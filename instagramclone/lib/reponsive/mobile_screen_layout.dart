import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagramclone/models/user.dart' as model;
import 'package:instagramclone/providers/user_provider.dart';
import 'package:instagramclone/utils/colors.dart';
import 'package:instagramclone/utils/global_variables.dart';
import 'package:provider/provider.dart';

class MobileScreenLayout extends StatefulWidget {
  const MobileScreenLayout({super.key});

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

class _MobileScreenLayoutState extends State<MobileScreenLayout> {
  int _page = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void navigationTapped(int page) {
    //Animating Page
    pageController.jumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        children: getHomeScreenItems(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        height: 60,
        border: Border(top: BorderSide(width: 0.2, color: secondaryColor)),
        backgroundColor: mobileBackgroundColor,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: RepaintBoundary(
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.home,
                  size: 28, // Tăng size để dễ nhìn thấy
                  color: (_page == 0) ? primaryColor : secondaryColor,
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: RepaintBoundary(
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.search,
                  size: 28,
                  color: (_page == 1) ? primaryColor : secondaryColor,
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: RepaintBoundary(
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.add_circle,
                  size: 28,
                  color: (_page == 2) ? primaryColor : secondaryColor,
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: RepaintBoundary(
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.favorite,
                  size: 28,
                  color: (_page == 3) ? primaryColor : secondaryColor,
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return RepaintBoundary(
                    child: const CircleAvatar(
                      radius: 14,
                      backgroundImage:
                          AssetImage('assets/default_avatar.png'), // Ảnh mặc định
                    ),
                  );
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                return RepaintBoundary(
                  child: CircleAvatar(
                    radius: 14,
                    backgroundImage:
                        NetworkImage(userData['photoUrl'] ?? ''), // Ảnh user
                  ),
                );
              },
            ),
            label: '',
          ),
        ],
        onTap: navigationTapped,
        currentIndex: _page,
      ),
    );
  }
}
