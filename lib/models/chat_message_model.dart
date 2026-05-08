import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  String? uid;
  String? senderId;
  String? receiverId;
  String? senderName;
  String? senderUid;
  String? receiverUid;
  String? photoUrl;
  List<String>? attachmentfiles;
  String? messageType;
  bool? isMe;
  bool? isMessageRead;
  String? message;
  String? text;
  int? createdAt;
  Timestamp? createdAtTime;
  Timestamp? updatedAtTime;
  DocumentReference? chatDocumentReference;

  ChatMessageModel(
      {this.uid,
      this.chatDocumentReference,
      this.senderId,
      this.receiverId,
      this.senderUid,
      this.receiverUid,
      this.senderName,
      this.createdAtTime,
      this.updatedAtTime,
      this.createdAt,
      this.message,
      this.text,
      this.isMessageRead,
      this.photoUrl,
      this.attachmentfiles,
      this.messageType});

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      uid: json['uid'],
      senderId: json['senderId']?.toString(),
      receiverId: json['receiverId']?.toString(),
      senderUid: json['senderUid'],
      receiverUid: json['receiverUid'],
      senderName: json['senderName'],
      // Both apps use 'text' or 'message' fields
      message: json['message'] ?? json['text'],
      text: json['text'] ?? json['message'],
      // Zeerah uses 'isRead', provider app uses 'isMessageRead'
      isMessageRead: json['isMessageRead'] ?? json['isRead'],
      photoUrl: json['photoUrl'],
      attachmentfiles: json['attachmentfiles'] is List ? List<String>.from(json['attachmentfiles'].map((x) => x)) : [],
      messageType: json['messageType'],
      createdAt: json['createdAt'],
      // Both apps use 'timestamp'; provider also uses 'createdAtTime'
      createdAtTime: json['createdAtTime'] ?? json['timestamp'],
      updatedAtTime: json['updatedAtTime'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['uid'] = this.uid;
    data['createdAt'] = this.createdAt;
    data['message'] = this.message;
    data['text'] = this.text;
    data['senderId'] = this.senderId;
    data['receiverId'] = this.receiverId;
    data['senderUid'] = this.senderUid;
    data['receiverUid'] = this.receiverUid;
    data['senderName'] = this.senderName;
    data['isMessageRead'] = this.isMessageRead;
    data['photoUrl'] = this.photoUrl;
    if (this.attachmentfiles != null) data['attachmentfiles'] = this.attachmentfiles?.map((e) => e).toList();
    data['createdAtTime'] = this.createdAtTime;
    data['timestamp'] = this.createdAtTime;
    data['updatedAtTime'] = this.updatedAtTime;
    data['messageType'] = this.messageType;
    return data;
  }
}
