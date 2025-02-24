import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagramclone/screens/chat_screen.dart';
import 'package:instagramclone/screens/list_chat_user_screen.dart';
import 'package:instagramclone/utils/colors.dart';
import 'package:instagramclone/utils/global_variables.dart';
import 'package:instagramclone/widgets/post_card.dart';


class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Future<void> _refreshData() async {
  setState(() {}); 
}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor:
          width > webScreenSize ? webBackgroundColor : mobileBackgroundColor,
      appBar: width > webScreenSize
          ? null
          : AppBar(
              backgroundColor: mobileBackgroundColor,
              centerTitle: false,
              title: Image.asset(
                'assets/logo.jpg',
                height: 30,
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.messenger_outline,
                    color: primaryColor,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => ListChatUserScreen()));
                  },
                ),
              ],
            ),
      body: StreamBuilder(
  stream: FirebaseFirestore.instance.collection('posts')
      .orderBy('datePublished', descending: true)
      .snapshots(),
  builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(child: Text("Không có bài viết nào!"));
    }

    List<DocumentSnapshot<Map<String, dynamic>>> allPosts = snapshot.data!.docs;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Center(child: CircularProgressIndicator());
        }

        String currentUserId = FirebaseAuth.instance.currentUser!.uid;

        // Lấy danh sách người dùng mà mình đang theo dõi
        List following = (userSnapshot.data!.data() as Map<String, dynamic>)['following'] ?? [];

        // Thêm chính mình vào danh sách để không bị lọc mất bài viết của bản thân
        if (!following.contains(currentUserId)) {
          following.add(currentUserId);
        }

        // Lọc các bài viết của following + chính mình
        List<DocumentSnapshot<Map<String, dynamic>>> followingPosts = allPosts
            .where((post) => following.contains(post['uid']))
            .toList();

        // Lọc các bài viết của những người khác không nằm trong following
        List<DocumentSnapshot<Map<String, dynamic>>> otherPosts = allPosts
            .where((post) => !following.contains(post['uid']))
            .toList();

        // Sắp xếp: Bài viết của mình & following trước, bài viết của người khác sau
        List<DocumentSnapshot<Map<String, dynamic>>> sortedPosts = [...followingPosts, ...otherPosts];

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.builder(
            itemCount: sortedPosts.length,
            itemBuilder: (ctx, index) => Container(
              margin: EdgeInsets.symmetric(
                horizontal: width > webScreenSize ? width * 0.3 : 0,
                vertical: width > webScreenSize ? 15 : 0,
              ),
              child: PostCard(
                snap: sortedPosts[index].data()!,
              ),
            ),
          ),
        );
      },
    );
  },
),


    );
  }
}