import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:instagramclone/models/post.dart';
import 'package:instagramclone/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadPost(String des, Uint8List file, String uid,
      String username, String profImage) async {
    String res = "Some error occurred";
    try {
      String photoUrl =
          await StorageMethods().uploadImageToStorage('post', file, true);
      String postId = const Uuid().v1();
      Post post = Post(
          description: des,
          uid: uid,
          username: username,
          likes: [],
          postId: postId,
          datePublished: DateTime.now(),
          postUrl: photoUrl,
          profImage: profImage);

      _firestore.collection('posts').doc(postId).set(post.toJson());
      res = "success";
    } catch (e) {
      res = e.toString();
    }

    return res;
  }

 Future<void> likePost(String postId, String uid, List likes) async {
  try {
    DocumentSnapshot postSnap =
        await _firestore.collection('posts').doc(postId).get();

    if (!postSnap.exists) return;

    String postOwnerId = postSnap['uid']; // Lấy chủ bài viết

    if (likes.contains(uid)) {
      // Nếu đã like, thì unlike và xóa thông báo
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([uid])
      });

      // Xóa thông báo khi unlike
      QuerySnapshot notiSnap = await _firestore
          .collection('notifications')
          .where('postId', isEqualTo: postId)
          .where('senderId', isEqualTo: uid)
          .where('type', isEqualTo: 'like')
          .get();

      for (var doc in notiSnap.docs) {
        await _firestore.collection('notifications').doc(doc.id).delete();
      }
    } else {
      // Nếu chưa like, thì like bài viết
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([uid])
      });

      // Chỉ thêm thông báo nếu người like không phải là chủ bài viết
      if (uid != postOwnerId) {
        await _firestore.collection('notifications').add({
          'type': 'like',
          'senderId': uid,
          'receiverId': postOwnerId,
          'postId': postId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  } catch (e) {
    print(e.toString());
  }
}



  Future<void> postComment(String postId, String text, String uid, String name,
    String profilePic) async {
  try {
    if (text.isNotEmpty) {
      String commentId = const Uuid().v1();
      DocumentSnapshot postSnap = await _firestore.collection('posts').doc(postId).get();

      String postOwnerId = postSnap['uid']; // Lấy ID chủ bài viết
      String notificationId = const Uuid().v1(); // ID cho thông báo

      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .set({
        'profilePic': profilePic,
        'name': name,
        'uid': uid,
        'text': text,
        'commentId': commentId,
        'datePublished': DateTime.now(),
      });

      
      if (postOwnerId != uid) {
        await _firestore.collection('notifications').doc(notificationId).set({
          'receiverId': postOwnerId, 
          'senderId': uid, 
          'postId': postId,
          'type': 'comment',
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } else {
      print('Text is empty');
    }
  } catch (e) {
    print(e.toString());
  }
}



  Future<String> deletePost(String postId) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('posts').doc(postId).delete();
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<void> followUser(String uid, String followId) async {
  try {
    DocumentSnapshot snap = await _firestore.collection('users').doc(uid).get();
    List following = (snap.data()! as dynamic)['following'];

    if (following.contains(followId)) {
      // Nếu đã follow thì unfollow
      await _firestore.collection('users').doc(followId).update({
        'followers': FieldValue.arrayRemove([uid])
      });

      await _firestore.collection('users').doc(uid).update({
        'following': FieldValue.arrayRemove([followId])
      });

      // Xóa thông báo khi unfollow
      QuerySnapshot notiSnap = await _firestore
          .collection('notifications')
          .where('type', isEqualTo: 'follow')
          .where('senderId', isEqualTo: uid)
          .where('receiverId', isEqualTo: followId)
          .get();

      for (var doc in notiSnap.docs) {
        await _firestore.collection('notifications').doc(doc.id).delete();
      }
    } else {
      // Nếu chưa follow thì follow
      await _firestore.collection('users').doc(followId).update({
        'followers': FieldValue.arrayUnion([uid])
      });

      await _firestore.collection('users').doc(uid).update({
        'following': FieldValue.arrayUnion([followId])
      });

      // Thêm thông báo follow
      await _firestore.collection('notifications').add({
        'type': 'follow',
        'senderId': uid,
        'receiverId': followId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  } catch (e) {
    if (kDebugMode) print(e.toString());
  }
}

}
