import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dog.dart'; // Dog modelini import et

class ReportLostDogDialog extends StatefulWidget {
  final Dog dog; // Hangi köpek kayıp? Bunu parametre olarak alalım.

  const ReportLostDogDialog({super.key, required this.dog});

  @override
  _ReportLostDogDialogState createState() => _ReportLostDogDialogState();
}

class _ReportLostDogDialogState extends State<ReportLostDogDialog> {
  bool _loading = false;

  Future<void> _reportLostDog() async {
    setState(() => _loading = true);

    try {
      // 1. Konum izni ve mevcut konum alma
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
           throw Exception("Konum izni verilmedi");
        }
      }
      
      final position = await Geolocator.getCurrentPosition();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 2. Koleksiyon ismini DÜZELTTİK: 'lost_dogs' yaptık
      final reportRef = FirebaseFirestore.instance.collection('lost_dogs').doc();

      // 3. Veriyi hazırlama
      final reportData = {
        'id': reportRef.id,        // Kaydın ID'si
        'dogId': widget.dog.id,    // Köpeğin ID'si
        'ownerId': uid,
        'dogName': widget.dog.name,
        'imageUrl': widget.dog.imageUrl,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'found': false,            // Henüz bulunmadı
      };

      await reportRef.set(reportData);

      if (mounted) {
        Navigator.pop(context, true); // true döndürerek işlemin bittiğini haber verelim
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıp ilanı başarıyla oluşturuldu!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("${widget.dog.name} Kayıp mı?"),
      content: const Text("Mevcut konumunuz kullanılarak kayıp ilanı oluşturulacak."),
      actions: [
        TextButton(
          child: const Text("İptal"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _reportLostDog,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Text("Kayıp İlanı Oluştur", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}