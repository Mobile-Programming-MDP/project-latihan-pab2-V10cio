import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shimmer/shimmer.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});
  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _image;
  String? _base64Image;
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double? _latitude;
  double? _longitude;
  String? _aiCategory;
  String? _aiDescription;
  bool _isGenerating = false;
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
  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: categories.map((category) {
            return ListTile(
              title: Text(category),
              onTap: () {
                setState(() {
                  _aiCategory =
                      category; // Ganti AI category dengan pilihan user
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _aiCategory = null;
          _aiDescription = null;
          _descriptionController.clear();
        });
        await _compressAndEncodeImage();
        await _generateDescriptionWithAI();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _compressAndEncodeImage() async {
    if (_image == null) return;
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        _image!.path,
        quality: 50,
      );
      if (compressedImage == null) return;
      setState(() {
        _base64Image = base64Encode(compressedImage);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to compress image: $e')));
      }
    }
  }

  Future<void> _generateDescriptionWithAI() async {
    if (_image == null) return;
    setState(() => _isGenerating = true);
    try {
      //RequestOptions ro = const RequestOptions(apiVersion: 'v1');
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey:
            'AIzaSyDGbZbX46WD5VlliHmT-nm1vrptlIur7_c', //gunakan api key gemini anda
        //requestOptions: ro,
      );
      final imageBytes = await _image!.readAsBytes();
      final content = Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(
          'Berdasarkan foto ini, identifikasi satu kategori utama kerusakan fasilitas umum '
          'dari daftar berikut: Jalan Rusak, Marka Pudar, Lampu Mati, Trotoar Rusak, '
          'Rambu Rusak, Jembatan Rusak, Sampah Menumpuk, Saluran Tersumbat, Sungai Tercemar, '
          'Sampah Sungai, Pohon Tumbang, Taman Rusak, Fasilitas Rusak, Pipa Bocor, '
          'Vandalisme, Banjir, dan Lainnya. '
          'Pilih kategori yang paling dominan atau paling mendesak untuk dilaporkan. '
          'Buat deskripsi singkat untuk laporan perbaikan, dan tambahkan permohonan perbaikan. '
          'Fokus pada kerusakan yang terlihat dan hindari spekulasi.\n\n'
          'Format output yang diinginkan:\n'
          'Kategori: [satu kategori yang dipilih]\n'
          'Deskripsi: [deskripsi singkat]'
          'Jangan menambahkan output lain di luar format ini. Output harus dalam format plaintext\n\n',
        ),
      ]);
      final response = await model.generateContent([content]);
      final aiText = response.text;
      print("AI TEXT: $aiText");
      if (aiText != null && aiText.isNotEmpty) {
        final lines = aiText.trim().split('\n');
        String? category;
        String? description;
        for (var line in lines) {
          final lower = line.toLowerCase();
          if (lower.startsWith('kategori:')) {
            category = line.substring(9).trim();
          } else if (lower.startsWith('deskripsi:')) {
            description = line.substring(10).trim();
          } else if (lower.startsWith('keterangan:')) {
            description = line.substring(11).trim();
          }
        }
        description ??= aiText.trim();
        setState(() {
          _aiCategory = category ?? 'Tidak diketahui';
          _aiDescription = description!;
          _descriptionController.text = _aiDescription!;
        });
      }
    } catch (e) {
      debugPrint('Failed to generate AI description: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      debugPrint('Failed to retrieve location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to retrieve location: $e')),
      );
      setState(() {
        _latitude = null;
        _longitude = null;
      });
    }
  }

  Future<void> sendNotificationToTopic(String body, String senderName) async {
    final url = Uri.parse('https://cio-fs-cloud.vercel.app/send-to-topic');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "topic": "berita-fasum",
        "title": "🔔 Laporan Baru",
        "body": body,
        "senderName": senderName,
        "senderPhotoUrl":
            "data:image/png;base64,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",
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Notifikasi berhasil dikirim")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Gagal kirim notifikasi: ${response.body}")),
        );
      }
    }
  }
  try {
  await _getLocation();

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  final fullName = userDoc.data()?['fullName'] ?? 'Anonymous';

  await FirebaseFirestore.instance.collection('posts').add({
    'image': _base64Image,
    'description': _descriptionController.text,
    'aiCategory': _aiCategory ?? 'Tidak diketahui',
    'createdAt': now,
    'latitude': _latitude,
    'longitude': _longitude,
    'fullName': fullName,
    'userId': uid,
  });

  if (!mounted) return;

  sendNotificationToTopic(_descriptionController.text, fullName);

  Navigator.pop(context);
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('Post uploaded successfully!')));
} catch (e) {
  debugPrint('Upload failed: $e');
  if (!mounted) return;
  setState(() => _isUploading = false);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("❌ Upload gagal")),
  );
}

  Future<void> _submitPost() async {
    if (_base64Image == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an image and description.')),
      );
      return;
    }
    setState(() => _isUploading = true);
    final now = DateTime.now().toIso8601String();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please signin.')),
      );
      return;
    }
    try {
      await _getLocation();
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final fullName = userDoc.data()?['fullName'] ?? 'Anonymous';
      await FirebaseFirestore.instance.collection('posts').add({
        'image': _base64Image,
        'description': _descriptionController.text,
        'category': _aiCategory ?? 'Tidak diketahui',
        'createdAt': now,
        'latitude': _latitude,
        'longitude': _longitude,
        'fullName': fullName,
        'userId': uid,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post uploaded successfully!')),
      );
    } catch (e) {
      debugPrint('Upload failed: $e');
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload the post: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _image!,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.add_a_photo,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Efek shimmer saat generating
            if (_isGenerating)
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                    Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            // Kategori dan tombol refresh
            if (_aiCategory != null && !_isGenerating)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _showCategorySelection,
                      child: Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_aiCategory!),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit, size: 16),
                          ],
                        ),
                        backgroundColor: Colors.blue[100],
                      ),
                    ),
                    if (_image != null)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Generate another description',
                        onPressed: _generateDescriptionWithAI,
                      ),
                  ],
                ),
              ),
            // TextField untuk deskripsi
            Offstage(
              offstage: _isGenerating,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Add a brief description...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tombol kirim post
            ElevatedButton(
              onPressed: _isUploading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.green,
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
