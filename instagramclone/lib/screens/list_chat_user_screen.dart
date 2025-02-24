import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagramclone/utils/colors.dart';
import 'package:intl/intl.dart';

import 'chat_screen.dart'; // Import màn hình chat

class ListChatUserScreen extends StatefulWidget {
  const ListChatUserScreen({super.key});

  @override
  State<ListChatUserScreen> createState() => _ListChatUserScreenState();
}

class _ListChatUserScreenState extends State<ListChatUserScreen> {
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List followingList = [];

  @override
  void initState() {
    super.initState();
    getFollowingList();
  }

  /// 📌 **Lấy danh sách người dùng mà current user đang follow**
  void getFollowingList() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    if (userDoc.exists) {
      setState(() {
        followingList = (userDoc.data() as Map<String, dynamic>)['following'] ?? [];
      });
    }
  }

  Future<void> onRefresh() async {
    getFollowingList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Scaffold(
        appBar: AppBar(title: Text("Chat")),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
      
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("Không có người dùng nào!"));
            }
      
            List<DocumentSnapshot> allUsers = snapshot.data!.docs;
            List<DocumentSnapshot> filteredUsers = allUsers.where((user) => user['uid'] != currentUserId).toList();
      
            /// 📌 **Sắp xếp những người đang follow lên trước**
            List<DocumentSnapshot> followingUsers = filteredUsers.where((user) => followingList.contains(user['uid'])).toList();
            List<DocumentSnapshot> otherUsers = filteredUsers.where((user) => !followingList.contains(user['uid'])).toList();
            List<DocumentSnapshot> sortedUsers = [...followingUsers, ...otherUsers];
      
            return ListView.builder(
              itemCount: sortedUsers.length,
              itemBuilder: (context, index) {
                var user = sortedUsers[index].data() as Map<String, dynamic>;
                bool isFollowing = followingList.contains(user['uid']); // Kiểm tra nếu đang follow
      
                return FutureBuilder(
                  future: getLastMessage(currentUserId, user['uid']),
                  builder: (context, AsyncSnapshot<String> messageSnapshot) {
                    String lastMessage = messageSnapshot.data ?? "Chưa có tin nhắn";
      
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user['photoUrl']),
                      ),
                      title: Row(
                        children: [
                          Text(user['username']),
                          if (isFollowing) 
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Text(
                                "• Following",
                                style: TextStyle(color: secondaryColor, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w100),
                      ),
                      onTap: () async {
                        String chatId = await getOrCreateChat(currentUserId, user['uid']);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(chatId: chatId, otherUser: user),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 📌 **Hàm lấy tin nhắn gần nhất**
 Future<String> getLastMessage(String currentUserId, String otherUserId) async {
  QuerySnapshot chatQuery = await FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: currentUserId)
      .get();

  for (var doc in chatQuery.docs) {
    List<dynamic> participants = doc['participants'];
    if (participants.contains(otherUserId)) {
      List<dynamic> messages = doc['messages'] ?? [];
      if (messages.isNotEmpty) {
        var lastMessage = messages.last;
        
        // Chuyển timestamp thành DateTime
        Timestamp sentAtTimestamp = lastMessage['sentAt'];
        DateTime sentAt = sentAtTimestamp.toDate();

        // Định dạng thời gian (giờ:phút AM/PM)
        String formattedTime = DateFormat("hh:mm a").format(sentAt);

        return "${lastMessage['content']}     $formattedTime";
      }
    }
  }
  return "Chưa có tin nhắn";
}

  /// 📌 **Hàm kiểm tra hoặc tạo chat**
  Future<String> getOrCreateChat(String currentUserId, String otherUserId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    QuerySnapshot chatQuery = await firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    DocumentSnapshot? existingChat;
    for (var doc in chatQuery.docs) {
      List<dynamic> participants = doc['participants'];
      if (participants.contains(otherUserId)) {
        existingChat = doc;
        break;
      }
    }

    if (existingChat != null) {
      return existingChat.id;
    } else {
      DocumentReference newChatRef = firestore.collection('chats').doc();
      await newChatRef.set({
        'id': newChatRef.id,
        'participants': [currentUserId, otherUserId],
        'messages': [],
      });
      return newChatRef.id;
    }
  }
}
