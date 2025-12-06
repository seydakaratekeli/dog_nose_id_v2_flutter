import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

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

  File? _newImage;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.dog.name);
    _breedCtrl = TextEditingController(text: widget.dog.breed);
    _ageCtrl = TextEditingController(text: widget.dog.age.toString());
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

    final uid = FirebaseAuth.instance.currentUser!.uid;
    String imageUrl = widget.dog.imageUrl;

    // Yeni fotoğraf seçildiyse yükle
    if (_newImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('dogs')
          .child('$uid-${widget.dog.id}.jpg');

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
      "name": _nameCtrl.text,
      "breed": _breedCtrl.text,
      "age": int.parse(_ageCtrl.text),
      "imageUrl": imageUrl,
    });

    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Köpek bilgileri güncellendi")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Köpeği Düzenle")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,

          child: ListView(
            children: [
              // Fotoğraf
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: _newImage != null
                        ? FileImage(_newImage!)
                        : (widget.dog.imageUrl.isNotEmpty
                            ? NetworkImage(widget.dog.imageUrl)
                            : null) as ImageProvider?,
                    child: widget.dog.imageUrl.isEmpty && _newImage == null
                        ? const Icon(Icons.pets, size: 40)
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Adı"),
                validator: (v) => v!.isEmpty ? "Bu alan boş olamaz" : null,
              ),

              TextFormField(
                controller: _breedCtrl,
                decoration: const InputDecoration(labelText: "Irkı"),
              ),

              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Yaşı"),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _save,
                child: const Text("Kaydet"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
