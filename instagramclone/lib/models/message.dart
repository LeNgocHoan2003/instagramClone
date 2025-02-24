import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {Text, Image}

class Message {
  String? senderId;
  String? content;
  MessageType? messageType;
  Timestamp? sentAt;

    Message({
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.sentAt,
  });

 
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      senderId: json['senderId'],
      content: json['content'],
      messageType: MessageType.values[json['messageType']],
      sentAt: json['sentAt'],
    );
  }

  // Convert Message object to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'content': content,
      'messageType': messageType?.index,
      'sentAt': sentAt,
    };
  }
}