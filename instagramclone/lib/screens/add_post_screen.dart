import 'dart:typed_data';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagramclone/providers/user_provider.dart';
import 'package:instagramclone/resources/firestore_methods.dart';
import 'package:instagramclone/utils/colors.dart';
import 'package:instagramclone/utils/utils.dart';

import 'package:provider/provider.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({Key? key}) : super(key: key);

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  Uint8List? _file;
  bool isLoading = false;
  final TextEditingController _descriptionController = TextEditingController();

  _selectImage(BuildContext parentContext) async {
    return showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Create a Post'),
          children: <Widget>[
            SimpleDialogOption(
  padding: const EdgeInsets.all(20),
  child: const Text('Take a photo'),
  onPressed: () async {
    Navigator.pop(context);
    Uint8List? file = await pickImage(ImageSource.camera);
    if (file == null) return; // Nếu không chọn ảnh, thoát luôn
    setState(() {
      _file = file;
    });
  },
),
SimpleDialogOption(
  padding: const EdgeInsets.all(20),
  child: const Text('Choose from Gallery'),
  onPressed: () async {
    Navigator.of(context).pop();
    Uint8List? file = await pickImage(ImageSource.gallery);
    if (file == null) return; // Nếu không chọn ảnh, thoát luôn
    setState(() {
      _file = file;
    });
  },
),

            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  void postImage(String uid, String username, String profImage) async {
    setState(() {
      isLoading = true;
    });
    // start the loading
    try {
      // upload to storage and db
      String res = await FirestoreMethods().uploadPost(
        _descriptionController.text,
        _file!,
        uid,
        username,
        profImage,
      );
      if (res == "success") {
        setState(() {
          isLoading = false;
        });
        if (context.mounted) {
          showSnackBar(
            context,
            'Posted!',
          );
        }
        clearImage();
      } else {
        if (context.mounted) {
          showSnackBar(context, res);
        }
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(
        context,
        err.toString(),
      );
    }
  }

  void clearImage() {
    setState(() {
      _file = null;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    // userProvider.refreshUser();
    return _file == null
        ? Scaffold(
            appBar: AppBar(
              title: Text('Create new post'),
              centerTitle: true,
            ),
            body: GestureDetector(
                onTap: () => _selectImage(context),
                child: Scaffold(
                  body: Center(
                    // Đưa toàn bộ khung hình vuông vào giữa màn hình
                    child: DottedBorder(
                      color: secondaryColor,
                      strokeWidth: 2,
                      dashPattern: [6, 3],
                      borderType: BorderType.RRect,
                      radius: Radius.circular(20),
                      child: SizedBox(
                        width: 320,
                        height: 320,
                        child: Center(
                          // Đưa nội dung bên trong vào giữa
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 80,
                                color: secondaryColor,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Upload an Image',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
          )
        : Scaffold(
            backgroundColor: mobileBackgroundColor, // Nền đen
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: primaryColor),
                onPressed: clearImage,
              ),
              title: const Text(
                'Create new post',
                style:
                    TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
              centerTitle: false,
              actions: <Widget>[
                TextButton(
                  onPressed: () => postImage(
                    userProvider.getUser.uid,
                    userProvider.getUser.username,
                    userProvider.getUser.photoUrl,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: mobileBackgroundColor,
                  ),
                  child: const Text(
                    "Share",
                    style: TextStyle(
                        color: lightBlueColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0),
                  ),
                )
              ],
            ),

            // POST FORM
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  if (isLoading) const LinearProgressIndicator(),
                  const SizedBox(height: 10),

                  // 1️⃣ Avatar user
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              NetworkImage(userProvider.getUser.photoUrl),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(userProvider.getUser.username)
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 2️⃣ Ảnh được tải lên
                  if (_file != null)
                    Image.memory(
                      _file!,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 5),

                  // 3️⃣ Caption nhập vào
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: "Write a caption...",
                        hintStyle: TextStyle(color: secondaryColor),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                      maxLines: null,
                      style: const TextStyle(color: primaryColor),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
  }
}
