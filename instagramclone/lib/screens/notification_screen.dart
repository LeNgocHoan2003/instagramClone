import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagramclone/resources/firestore_methods.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body:StreamBuilder(
  stream: FirebaseFirestore.instance
      .collection('notifications')
      .where('receiverId', isEqualTo: currentUserId) // Lọc theo người nhận
      .orderBy('timestamp', descending: true)
      .snapshots(),
  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(child: Text('Chưa có thông báo nào.'));
    }

    return ListView.builder(
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (context, index) {
        var data = snapshot.data!.docs[index];

        return FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(data['senderId'])
              .get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
            if (!userSnapshot.hasData) {
              return SizedBox.shrink();
            }

            var user = userSnapshot.data!.data() as Map<String, dynamic>;
            String username = user['username'];
            String photoUrl = user['photoUrl'];

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(photoUrl),
              ),
              title: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: data['type'] == 'like'
                          ? " liked your post"
                          : data['type'] == 'comment'
                              ? " commented: \"${data['text']}\""
                              : " started following you",
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: data['type'] == 'like' || data['type'] == 'comment'
                  ? FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(data['postId'])
                          .get(),
                      builder: (context, AsyncSnapshot<DocumentSnapshot> postSnapshot) {
                        if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
                          return Icon(Icons.favorite, color: Colors.red);
                        }

                        var post = postSnapshot.data!.data() as Map<String, dynamic>;
                        String postImageUrl = post['postUrl'];

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            postImageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    )
                  : StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return SizedBox();
                        }

                        List following =
                            (snapshot.data!.data() as Map<String, dynamic>)['following'] ?? [];

                        bool isFollowing = following.contains(data['senderId']);

                        return isFollowing
                            ? SizedBox()
                            : IconButton(
                                icon: Icon(Icons.person_add, color: Colors.blue),
                                onPressed: () async {
                                  await FirestoreMethods().followUser(
                                      FirebaseAuth.instance.currentUser!.uid,
                                      data['senderId']);
                                },
                              );
                      },
                    ),
            );
          },
        );
      },
    );
  },
)


    );
  }
}
