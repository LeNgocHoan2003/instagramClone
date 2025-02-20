import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagramclone/resources/storage_methods.dart';
import 'package:instagramclone/utils/utils.dart';

class EditProfileScreen extends StatefulWidget {
  final String uid;
  const EditProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  Uint8List? _image;
  bool _isLoading = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    DocumentSnapshot userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();

    if (userSnap.exists) {
      setState(() {
        _photoUrl = userSnap['photoUrl'];
        usernameController.text = userSnap['username'];
        bioController.text = userSnap['bio'];
        emailController.text = userSnap['email'];
      });
    }
  }

  void selectImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(context); // Đóng BottomSheet
                Uint8List? im = await pickImage(ImageSource.gallery);
                if (im != null) {
                  setState(() {
                    _image = im;
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Chụp ảnh mới'),
              onTap: () async {
                Navigator.pop(context); // Đóng BottomSheet
                Uint8List? im = await pickImage(ImageSource.camera);
                if (im != null) {
                  setState(() {
                    _image = im;
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    String uid = FirebaseAuth.instance.currentUser!.uid;
    String? newPhotoUrl = _photoUrl;
    

    if (_image != null) {
      newPhotoUrl = await StorageMethods()
          .uploadImageToStorage('profilePics', _image!, false);
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'username': usernameController.text,
      'bio': bioController.text,
      'email': emailController.text,
      'photoUrl': newPhotoUrl,
    });

    QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: uid) // Lọc bài viết của user
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in postsSnapshot.docs) {
      batch.update(doc.reference, {'username':  usernameController.text});
    }

    await batch.commit();

    setState(() {
      _isLoading = false;
    });

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    super.dispose();
    usernameController.dispose();
    bioController.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: updateProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: _image != null
                            ? MemoryImage(_image!)
                            : (_photoUrl != null
                                    ? NetworkImage(_photoUrl!)
                                    : AssetImage('assets/default_avatar.png'))
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: -5,
                        right: -5,
                        child: IconButton(
                          icon: Icon(Icons.edit, color: Colors.white),
                          onPressed: selectImage,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(labelText: "Username"),
                  ),
                  TextField(
                    controller: bioController,
                    decoration: InputDecoration(labelText: "Bio"),
                  ),
                  TextField(
                    enabled: false,
                    controller: emailController,
                    decoration: InputDecoration(labelText: "Email"),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: updateProfile,
                    child: Text("Save Changes"),
                  ),
                ],
              ),
            ),
    );
  }
}
