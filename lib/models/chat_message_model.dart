import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {

  String? uid;

  String? messageId;

  String? bookingId;

  String? senderId;

  String? receiverId;

  String? photoUrl;

  List<String>? attachmentfiles;

  String? messageType;

  bool? isMe;

  bool? isMessageRead;

  bool? isRead;

  bool? isDelivered;

  String? message;

  int? createdAt;

  Timestamp? createdAtTime;

  Timestamp? updatedAtTime;

  DocumentReference? chatDocumentReference;

  ChatMessageModel({

    this.uid,

    this.messageId,

    this.bookingId,

    this.chatDocumentReference,

    this.senderId,

    this.createdAtTime,

    this.updatedAtTime,

    this.receiverId,

    this.createdAt,

    this.message,

    this.isMessageRead,

    this.isRead,

    this.isDelivered,

    this.photoUrl,

    this.attachmentfiles,

    this.messageType,

    this.isMe,
  });

  factory ChatMessageModel.fromJson(
      Map<String, dynamic> json) {

    return ChatMessageModel(

      uid:
          json['uid'],

      messageId:
          json['messageId'],

      bookingId:
          json['bookingId']
              ?.toString(),

      senderId:
          json['senderId'],

      receiverId:
          json['receiverId'],

      message:

          json['message'] ??

          json['text'] ??

          '',

      isMessageRead:

          json['isMessageRead'] ??

          json['isRead'] ??

          false,

      isRead:
          json['isRead'],

      isDelivered:
          json['isDelivered'],

      photoUrl:
          json['photoUrl'],

      attachmentfiles:

          json['attachmentfiles']
                  is List

              ? List<String>.from(

                  json['attachmentfiles']
                      .map((x) => x),
                )

              : [],

      messageType:

          json['messageType'] ??

          'TEXT',

      createdAt:
          json['createdAt'],

      createdAtTime:

          json['timestamp'] ??

          json['createdAtTime'],

      updatedAtTime:
          json['updatedAtTime'],
    );
  }

  Map<String, dynamic> toJson() {

    final Map<String, dynamic> data =
        <String, dynamic>{};

    data['uid'] =
        uid;

    data['messageId'] =
        messageId;

    data['bookingId'] =
        bookingId;

    data['createdAt'] =
        createdAt;

    data['message'] =
        message;

    data['senderId'] =
        senderId;

    data['isMessageRead'] =
        isMessageRead;

    data['isRead'] =
        isRead;

    data['isDelivered'] =
        isDelivered;

    data['receiverId'] =
        receiverId;

    data['photoUrl'] =
        photoUrl;

    if (attachmentfiles != null) {

      data['attachmentfiles'] =

          attachmentfiles!
              .map((e) => e)
              .toList();
    }

    data['createdAtTime'] =
        createdAtTime;

    data['updatedAtTime'] =
        updatedAtTime;

    data['messageType'] =
        messageType;

    return data;
  }
}