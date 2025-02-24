import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagramclone/screens/profile_screen.dart';
import 'package:instagramclone/utils/colors.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic> otherUser;

  ChatScreen({required this.chatId, required this.otherUser});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatUser currentUser;
  late ChatUser otherChatUser;
  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();

    // Lấy thông tin user hiện tại
    User? user = FirebaseAuth.instance.currentUser;
    currentUser = ChatUser(
      id: user!.uid,
      firstName: user.displayName ?? "Me",
      profileImage: user.photoURL,
    );

    // Lấy thông tin user đối phương
    otherChatUser = ChatUser(
      id: widget.otherUser['uid'],
      firstName: widget.otherUser['username'],
      profileImage: widget.otherUser['photoUrl'],
    );

    // Lắng nghe tin nhắn từ Firestore
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        var chatData = snapshot.data() as Map<String, dynamic>;
        List<dynamic> rawMessages = chatData['messages'] ?? [];

        List<ChatMessage> chatMessages = rawMessages.map((msg) {
          return ChatMessage(
            text: msg['content'],
            user:
                msg['senderId'] == currentUser.id ? currentUser : otherChatUser,
            createdAt: (msg['sentAt'] as Timestamp).toDate(),
          );
        }).toList();
        if (mounted) {
          setState(() {
            messages = chatMessages.reversed
                .toList(); // Đảo ngược để tin nhắn mới nhất ở cuối
          });
        }
      }
    });
  }

  void sendMessage(ChatMessage message) {
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'messages': FieldValue.arrayUnion([
        {
          'content': message.text.trim(),
          'senderId': currentUser.id,
          'sentAt': Timestamp.now(),
        }
      ])
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(uid: widget.otherUser['uid']),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.otherUser['photoUrl']),
              ),
            ),
            SizedBox(width: 10),
            Text(widget.otherUser['username']),
          ],
        ),
      ),
      body: DashChat(
        currentUser: currentUser,
        onSend: sendMessage,
        messages: messages,
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            filled: true, // Bật màu nền
            fillColor: Colors.white, // Màu nền TextField
            hintText: "Nhập tin nhắn...",
            hintStyle: TextStyle(color: Colors.grey), // Màu chữ gợi ý
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20), // Bo góc
              borderSide: BorderSide.none, // Bỏ viền
            ),
          ),
          alwaysShowSend: true,
          cursorStyle: CursorStyle(color: lightBlueColor),
          sendButtonBuilder: (void Function() send) => IconButton(
            icon: Icon(Icons.send, color: lightBlueColor), // Đổi màu tại đây
            onPressed: send,
          ),
          inputTextStyle: TextStyle(
      color: Colors.black, // Màu chữ khi nhập
      fontSize: 12, // Kích thước chữ
    ),

        ),
        messageOptions: MessageOptions(
            containerColor: lightBlueColor,
            showTime: true,
            textColor: primaryColor,
            currentUserTextColor: primaryColor,
            currentUserContainerColor: lightBlueColor,
            onPressAvatar: (ChatUser chatUser) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(uid: widget.otherUser['uid']),
                ),
              );
            }),
      ),
    );
  }
}
