import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:instagramclone/screens/comments_screen.dart';
import 'package:instagramclone/screens/profile_screen.dart';
import 'package:instagramclone/utils/colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  final StreamController<String> searchStreamController = StreamController<String>.broadcast();
  bool isShowUsers = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    searchStreamController.close();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchStreamController.add(searchController.text);
      setState(() {
        isShowUsers = searchController.text.isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: TextField(
          controller: searchController,
          decoration: const InputDecoration(labelText: 'Search for a user...'),
        ),
      ),
      body: StreamBuilder<String>(
        stream: searchStreamController.stream,
        builder: (context, searchSnapshot) {
          String searchText = searchSnapshot.data ?? '';

          return isShowUsers
              ? StreamBuilder<QuerySnapshot>(
                  stream: searchText.isNotEmpty
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .where('username', isGreaterThanOrEqualTo: searchText)
                          .where('username', isLessThan: searchText + 'z')
                          .snapshots()
                      : const Stream.empty(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No users found"));
                    }

                    return ListView.builder(
                      itemCount: userSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var userData = userSnapshot.data!.docs[index].data() as Map<String, dynamic>;

                        return InkWell(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: userData.containsKey('photoUrl') &&
                                      userData['photoUrl'].isNotEmpty
                                  ? NetworkImage(userData['photoUrl'])
                                  : const AssetImage('assets/default-avatar.png') as ImageProvider,
                              radius: 16,
                            ),
                            title: Text(userData['username'] ?? 'Unknown'),
                          ),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                uid: userSnapshot.data!.docs[index]['uid'],
                              ),
                            ));
                          },
                        );
                      },
                    );
                  },
                )
              : StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('posts')
      .orderBy('datePublished', descending: true)
      .snapshots(),
  builder: (context, postSnapshot) {
    if (postSnapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
      return const Center(child: Text("No posts available"));
    }

    return MasonryGridView.count(
      crossAxisCount: 3,
      itemCount: postSnapshot.data!.docs.length,
      mainAxisSpacing: 1.0,
      crossAxisSpacing: 1.0,
      itemBuilder: (context, index) {
        var postDoc = postSnapshot.data!.docs[index];

        // Chuyển document thành Map<String, dynamic>
        var post = postDoc.data() as Map<String, dynamic>?;

        // Kiểm tra nếu post == null hoặc không có postUrl
        if (post == null || !post.containsKey('postUrl') || post['postUrl'] == null) {
          return const SizedBox(); // Tránh lỗi bằng cách trả về widget trống
        }

        return InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => CommentsScreen(
                postId: postDoc['postId'],
              ),
            ));
          },
          child: ClipRRect(
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                post['postUrl'],
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  },
);

        },
      ),

    );
  }
}
