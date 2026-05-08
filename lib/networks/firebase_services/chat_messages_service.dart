import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/chat_message_model.dart';
import 'package:handyman_provider_flutter/models/contact_model.dart';
import 'package:handyman_provider_flutter/models/user_data.dart';
import 'package:handyman_provider_flutter/networks/firebase_services/base_services.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:nb_utils/nb_utils.dart';

FirebaseFirestore fireStore = FirebaseFirestore.instance;
CollectionReference? userRef;
FirebaseStorage storage = FirebaseStorage.instance;

class ChatServices extends BaseService {
  ChatServices() {
    ref = fireStore.collection('chats');
    userRef = fireStore.collection(USER_COLLECTION);
  }

  // The Zeerah user app stores participants as [userFirebaseUID, providerNumericId (e.g. "162")].
  // So we must query using the provider's numeric backend ID, not Firebase Auth UID.
  // Use array-contains-any to find chats that have EITHER the numeric ID or the Firebase UID.
  // This prevents chats from disappearing if one app updates the participants with a different format.
  Query fetchChatListQuery({required String userId}) {
    List<String> ids = [userId];
    if (appStore.uid.validate().isNotEmpty) {
      ids.add(appStore.uid.validate());
    }
    return ref!.where('participants', arrayContainsAny: ids).orderBy('lastTimestamp', descending: true);
  }

  Future<void> setUnReadStatusToTrue({required String senderId, required String receiverId, String? bookingId}) async {
    log("setUnReadStatusToTrue: sender: $senderId, receiver: $receiverId, booking: $bookingId");
    String chatRoomId = 'booking_$bookingId';
    final WriteBatch batch = fireStore.batch();

    // Get all messages in the chat room to update unread ones from the other person
    QuerySnapshot messagesSnapshot = await ref!.doc(chatRoomId).collection('messages').get();

    messagesSnapshot.docs.forEach((element) {
      Map<String, dynamic> data = element.data() as Map<String, dynamic>;
      // Check if message is NOT from current provider and is unread
      bool isFromOther = data['senderId'] != appStore.uid && data['senderId'] != appStore.userId.toString();
      bool isUnread = (data['isMessageRead'] == false) || (data['isRead'] == false);
      
      if (isFromOther && isUnread) {
        batch.update(element.reference, {
          'isMessageRead': true,
          'isRead': true,
        });
      }
    });

    await batch.commit();
  }

  Future<void> deleteSingleMessage({required String receiverId, String? bookingId, String? documentId}) async {
    try {
      log("deleteSingleMessage: receiver: $receiverId, booking: $bookingId, doc: $documentId");
      String chatRoomId = 'booking_$bookingId';
      await ref!.doc(chatRoomId).collection('messages').doc(documentId).delete();
      log("====================== Message Deleted ======================");
    } catch (e) {
      throw languages.somethingWentWrong;
    }
  }

  Query chatMessagesWithPagination({String? bookingId}) {
    try {
      String chatRoomId = 'booking_$bookingId';
      // Use 'timestamp' field — both the Zeerah user app and this provider app write to 'timestamp'.
      return ref!.doc(chatRoomId).collection('messages').orderBy("timestamp", descending: true);
    } catch (e) {
      log("Error in chatMessagesWithPagination: $e");
      return ref!.limit(0);
    }
  }

  Future<DocumentReference> addMessage(ChatMessageModel data, {String? bookingId}) async {
    String chatRoomId = 'booking_$bookingId';
    final messagesCollection = ref!.doc(chatRoomId).collection('messages');

    final doc = await messagesCollection.add(data.toJson());

    await doc.update({'uid': doc.id});

    // Store all identifying IDs in participants to ensure all parties can find the chat
    List<String> participants = [];
    participants.add(appStore.uid.validate());
    participants.add(appStore.userId.toString());
    if (data.receiverUid.validate().isNotEmpty) participants.add(data.receiverUid.validate());
    if (data.receiverId.validate().isNotEmpty) participants.add(data.receiverId.validate());
    
    // De-duplicate participants
    participants = participants.where((element) => element.isNotEmpty).toSet().toList();

    await ref!.doc(chatRoomId).set({
      'bookingId': bookingId,
      'lastMessage': data.message ?? data.text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
      'participants': participants,
      'providerName': appStore.userFullName,
      'providerImage': appStore.userProfileImage,
    }, SetOptions(merge: true));

    return doc;
  }

  Future<void> addToContacts({String? senderId, String? receiverId, String? senderName, String? receiverName}) async {
    // This might not be needed anymore with the new structure, 
    // but we can keep it if other parts of the app rely on the 'contact' collection.
  }

  Stream<int> getUnReadCount({required String senderId, required String receiverId, String? bookingId}) {
    String chatRoomId = 'booking_$bookingId';
    return ref!
        .doc(chatRoomId)
        .collection('messages')
        .snapshots()
        .map((event) => event.docs.where((element) {
              Map<String, dynamic> data = element.data() as Map<String, dynamic>;
              // Count messages that are NOT from current provider and are unread
              bool isFromOther = data['senderId'] != appStore.uid && data['senderId'] != appStore.userId.toString();
              bool isUnread = (data['isMessageRead'] == false) || (data['isRead'] == false);
              return isFromOther && isUnread;
            }).length)
        .handleError((e) => 0);
  }

  Stream<QuerySnapshot> fetchLastMessageBetween({String? bookingId}) {
    String chatRoomId = 'booking_$bookingId';
    return ref!.doc(chatRoomId).collection('messages').orderBy("timestamp", descending: false).snapshots();
  }

  Future<void> clearAllMessages({required String receiverId, String? bookingId}) async {
    String chatRoomId = 'booking_$bookingId';
    final QuerySnapshot messagesSnapshot = await ref!.doc(chatRoomId).collection('messages').get();
    final WriteBatch batch = fireStore.batch();

    for (final document in messagesSnapshot.docs) {
      batch.delete(document.reference);
    }

    await batch.commit();
  }

  Future<void> setOnlineCount({required String receiverId, required String senderId, required int status}) async {
    // Online status logic might need to be adapted or can be ignored if not critical for now.
  }

  Stream<UserData> isReceiverOnline({required String receiverUserId, required String senderId}) {
    return userRef!.doc(receiverUserId).snapshots().map((event) => UserData.fromJson(event.data() as Map<String, dynamic>));
  }

  Future<List<String>> uploadFiles(List<File> files) async {
    appStore.setLoading(true);
    List<String> downloadUrls = [];
    for (File file in files) {
      try {
        Reference storageRef = FirebaseStorage.instance.ref().child('$CHAT_FILES/${file.path.getFileName}');
        await storageRef.putFile(file);
        String downloadURL = await storageRef.getDownloadURL();
        downloadUrls.add(downloadURL);
      } catch (e) {
        toast(e.toString());
        log('Error uploading file $CHAT_FILES/${file.path.getFileName}: $e');
      }
    }
    appStore.setLoading(false);
    return downloadUrls;
  }

  Future<void> deleteFiles(List<String> storagePaths) async {
    for (String path in storagePaths) {
      try {
        log('deleteFile: $CHAT_FILES/${path.getChatFileName}');
        await FirebaseStorage.instance.ref('$CHAT_FILES/${path.getChatFileName}').delete();
      } catch (e) {
        log('Error deleting file $CHAT_FILES/${path.getChatFileName}: $e');
      }
    }
  }
}
