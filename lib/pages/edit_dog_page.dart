import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import '../components/model_warning.dart'; // İsterseniz kaldırabilirsiniz
import '../models/dog.dart';

class EditDogPage extends StatefulWidget {
  final Dog dog;

  const EditDogPage({super.key, required this.dog});

  @override
  State<EditDogPage> createState() => _EditDogPageState();
}

class _EditDogPageState extends State<EditDogPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _breedCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _phoneCtrl; // 📞 YENİ

  File? _newImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.dog.name);
    _breedCtrl = TextEditingController(text: widget.dog.breed);
    _ageCtrl = TextEditingController(text: widget.dog.age.toString());
    // Köpeğin mevcut telefon numarasını yükle
    _phoneCtrl = TextEditingController(text: widget.dog.ownerPhone); 
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _newImage = File(image.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String imageUrl = widget.dog.imageUrl;

      // Yeni fotoğraf seçildiyse yükle
      if (_newImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('dog_images') // Klasör adı AddDogPage ile aynı olmalı
            .child(uid)
            .child('${widget.dog.id}.jpg');

        await ref.putFile(_newImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // Firestore güncelleme
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dogs')
          .doc(widget.dog.id)
          .update({
        "name": _nameCtrl.text.trim(),
        "breed": _breedCtrl.text.trim(),
        "age": int.tryParse(_ageCtrl.text.trim()) ?? 0,
        "imageUrl": imageUrl,
        "ownerPhone": _phoneCtrl.text.trim(), // 📞 GÜNCELLENEN ALAN
      });

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Köpek bilgileri güncellendi")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Köpeği Düzenle")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Fotoğraf
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    // ⚡ OPTİMİZE EDİLDİ: CachedNetworkImageProvider
                    backgroundImage: _newImage != null
                        ? FileImage(_newImage!)
                        : (widget.dog.imageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(widget.dog.imageUrl) // <-- DEĞİŞEN KISIM
                            : null) as ImageProvider?,
                    child: widget.dog.imageUrl.isEmpty && _newImage == null
                        ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                        : null, 
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text("Fotoğrafı Değiştir", style: TextStyle(color: Colors.blue, fontSize: 12)),

              const SizedBox(height: 24),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Adı",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (v) => v!.isEmpty ? "Bu alan boş olamaz" : null,
              ),
              
              const SizedBox(height: 16),

              TextFormField(
                controller: _breedCtrl,
                decoration: const InputDecoration(
                  labelText: "Irkı",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),

              const SizedBox(height: 16),

              // YAŞ VE TELEFON YANYANA
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Yaşı",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // 📞 TELEFON ALANI
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Sahibinin Tel",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("KAYDET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}