import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:instagramclone/models/user.dart' as model;
import 'package:instagramclone/resources/storage_methods.dart';

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // // get user details
  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;

    DocumentSnapshot documentSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();

    return model.User.fromSnap(documentSnapshot);
  }

  Future<String> signInWithGoogle() async {
  String res = "Some error Occurred";
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return "Google sign-in cancelled";

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential cred = await _auth.signInWithCredential(credential);
    User? user = cred.user;

    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection("users").doc(user.uid).get();

      if (!doc.exists) {
        model.User newUser = model.User(
          username: user.displayName ?? "No Name",
          uid: user.uid,
          photoUrl: user.photoURL ??
              "https://www.example.com/default-profile-pic.png",
          email: user.email!,
          bio: "",
          followers: [],
          following: [],
        );

        await _firestore.collection("users").doc(user.uid).set(newUser.toJson());
      }

      res = "success";
    }
  } catch (e) {
    res = e.toString();
  }
  return res;
}




 Future<String> signUpUser({
  required String email,
  required String password,
  required String username,
  required String bio,
  required Uint8List file,
}) async {
  String res = "Some error Occurred";
  try {
    if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty && bio.isNotEmpty) {
      // Đăng ký Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Gửi email xác nhận
      await cred.user!.sendEmailVerification();

      // Upload ảnh đại diện
      String photoUrl = await StorageMethods().uploadImageToStorage('profilePics', file, false);

      // Tạo user object
      model.User user = model.User(
        username: username,
        uid: cred.user!.uid,
        photoUrl: photoUrl,
        email: email,
        bio: bio,
        followers: [],
        following: [],
      );

      // Lưu user vào Firestore
      await _firestore.collection("users").doc(cred.user!.uid).set(user.toJson());

      res = "Please verify your email before logging in";
    } else {
      res = "Please enter all the fields";
    }
  } catch (err) {
    return err.toString();
  }
  return res;
}




  Future<String> loginUser({
  required String email,
  required String password,
}) async {
  String res = "Some error Occurred";
  try {
    if (email.isNotEmpty && password.isNotEmpty) {
      // Đăng nhập Firebase
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      
      await cred.user!.reload();
      // if (!cred.user!.emailVerified) {
      //   return "Please verify your email before logging in.";
      // }

      DocumentSnapshot doc =
          await _firestore.collection("users").doc(cred.user!.uid).get();

      if (doc.exists) {
        model.User user = model.User.fromSnap(doc);
        print("User data: ${user.toJson()}");
      } else {
        return "User data not found!";
      }

      res = "success";
    } else {
      res = "Please enter all the fields";
    }
  } catch (err) {
    return err.toString();
  }
  return res;
}






  Future<void> signOut() async {
  try {
    // Kiểm tra nếu user đăng nhập bằng Google
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut(); // Đăng xuất Google
    }

    await _auth.signOut(); // Đăng xuất Firebase
  } catch (e) {
    print("Error signing out: $e");
  }
}

}
