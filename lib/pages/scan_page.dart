import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../models/dog.dart';
import '../models/scan_history.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  File? _image;
  bool _isScanning = false;

  final picker = ImagePicker();

  // LOST-DOG PARAMETRELERİ
  String? lostDogId;
  String? lostRecordId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final extra = GoRouterState.of(context).extra;

    if (extra != null && extra is Map<String, dynamic>) {
      lostDogId = extra["lostDogId"];
      lostRecordId = extra["lostRecordId"];
    }
  }

  // -----------------------
  // FOTOĞRAF SEÇME
  // -----------------------
  Future<void> _pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  // -----------------------
  // SAHTE EMBEDDING (MODEL YERİNE)
  // -----------------------
  List<double> _generateFakeEmbedding() {
    final rand = Random();
    return List.generate(128, (_) => rand.nextDouble());
  }

  // -----------------------
  // SCAN START
  // -----------------------
  Future<void> _startScan() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir fotoğraf seç.")),
      );
      return;
    }

    setState(() => _isScanning = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // -----------------------------
      // 1) KULLANICININ TÜM KÖPEKLERİ
      // -----------------------------
      final dogDocs = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("dogs")
          .get();

      if (dogDocs.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıtlı köpeğin yok.")),
        );
        return;
      }

      final dogs = dogDocs.docs.map((d) => Dog.fromMap(d.data())).toList();

      // -----------------------------
      // 2) FOTOĞRAF EMBEDDING
      // -----------------------------
      final scanEmbedding = _generateFakeEmbedding();

      // -----------------------------
      // 3) EŞLEŞTİRME
      // -----------------------------
      Dog? bestMatch;
      double bestScore = -1;

      for (var dog in dogs) {
        // LOSTDOGFLOW → sadece kayıp köpek eşleşsin
        if (lostDogId != null && dog.id != lostDogId) {
          continue; // diğer köpekler devre dışı
        }

        // Geçici FAKE embedding
        final dogEmbedding = _generateFakeEmbedding();

        final score = _cosineSimilarity(scanEmbedding, dogEmbedding);

        if (score > bestScore) {
          bestScore = score;
          bestMatch = dog;
        }
      }

      // Eğer LostDogFlow aktifse → diğer köpekler zaten eşleşmeye girmedi.

      if (bestMatch == null) {
        context.push("/not-found");
        return;
      }

      // -----------------------------
      // 4) SAHTE EŞİK → MODEL GELİNCE AYARLANACAK
      // -----------------------------
      const matchThreshold = 0.75;

      if (lostDogId != null) {
        // 💛 LOST DOG FLOW
        if (bestScore >= matchThreshold) {
          // Firestore'da "found" olarak işaretle
          await FirebaseFirestore.instance
              .collection("lost_dogs")
              .doc(lostRecordId)
              .update({
            "found": true,
            "foundAt": DateTime.now(),
            "matchedDogId": bestMatch.id,
          });

          context.push("/found", extra: bestMatch);
          return;
        } else {
          context.push("/not-found");
          return;
        }
      }

      // -----------------------------
      // 5) NORMAL SCAN FLOW → TARAYI KAYDET
      // -----------------------------
      final ref = FirebaseStorage.instance
          .ref()
          .child("scan_history")
          .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

      await ref.putFile(_image!);
      final scanImageUrl = await ref.getDownloadURL();

      final historyId =
          FirebaseFirestore.instance.collection("scan_history").doc().id;

      final history = ScanHistory(
        id: historyId,
        dogId: bestMatch.id,
        imageUrl: scanImageUrl,
        score: bestScore,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection("scan_history")
          .doc(historyId)
          .set(history.toMap());

      // Sonuç ekranına git
      context.push("/result", extra: {
        "dog": bestMatch,
        "score": bestScore,
        "image": _image,
      });
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  // -----------------------
  // COSINE SIMILARITY
  // -----------------------
  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0;
    double magA = 0;
    double magB = 0;

    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }

    return dot / (sqrt(magA) * sqrt(magB));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Burun İzi Taraması")),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [

            
            // FOTO ALANI
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera_back,
                            size: 60, color: Colors.grey.shade500),
                        const SizedBox(height: 8),
                        Text("Fotoğraf Seçilmedi",
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
            ),

            const SizedBox(height: 20),

            // FOTO SEÇME BUTONLARI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text("Galeriden"),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text("Kamera"),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // TARAMA BUTONU
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isScanning ? null : _startScan,
                child: _isScanning
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ))
                    : const Text("Taramayı Başlat"),
              ),
            ),
          ],
        ),
      ),
    ); 
  }
}
