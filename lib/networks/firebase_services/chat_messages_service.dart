import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/networks/firebase_services/base_services.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:nb_utils/nb_utils.dart';

FirebaseFirestore fireStore = FirebaseFirestore.instance;
FirebaseStorage storage = FirebaseStorage.instance;

class ChatServices extends BaseService {
  ChatServices() {
    ref = fireStore.collection('chats');
  }

  // =========================================================
  // CHAT LIST
  // =========================================================
  Query fetchChatListQuery({required String myChatId}) {
    return ref!
        .where('participants', arrayContains: myChatId)
        .orderBy('lastTimestamp', descending: true);
  }

  // =========================================================
  // ROOM MESSAGES
  // =========================================================
  Query chatMessagesWithPagination({required String roomId}) {
    return ref!.doc(roomId).collection('messages').orderBy('timestamp', descending: true);
  }

  // =========================================================
  // SEND MESSAGE (FIXED: lastMessage now handles files)
  // =========================================================
  Future<void> addMessage({
    required String roomId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final messageRef = ref!.doc(roomId).collection('messages').doc();

      final messageData = {
        ...data,
        'messageId': messageRef.id,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isDelivered': false,
      };

      await messageRef.set(messageData);

      // FIX: Generate a meaningful lastMessage text even for files/images
      String lastMessageText = _getLastMessageText(data);

      await ref!.doc(roomId).set({
        'bookingId': data['bookingId'],
        'chatRoomId': roomId,
        'participants': data['participants'],
        'lastMessage': lastMessageText,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'targetUid': data['receiverId'],
        'providerName': data['providerName'] ?? '',
        'providerImage': data['providerImage'] ?? '',
        'chatType': data['chatType'] ?? 'provider',
      }, SetOptions(merge: true));

      log("=========== MESSAGE ADDED ===========");
      log("ROOM ID => $roomId");
      log("MESSAGE ID => ${messageRef.id}");
      log("SENDER => ${data['senderId']}");
      log("RECEIVER => ${data['receiverId']}");
      log("MESSAGE => $lastMessageText");
      log("=====================================");
    } catch (e) {
      log("=========== ADD MESSAGE ERROR ===========");
      log(e.toString());
      log("=========================================");
      rethrow;
    }
  }

  // Helper to create a readable last message for media
  String _getLastMessageText(Map<String, dynamic> data) {
    if (data['message'] != null && data['message'].toString().isNotEmpty)
      return data['message'];
    if (data['text'] != null && data['text'].toString().isNotEmpty)
      return data['text'];
    if (data['msg'] != null && data['msg'].toString().isNotEmpty)
      return data['msg'];
    if (data['fileUrls'] != null && (data['fileUrls'] as List).isNotEmpty) {
      return '📎 ${(data['fileUrls'] as List).length} file(s)';
    }
    return '📎 Media';
  }

  // =========================================================
  // LAST MESSAGE STREAM (used in UserItemWidget)
  // =========================================================
  Stream<DocumentSnapshot> getLastMessageStream({required String roomId}) {
    return ref!.doc(roomId).snapshots();
  }

  // =========================================================
  // UNREAD COUNT
  // =========================================================
  Stream<int> getUnReadCount({required String roomId, required String myChatId}) {
    return ref!
        .doc(roomId)
        .collection('messages')
        .where('receiverId', isEqualTo: myChatId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((event) => event.docs.length);
  }

  // =========================================================
  // MARK READ (FIXED: added logging and ensures it runs)
  // =========================================================
  Future<void> markMessagesAsRead({required String roomId, required String myChatId}) async {
    try {
      final unreadMessages = await ref!
          .doc(roomId)
          .collection('messages')
          .where('receiverId', isEqualTo: myChatId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      final batch = fireStore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      log("=========== MARK READ ===========");
      log("ROOM ID => $roomId");
      log("UPDATED => ${unreadMessages.docs.length} messages");
      log("=================================");
    } catch (e) {
      log("=========== MARK READ ERROR ===========");
      log(e.toString());
      log("=======================================");
    }
  }

  // =========================================================
  // DELETE SINGLE MESSAGE
  // =========================================================
  Future<void> deleteSingleMessage({required String roomId, required String documentId}) async {
    try {
      await ref!.doc(roomId).collection('messages').doc(documentId).delete();
      log("=========== MESSAGE DELETED ===========");
      log("ROOM ID => $roomId");
      log("MESSAGE ID => $documentId");
      log("=======================================");
    } catch (e) {
      log("=========== DELETE ERROR ===========");
      log(e.toString());
      log("====================================");
    }
  }

  // =========================================================
  // CLEAR CHAT (clears all messages and resets lastMessage)
  // =========================================================
  Future<void> clearAllMessages({required String roomId}) async {
    try {
      final messagesSnapshot = await ref!.doc(roomId).collection('messages').get();
      final batch = fireStore.batch();
      for (final document in messagesSnapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();

      // Reset last message and timestamp
      await ref!.doc(roomId).set({
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      log("=========== CHAT CLEARED ===========");
      log("ROOM ID => $roomId");
      log("DELETED => ${messagesSnapshot.docs.length}");
      log("LAST MESSAGE CLEARED");
      log("====================================");
    } catch (e) {
      log("=========== CLEAR CHAT ERROR ===========");
      log(e.toString());
      log("========================================");
    }
  }

  // =========================================================
  // FILE UPLOAD
  // =========================================================
  Future<List<String>> uploadFiles(List<File> files) async {
    appStore.setLoading(true);
    List<String> downloadUrls = [];

    for (File file in files) {
      try {
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_files/${file.path.getFileName}');
        await storageRef.putFile(file);
        String downloadURL = await storageRef.getDownloadURL();
        downloadUrls.add(downloadURL);
      } catch (e) {
        toast(e.toString());
        log('Error uploading file: $e');
      }
    }

    appStore.setLoading(false);
    return downloadUrls;
  }

  // =========================================================
  // FILE DELETE
  // =========================================================
  Future<void> deleteFiles(List<String> storagePaths) async {
    for (String path in storagePaths) {
      try {
        await FirebaseStorage.instance
            .ref('chat_files/${path.getChatFileName}')
            .delete();
      } catch (e) {
        log('Error deleting file: $e');
      }
    }
  }
}
