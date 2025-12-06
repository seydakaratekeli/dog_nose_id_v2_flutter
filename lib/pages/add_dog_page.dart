import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../models/dog.dart';

class AddDogPage extends StatefulWidget {
  const AddDogPage({super.key});

  @override
  State<AddDogPage> createState() => _AddDogPageState();
}

class _AddDogPageState extends State<AddDogPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final ageController = TextEditingController();

  File? _image;
  bool _loading = false;


 // ---------------------------------------
  // 1) BOŞ EMBEDDING OLUŞTURAN FONKSİYON
  // (Geçici, model gelince gerçek embedding gelecek)
  // ---------------------------------------
  List<double> _emptyEmbedding() {
    return List.generate(128, (_) => 0.0);
  }
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _saveDog() async {
    if (!_formKey.currentState!.validate()) return;

    if (_image == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Lütfen fotoğraf seç.")));
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      /// 1) Fotoğrafı Storage'a yükle
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("dogs")
          .child("$uid-${DateTime.now().millisecondsSinceEpoch}.jpg");

      await storageRef.putFile(_image!);
      final imageUrl = await storageRef.getDownloadURL();

      /// 2) Dog ID oluştur
      final dogId = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("dogs")
          .doc()
          .id;

      /// 3) Dog model oluştur
     final dog = Dog(
  id: dogId,
  name: nameController.text.trim(),
  breed: breedController.text.trim(),
  age: int.tryParse(ageController.text.trim()) ?? 0,
  imageUrl: imageUrl,
  embedding: _emptyEmbedding(), // ← ZORUNLU ALAN EKLENDİ
);


      /// 4) Firestore'a kaydet
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("dogs")
          .doc(dogId)
          .set(dog.toMap());

      if (mounted) {
        context.pop(); // Sayfayı kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${dog.name} eklendi.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Köpek Ekle")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------
              // FOTOĞRAF ALANI
              // ------------------------
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _image == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  size: 50, color: Colors.grey.shade700),
                              const SizedBox(height: 8),
                              Text("Fotoğraf Seç",
                                  style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_image!, fit: BoxFit.cover),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------
              // FORM ALANLARI
              // ------------------------

              Text("Köpek Bilgileri",
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Adı",
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (v) =>
                    v!.isEmpty ? "Bu alan boş olamaz." : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: breedController,
                decoration: const InputDecoration(
                  labelText: "Irkı",
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Yaşı",
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------
              // KAYDET BUTONU
              // ------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveDog,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ))
                      : const Text("Kaydet"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
