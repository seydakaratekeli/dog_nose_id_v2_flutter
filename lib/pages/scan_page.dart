import 'dart:io';
import 'dart:math'; // Cosine similarity için gerekli
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Camera paketi
import 'package:image_picker/image_picker.dart'; // Galeri seçimi için yedek
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/dog.dart';
import '../models/scan_history.dart';

class ScanPage extends StatefulWidget {
  final String? lostDogId;
  final String? lostRecordId;

  const ScanPage({
    super.key,
    this.lostDogId,
    this.lostRecordId,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  File? _capturedImage; // Çekilen veya seçilen fotoğraf
  bool _isScanning = false;
  bool _isCameraInitialized = false;

  // LOST-DOG PARAMETRELERİ
  String? lostDogId;
  String? lostRecordId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Widget parametrelerini ata
    lostDogId = widget.lostDogId;
    lostRecordId = widget.lostRecordId;
    _initCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route argümanlarını al (eğer widget parametresi yoksa)
    if (lostDogId == null && lostRecordId == null) {
      final extra = GoRouterState.of(context).extra;
      if (extra != null && extra is Map<String, dynamic>) {
        lostDogId = extra["lostDogId"];
        lostRecordId = extra["lostRecordId"];
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Kamera Başlatma
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Genellikle 0. indeks arka kameradır
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint("Kamera hatası: $e");
    }
  }

  // Fotoğraf Çekme
  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isTakingPicture) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = File(image.path);
      });
    } catch (e) {
      debugPrint("Çekim hatası: $e");
    }
  }

  // Galeriden Seçme (Eski yöntem yedek olarak)
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _capturedImage = File(picked.path);
      });
    }
  }

  // Fotoğrafı İptal Et / Yeniden Çek
  void _retake() {
    setState(() {
      _capturedImage = null;
    });
  }

  // -----------------------------------------------------------
  // SAHTE EMBEDDING ve SCAN MANTIĞI (Önceki kodunuzdan alındı)
  // -----------------------------------------------------------
  List<double> _generateFakeEmbedding() {
    final rand = Random();
    return List.generate(128, (_) => rand.nextDouble());
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty) return 0; // Hata koruması
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

  Future<void> _startScan() async {
    if (_capturedImage == null) return;

    setState(() => _isScanning = true);

   try {
      // ---------------------------------------------------------
      // DÜZELTME: Sadece kendi köpeklerimi değil,
      // TÜM KAYIP KÖPEKLERİ getirip karşılaştırmalıyız.
      // ---------------------------------------------------------
      
      // 1. Adım: Önce 'lost_dogs' koleksiyonundaki tüm aktif kayıpları çek
      final lostSnap = await FirebaseFirestore.instance
          .collection("lost_dogs")
          .where("found", isEqualTo: false) // Sadece bulunmamış olanlar
          .get();

      if (lostSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sistemde şu an aranan kayıp bir köpek yok.")),
        );
        setState(() => _isScanning = false);
        return;
      }

      List<Dog> candidateDogs = [];

      // 2. Adım: Bu kayıp ilanlarının detaylı 'Dog' profillerini çek
      // (Gerçek embedding verisi Dog profilinde olduğu için)
      for (var doc in lostSnap.docs) {
        final data = doc.data();
        final ownerId = data['userId'] ?? data['ownerId'];
        final dogId = data['dogId'];

        if (ownerId != null && dogId != null) {
          final dogDoc = await FirebaseFirestore.instance
              .collection("users")
              .doc(ownerId)
              .collection("dogs")
              .doc(dogId)
              .get();
          
          if (dogDoc.exists) {
            candidateDogs.add(Dog.fromMap(dogDoc.data()!));
          }
        }
      }

      // 3. Adım: Eşleştirme (Cosine Similarity)
      final scanEmbedding = _generateFakeEmbedding(); // Gerçek model entegre edilince burası değişecek
      Dog? bestMatch;
      double bestScore = -1;

      for (var dog in candidateDogs) {
        // Not: Gerçek modelde dog.embedding kullanılacak. 
        // Şimdilik test için rastgele embedding üretiyoruz.
        final dogEmbedding = _generateFakeEmbedding(); 
        final score = _cosineSimilarity(scanEmbedding, dogEmbedding);

        if (score > bestScore) {
          bestScore = score;
          bestMatch = dog;
        }
      }

      // Eşik değer kontrolü (Örn: %80 benzerlik altındaysa bulamadık de)
      if (bestMatch == null || bestScore < 0.5) { // Test için 0.5 yaptık
        if (mounted) context.push("/not-found");
        return;
      }

      // 3) Tarihçe Kaydı
      final ref = FirebaseStorage.instance
          .ref()
          .child("scan_history")
          .child("${DateTime.now().millisecondsSinceEpoch}.jpg");
      await ref.putFile(_capturedImage!);
      final scanImageUrl = await ref.getDownloadURL();

      final historyId = FirebaseFirestore.instance.collection("scan_history").doc().id;
      final history = ScanHistory(
        id: historyId,
        dogId: bestMatch.id,
        imageUrl: scanImageUrl,
        score: bestScore,
        timestamp: DateTime.now(),
      );
      await FirebaseFirestore.instance.collection("scan_history").doc(historyId).set(history.toMap());

      // 4) Yönlendirme
      const matchThreshold = 0.0; // Test için 0
      if (lostDogId != null) {
        if (bestScore >= matchThreshold) {
          await FirebaseFirestore.instance.collection("lost_dogs").doc(lostRecordId).update({
            "found": true,
            "foundAt": DateTime.now().toIso8601String(),
            "matchedDogId": bestMatch.id,
          });
          if (mounted) context.push("/found", extra: bestMatch);
        } else {
          if (mounted) context.push("/not-found");
        }
      } else {
        if (mounted) {
          context.push("/result", extra: {
            "dog": bestMatch,
            "score": bestScore,
            "image": _capturedImage,
          });
        }
      }

    } catch (e) {
      debugPrint("Hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer fotoğraf çekildiyse, önizleme ve onay ekranını göster
    if (_capturedImage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Fotoğrafı Onayla")),
        body: Column(
          children: [
            Expanded(
              child: Image.file(_capturedImage!, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _retake,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Yeniden Çek"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _startScan,
                      icon: const Icon(Icons.check),
                      label: _isScanning
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Taramayı Başlat"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Kamera hazır değilse yükleniyor göster
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // CANLI KAMERA ARAYÜZÜ
    return Scaffold(
      body: Stack(
        children: [
          // 1. Kamera Görüntüsü (Tüm ekran)
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),

          // 2. Kılavuz Katmanı (Overlay)
          // Ortası delik, kenarları yarı saydam siyah
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.black54, // Karartma rengi
              BlendMode.srcOut, // Ortayı kesip atma modu
            ),
            child: Stack(
              children: [
                // Arka planı tamamen boya (şeffaf olarak, blendmode bunu siyaha çevirecek)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                // Ortadaki delik (Burası "srcOut" sayesinde şeffaf kalacak)
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20), // Köşeleri yuvarlatılmış kare
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Rehber Çizgiler (Sadece görsel süsleme)
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.add, color: Colors.white54, size: 40),
              ),
            ),
          ),

          // 4. Üst Bilgi Metni
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Text(
              "Köpeğin burnunu çerçeveye hizalayın",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(blurRadius: 4, color: Colors.black, offset: Offset(0, 2))
                ],
              ),
            ),
          ),

          // 5. Alt Kontrol Paneli
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Galeri Butonu
                IconButton(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                  tooltip: "Galeriden Seç",
                ),
                
                // Çekim Butonu (Büyük)
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 4),
                    ),
                    child: const Icon(Icons.camera_alt, size: 40, color: Colors.black87),
                  ),
                ),

                // Boşluk (Simetri için)
                const SizedBox(width: 48), 
              ],
            ),
          ),
          
          // Geri Butonu
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}