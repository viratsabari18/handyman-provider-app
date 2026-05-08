import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  String? bookingId;
  String? lastMessage;
  Timestamp? timestamp;
  List<String>? participants;
  String? providerName;
  String? providerImage;

  ChatModel({
    this.bookingId,
    this.lastMessage,
    this.timestamp,
    this.participants,
    this.providerName,
    this.providerImage,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      bookingId: json['bookingId'],
      lastMessage: json['lastMessage'],
      timestamp: json['timestamp'] ?? json['lastTimestamp'],
      participants: json['participants'] != null ? (json['participants'] as List).map((e) => e.toString()).toList() : [],
      providerName: json['providerName'],
      providerImage: json['providerImage'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['bookingId'] = this.bookingId;
    data['lastMessage'] = this.lastMessage;
    data['timestamp'] = this.timestamp;
    data['participants'] = this.participants;
    data['providerName'] = this.providerName;
    data['providerImage'] = this.providerImage;
    return data;
  }
}
