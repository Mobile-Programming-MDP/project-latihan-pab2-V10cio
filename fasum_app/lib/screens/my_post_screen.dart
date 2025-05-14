import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/screens/detail_screen.dart';
import 'package:fasum/screens/edit_post_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({Key? key}) : super(key: key);

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} secs ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hrs ago';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  //hapus data
  Future<void> _deletePost(String postId, BuildContext context) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && mounted) {
      // Implement delete functionality
      FirebaseFirestore.instance.collection("posts").doc(postId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Posts"),
        ),
        body: const Center(
          child: Text("You need to log in to view your posts."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Posts"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("posts")
            .where("userId", isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Trapped in has error ${!snapshot.hasData}");
            print("${snapshot.error}");

            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return const Center(
              child: Text("You haven't created any posts yet."),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index].data();
              final imageBase64 = data['image'];
              final description = data['description'];
              final createdAtStr = data['createdAt'];
              final fullName = data['fullName'] ?? 'Anonim';
              final latitude = data['latitude'];
              final longitude = data['longitude'];
              final category = data['category'] ?? 'Lainnya';

              // Parse createdAt to DateTime
              final createdAt = DateTime.parse(createdAtStr);
              String heroTag =
                  'my-post-image-${createdAt.millisecondsSinceEpoch}';

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          imageBase64: imageBase64,
                          description: description,
                          createdAt: createdAt,
                          fullName: fullName,
                          latitude: latitude,
                          longitude: longitude,
                          category: category,
                          heroTag: heroTag,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageBase64 != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10)),
                          child: Image.memory(
                            base64Decode(imageBase64),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatTime(createdAt),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Text(category),
                            Text(
                              description ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () {
                                    // Navigate to edit screen or implement edit functionality
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditPostScreen(
                                          postId: posts[index].id,
                                          imageBase64: imageBase64,
                                          description: description,
                                          category: category,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    // Call the delete function
                                    await _deletePost(
                                        posts[index].id, this.context);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
