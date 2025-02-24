import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagramclone/resources/auth_methods.dart';
import 'package:instagramclone/resources/firestore_methods.dart';
import 'package:instagramclone/screens/comments_screen.dart';
import 'package:instagramclone/screens/edit_profile_screen.dart';
import 'package:instagramclone/screens/login_screen.dart';
import 'package:instagramclone/utils/colors.dart';
import 'package:instagramclone/utils/utils.dart';
import 'package:instagramclone/widgets/follow_button.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var userData = {};
  int postLen = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      // get post lENGTH
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();

      postLen = postSnap.docs.length;
      userData = userSnap.data()!;
      followers = userSnap.data()!['followers'].length;
      following = userSnap.data()!['following'].length;
      isFollowing = userSnap
          .data()!['followers']
          .contains(FirebaseAuth.instance.currentUser!.uid);
      setState(() {});
    } catch (e) {
      showSnackBar(
        context,
        e.toString(),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : RefreshIndicator(
            onRefresh: () => getData(),
            child: Scaffold(
              appBar: AppBar(
                  backgroundColor: mobileBackgroundColor,
                  title: Text(
                    userData['username'],
                  ),
                  centerTitle: false,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.settings), // Biểu tượng cài đặt
                        onSelected: (value) async {
                          if (value == 'logout') {
                            await AuthMethods().signOut();

                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red),
                                SizedBox(width: 10),
                                Text('Sign out'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
              body: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey,
                              backgroundImage: NetworkImage(
                                userData['photoUrl'],
                              ),
                              radius: 35,
                            ),
                            Expanded(
                              flex: 1,
                              child: RepaintBoundary(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IgnorePointer(
                                            child: buildStatColumn(
                                                postLen,
                                                "posts",
                                                "posts",
                                                userData['uid'])),
                                        buildStatColumn(followers, "followers",
                                            "followers", userData['uid']),
                                        buildStatColumn(following, "following",
                                            "following", userData['uid']),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        FirebaseAuth.instance.currentUser!
                                                    .uid ==
                                                widget.uid
                                            ? FollowButton(
                                                text: 'Edit profile',
                                                backgroundColor:
                                                    mobileBackgroundColor,
                                                textColor: primaryColor,
                                                borderColor: Colors.grey,
                                                function: () async {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditProfileScreen(
                                                              uid: FirebaseAuth
                                                                  .instance
                                                                  .currentUser!
                                                                  .uid),
                                                    ),
                                                  );
                                                  // await AuthMethods().signOut();

                                                  // if (context.mounted) {
                                                  //   Navigator.of(context)
                                                  //       .pushReplacement(
                                                  //     MaterialPageRoute(
                                                  //       builder: (context) =>
                                                  //           LoginScreen(),
                                                  //     ),
                                                  //   );
                                                  // }
                                                },
                                              )
                                            : isFollowing
                                                ? RepaintBoundary(
                                                    child: FollowButton(
                                                      text: 'Unfollow',
                                                      backgroundColor:
                                                          Colors.white,
                                                      textColor: Colors.black,
                                                      borderColor: Colors.grey,
                                                      function: () async {
                                                        await FirestoreMethods()
                                                            .followUser(
                                                          FirebaseAuth.instance
                                                              .currentUser!.uid,
                                                          userData['uid'],
                                                        );

                                                        setState(() {
                                                          isFollowing = false;
                                                          followers--;
                                                        });
                                                      },
                                                    ),
                                                  )
                                                : RepaintBoundary(
                                                    child: FollowButton(
                                                      text: 'Follow',
                                                      backgroundColor:
                                                          Colors.blue,
                                                      textColor: Colors.white,
                                                      borderColor: Colors.blue,
                                                      function: () async {
                                                        await FirestoreMethods()
                                                            .followUser(
                                                          FirebaseAuth.instance
                                                              .currentUser!.uid,
                                                          userData['uid'],
                                                        );

                                                        setState(() {
                                                          isFollowing = true;
                                                          followers++;
                                                        });
                                                      },
                                                    ),
                                                  )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(
                            top: 15,
                          ),
                          child: Text(
                            userData['username'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(
                            top: 1,
                          ),
                          child: Text(
                            userData['bio'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const Divider(),
                  FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('posts')
                        .where('uid', isEqualTo: widget.uid)
                        .orderBy('datePublished', descending: true)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        itemCount: (snapshot.data as dynamic).docs.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          DocumentSnapshot snap =
                              (snapshot.data! as dynamic).docs[index];

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => CommentsScreen(
                                  postId: snap['postId'],
                                ),
                              ));
                            },
                            child: SizedBox(
                              child: Image(
                                image: NetworkImage(snap['postUrl']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                ],
              ),
            ),
          );
  }

  GestureDetector buildStatColumn(
      int num, String label, String type, String userId) {
    return GestureDetector(
      onTap: () =>
          showFollowersFollowingPopup(userId, type), // Khi ấn vào sẽ mở popup
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            num.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showFollowersFollowingPopup(String userId, String type) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('users').doc(userId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: CircularProgressIndicator());
            }

            Map<String, dynamic> userData =
                snapshot.data!.data() as Map<String, dynamic>;
            List<dynamic> usersList = userData[type] ?? [];

            return Container(
              height: 400,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    type == "followers" ? "Followers" : "Following",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: usersList.length,
                      itemBuilder: (context, index) {
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(usersList[index])
                              .get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData ||
                                !userSnapshot.data!.exists) {
                              return SizedBox.shrink();
                            }

                            Map<String, dynamic> user = userSnapshot.data!
                                .data() as Map<String, dynamic>;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(user['photoUrl']),
                              ),
                              title: Text(user['username']),
                              subtitle: Text(user['email']),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
