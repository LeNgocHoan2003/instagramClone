// ignore_for_file: prefer_const_constructors

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagramclone/reponsive/mobile_screen_layout.dart';
import 'package:instagramclone/reponsive/responsive_layout_screen.dart';
import 'package:instagramclone/reponsive/web_screen_layout.dart';
import 'package:instagramclone/resources/auth_methods.dart';
import 'package:instagramclone/screens/login_screen.dart';
import 'package:instagramclone/utils/colors.dart';
import 'package:instagramclone/utils/utils.dart';
import 'package:instagramclone/widgets/text_field_input.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailEditingController = TextEditingController();
  final TextEditingController passEditingController = TextEditingController();
  final TextEditingController userNameEditingController =
      TextEditingController();
  final TextEditingController bioEditingController = TextEditingController();
  Uint8List? image;
  bool isLoading = false;

  Future<Uint8List> getDefaultImage() async {
    final ByteData data = await rootBundle.load('assets/default-avatar.png');
    return data.buffer.asUint8List();
  }

  void selectImage() async {
    try {
      Uint8List? im = await pickImage(ImageSource.gallery);

      if (im != null && im.isNotEmpty) {
        setState(() {
          image = im;
        });
      }
    } catch (e) {
      print("Lỗi khi chọn ảnh: $e");
    }
  }

  void signUpUser() async {
  setState(() {
    isLoading = true;
  });

  Uint8List defaultImage = await getDefaultImage();

  String res = await AuthMethods().signUpUser(
    email: emailEditingController.text,
    password: passEditingController.text,
    username: userNameEditingController.text,
    bio: bioEditingController.text,
    file: image ?? defaultImage,
  );

  if (res == "Please verify your email before logging in") {
    if (context.mounted) {
      showSnackBar(
        context,
        "A verification email has been sent. Please check your inbox before logging in.",
      );
    }
  } else {
    showSnackBar(context, res);
  }

  setState(() {
    isLoading = false;
  });
}


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    emailEditingController.dispose();
    passEditingController.dispose();
    userNameEditingController.dispose();
    bioEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.jpg',
                // ignore: deprecated_member_use

                height: 50,
              ),
              const SizedBox(
                height: 16,
              ),
              Stack(children: [
                image != null
                    ? CircleAvatar(
                        radius: 64,
                        backgroundImage: MemoryImage(image!),
                      )
                    : const CircleAvatar(
                        backgroundImage: NetworkImage(
                            "https://i.pinimg.com/474x/66/ff/cb/66ffcb56482c64bdf6b6010687938835.jpg"),
                        radius: 64,
                      ),
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () {
                        selectImage();
                      },
                      icon: Icon(Icons.add_a_photo),
                    ))
              ]),
              const SizedBox(
                height: 32,
              ),
              TextFieldInput(
                  textEditingController: emailEditingController,
                  hintText: 'Enter your email',
                  textInputType: TextInputType.emailAddress),
              const SizedBox(
                height: 32,
              ),
              TextFieldInput(
                  textEditingController: passEditingController,
                  hintText: 'Enter your password',
                  isPass: true,
                  textInputType: TextInputType.text),
              const SizedBox(
                height: 32,
              ),
              TextFieldInput(
                  textEditingController: userNameEditingController,
                  hintText: 'Enter your username',
                  textInputType: TextInputType.text),
              const SizedBox(
                height: 32,
              ),
              TextFieldInput(
                  textEditingController: bioEditingController,
                  hintText: 'Enter your bio',
                  textInputType: TextInputType.text),
              const SizedBox(
                height: 32,
              ),
              InkWell(
                onTap: signUpUser,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const ShapeDecoration(
                      color: blueColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)))),
                  child: (isLoading)
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : const Text(
                          'Sign up',
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text("You have an account? "),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()));
                        },
                        child: const Text(
                          "Log in.",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
