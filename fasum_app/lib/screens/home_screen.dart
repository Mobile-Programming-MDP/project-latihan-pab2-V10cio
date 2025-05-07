import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/screens/add_post_screen.dart';
import 'package:fasum/screens/detail_screen.dart';
import 'package:fasum/screens/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  String? selectedCategory;
  List<String> categories = [
    'Jalan Rusak',
    'Marka Pudar',
    'Lampu Mati',
    'Trotoar Rusak',
    'Rambu Rusak',
    'Jembatan Rusak',
    'Sampah Menumpuk',
    'Saluran Tersumbat',
    'Sungai Tercemar',
    'Sampah Sungai',
    'Pohon Tumbang',
    'Taman Rusak',
    'Fasilitas Rusak',
    'Pipa Bocor',
    'Vandalisme',
    'Banjir',
    'Lainnya',
  ];

  void _showCategoryFilter() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('Semua Kategori'),
                  onTap: () => Navigator.pop(
                    context,
                    null,
                  ), // Null untuk memilih semua kategori
                ),
                const Divider(),
                ...categories.map(
                  (category) => ListTile(
                    title: Text(category),
                    trailing: selectedCategory == category
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, category),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        selectedCategory =
            result; // Set kategori yang dipilih atau null untuk Semua Kategori
      });
    } else {
      // Jika result adalah null, berarti memilih Semua Kategori
      setState(() {
        selectedCategory =
            null; // Reset ke null untuk menampilkan semua kategori
      });
    }
  }

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showCategoryFilter,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: () {
              signOut(context);
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); //mencegah stuck
        },
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("posts")
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final posts = snapshot.data!.docs.where((doc) {
              final data = doc.data();

              final Category = data['category'] ?? 'Lainnya';
              return selectedCategory == null || selectedCategory == Category;
            }).toList(); // untuk mengambil data snapshot dari firestore tanpa filter
            if (posts.isEmpty) {
              return const Center(
                child: Text('Tidak ada laporan untuk kategori ini'),
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
                //parse ke DateTime
                final createdAt = DateTime.parse(createdAtStr);
                String heroTag =
                    'fasum-image.${createdAt.millisecondsSinceEpoch}';
                return InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DetailScreen(
                                imageBase64: imageBase64,
                                description: description,
                                createdAt: createdAt,
                                fullName: fullName,
                                latitude: 0.0,
                                longitude: 0.0,
                                category: 'Jalan Rusak',
                                heroTag: heroTag)));
                  },
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageBase64 != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10)),
                            child: Image.memory(base64Decode(imageBase64),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatTime(createdAt),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    fullName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                description ?? '',
                                style: const TextStyle(fontSize: 16),
                              )
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => AddPostScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
