import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import '../widgets/report_lost_dog_dialog.dart'; // Artık diyaloğu kullanmıyoruz, gerekirse silebilirsiniz
import '../models/dog.dart';
import '../models/scan_history.dart';
import '../widgets/history_card.dart';

class DogDetailPage extends StatefulWidget {
  final Dog dog;

  const DogDetailPage({super.key, required this.dog});

  @override
  State<DogDetailPage> createState() => _DogDetailPageState();
}

class _DogDetailPageState extends State<DogDetailPage> {
  bool _isLost = false;
  String? _lostRecordId;

  @override
  void initState() {
    super.initState();
    _checkLostStatus();
  }

  // Kayıp durumunu kontrol et
  Future<void> _checkLostStatus() async {
    final snap = await FirebaseFirestore.instance
        .collection("lost_dogs")
        .where("dogId", isEqualTo: widget.dog.id)
        .where("found", isEqualTo: false)
        .get();

    if (snap.docs.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isLost = true;
          _lostRecordId = snap.docs.first.id;
        });
      }
    }
  }

  // Bulundu taramasına git
  void _scanForFound() {
    context.push("/scan", extra: {
      "lostDogId": widget.dog.id,
      "lostRecordId": _lostRecordId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dog.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push("/edit-dog", extra: widget.dog),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTOĞRAF
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.dog.imageUrl,
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 260,
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.pets, size: 50)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // BİLGİ KARTI
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dog.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.dog.breed.isNotEmpty
                          ? widget.dog.breed
                          : "Irk: Bilinmiyor",
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Yaş: ${widget.dog.age}",
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 12),

                    if (_isLost)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Bu köpek KAYIP olarak işaretlenmiş!",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // BUTONLAR
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    // DÜZELTİLEN KISIM BURASI
                    onPressed: () {
                      // Diyalog yerine harita sayfasına gidiyoruz.
                      // 'extra' parametresi ile hangi köpeğin kayıp olduğunu bildiriyoruz.
                      context.push("/map", extra: widget.dog.id).then((_) {
                        // Haritadan geri gelindiğinde durumu tekrar kontrol et
                        // (Kayıp ilanı verildiyse arayüz güncellensin)
                        _checkLostStatus();
                      });
                    },
                    icon: const Icon(Icons.location_off),
                    label: const Text("Kayıp Olarak İşaretle"),
                    style: ElevatedButton.styleFrom(
                      // Butonu biraz daha dikkat çekici yapabiliriz (Opsiyonel)
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLost ? _scanForFound : null,
                    icon: const Icon(Icons.search),
                    label: const Text("Bulundu mu?"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isLost ? Colors.green : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // TARİHÇE BAŞLIK
            const Text(
              "Geçmiş Taramalar",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // TARİHÇE LİSTESİ
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('scan_history')
                  .where('dogId', isEqualTo: widget.dog.id)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Bir sorun oluştu:\n${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      "Bu köpek için henüz geçmiş tarama yok.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return Column(
                  children: docs
                      .map((d) => HistoryCard(
                            history: ScanHistory.fromMap(
                                d.data() as Map<String, dynamic>),
                          ))
                      .toList(),
                );
              },
            ),
            
            // Sayfa sonu boşluğu
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}