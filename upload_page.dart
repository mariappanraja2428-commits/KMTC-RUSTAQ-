import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UploadPage extends StatefulWidget {
  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  Uint8List? _imageBytes;
  bool _uploading = false;

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> uploadImage() async {
    if (_imageBytes == null) return;

    setState(() => _uploading = true);

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // 1️⃣ Upload to Firebase Storage
      final storageRef =
          FirebaseStorage.instance.ref().child("uploads/$fileName.jpg");

      await storageRef.putData(_imageBytes!);

      // 2️⃣ Get image URL
      String downloadURL = await storageRef.getDownloadURL();

      // 3️⃣ Store in Firestore
      await FirebaseFirestore.instance.collection("photos").add({
        "url": downloadURL,
        "timestamp": FieldValue.serverTimestamp(),
      });

      setState(() {
        _imageBytes = null;
        _uploading = false;
      });
    } catch (e) {
      print("Upload Error: $e");
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Photo Upload System")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Preview
          if (_imageBytes != null)
            Image.memory(_imageBytes!, height: 180),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: pickImage, child: const Text("Select Photo")),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _uploading ? null : uploadImage,
                child: _uploading
                    ? const CircularProgressIndicator()
                    : const Text("Upload"),
              ),
            ],
          ),

          const Divider(height: 40),
          const Text("Uploaded Records", style: TextStyle(fontSize: 18)),

          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("photos")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    return Image.network(
                      docs[i]["url"],
                      fit: BoxFit.cover,
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
