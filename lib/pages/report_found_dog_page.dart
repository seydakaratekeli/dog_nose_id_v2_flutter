import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ReportFoundDogPage extends StatefulWidget {
  const ReportFoundDogPage({super.key});

  @override
  State<ReportFoundDogPage> createState() => _ReportFoundDogPageState();
}

class _ReportFoundDogPageState extends State<ReportFoundDogPage> {
  File? _image;
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _loading = false;
  
  // Konum bilgileri
  double? _lat;
  double? _lng;
  String _address = "Konum alınıyor...";

  @override
  void initState() {
    super.initState();
    _getLocation(); // Sayfa açılınca konumu bul
  }

  // Konumu Otomatik Al
  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        if (placemarks.isNotEmpty) {
           _address = "${placemarks[0].thoroughfare}, ${placemarks[0].subAdministrativeArea}";
        } else {
          _address = "Konum alındı (${position.latitude.toStringAsFixed(4)})";
        }
      });
    } catch (e) {
      setState(() => _address = "Konum alınamadı. Lütfen GPS'i açın.");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera); // Doğrudan kamera
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submitReport() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen köpeğin fotoğrafını çekin.")));
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // 1. Resmi Yükle
      final ref = FirebaseStorage.instance.ref().child('found_dogs').child('$fileName.jpg');
      await ref.putFile(_image!);
      final imageUrl = await ref.getDownloadURL();

      // 2. Veritabanına Kaydet (Farklı koleksiyon: 'found_dogs')
      await FirebaseFirestore.instance.collection('found_dogs').add({
        'reporterId': uid,
        'imageUrl': imageUrl,
        'breed': _breedController.text.trim().isEmpty ? 'Bilinmiyor' : _breedController.text.trim(),
        'note': _noteController.text.trim(),
        'lat': _lat,
        'lng': _lng,
        'address': _address,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sighted', // Görüldü
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bildiriminiz yayınlandı! Teşekkürler.")));
        context.go('/home'); // Ana sayfaya dön
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Görülen Köpek Bildir")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FOTOĞRAF ALANI
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null,
                ),
                child: _image == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.camera_alt, size: 50, color: Colors.grey), Text("Fotoğraf Çek")],
                    ) 
                  : null,
              ),
            ),
            const SizedBox(height: 20),

            // KONUM BİLGİSİ
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.orange),
              title: const Text("Konum"),
              subtitle: Text(_address),
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 10),

            // FORM ALANLARI
            TextField(
              controller: _breedController,
              decoration: const InputDecoration(labelText: "Tahmini Irk (Opsiyonel)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Notlar (Tasması var mı? Yaralı mı?)", border: OutlineInputBorder()),
            ),
            
            const SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: _loading ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: _loading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("BİLDİRİMİ YAYINLA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}