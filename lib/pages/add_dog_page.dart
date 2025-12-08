import 'dart:io';
import 'dart:math'; // Rastgele embedding için
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../models/dog.dart';

class AddDogPage extends StatefulWidget {
  const AddDogPage({super.key});

  @override
  State<AddDogPage> createState() => _AddDogPageState();
}

class _AddDogPageState extends State<AddDogPage> {
  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController(); // 📞 YENİ: Telefon kontrolcüsü

  File? _selectedImage;
  bool _isLoading = false;

  // Fotoğraf Seçimi
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery); // veya camera
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  // Geçici (Fake) Embedding Üretici
  // (Yapay zeka modeli entegre edilene kadar yer tutucu)
  List<double> _generateEmptyEmbedding() {
    return List.filled(128, 0.0);
  }

  // Kaydetme İşlemi
  Future<void> _saveDog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir fotoğraf seçin.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final uuid = const Uuid().v4(); // Benzersiz Köpek ID'si

      // 1. Fotoğrafı Storage'a Yükle
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("dog_images")
          .child(uid)
          .child("$uuid.jpg");
      
      await storageRef.putFile(_selectedImage!);
      final imageUrl = await storageRef.getDownloadURL();

      // 2. Dog Nesnesini Oluştur
      final newDog = Dog(
        id: uuid,
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        imageUrl: imageUrl,
        embedding: _generateEmptyEmbedding(),
        ownerPhone: _phoneController.text.trim(), // 📞 TELEFON EKLENDİ
      );

      // 3. Firestore'a Kaydet
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("dogs")
          .doc(uuid)
          .set(newDog.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Köpek başarıyla kaydedildi!")),
        );
        context.pop(); // Sayfadan çık
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Köpek Ekle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // FOTOĞRAF ALANI
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Fotoğraf Seç", style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : null,
                ),
              ),
              
              const SizedBox(height: 24),

              // İSİM
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Köpeğin Adı",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (value) => value == null || value.isEmpty ? "İsim giriniz" : null,
              ),

              const SizedBox(height: 16),

              // IRK
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: "Irkı (Opsiyonel)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),

              const SizedBox(height: 16),

              // YAŞ VE TELEFON YANYANA (Veya alt alta)
              Row(
                children: [
                  // YAŞ
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Yaş",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // 📞 TELEFON NUMARASI
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone, // Sayısal klavye açar
                      decoration: const InputDecoration(
                        labelText: "Sahibinin Tel",
                        hintText: "5XX...",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      // İsterseniz zorunlu yapabilirsiniz:
                      // validator: (val) => val!.isEmpty ? "Telefon giriniz" : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // KAYDET BUTONU
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDog,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("KAYDET", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}