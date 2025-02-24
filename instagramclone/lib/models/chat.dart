import 'package:instagramclone/models/message.dart';

class Chat {
  String? id;
  List<String>? participants;
  List<Message>? messages;
  Chat({
    required this.id,
    required this.participants,
    required this.messages,
  });


  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      participants: List<String>.from(json['participants']),
      messages: (json['messages'] as List<dynamic>)
          .map((msg) => Message.fromJson(msg))
          .toList(),
    );
  }

 
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'messages': messages?.map((msg) => msg.toJson()).toList(),
    };
  }
}
