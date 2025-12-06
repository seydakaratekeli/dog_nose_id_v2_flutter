import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/dog.dart';
import '../models/scan_history.dart';
import '../widgets/history_card.dart';

class DogDetailPage extends StatelessWidget {
  final Dog dog;

  const DogDetailPage({super.key, required this.dog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dog.name),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------- FOTO --------------------
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  dog.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // -------------------- KÖPEK BİLGİLERİ --------------------
            Text(
              dog.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              dog.breed.isNotEmpty ? dog.breed : "Irk: Bilinmiyor",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 4),

            Text(
              "Yaş: ${dog.age}",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            // -------------------- DÜZENLE & SİL --------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/edit-dog', extra: dog);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Düzenle"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _confirmDelete(context, dog);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text("Sil"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // -------------------- KAYIP OLARAK İŞARETLE --------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/map');
                },
                icon: const Icon(Icons.location_off),
                label: const Text("Köpeğimi Kayıp Olarak İşaretle"),
              ),
            ),

            const SizedBox(height: 20),

            // -------------------- GEÇMİŞ TARAMALAR BAŞLIĞI --------------------
            const Text(
              "Geçmiş Taramalar",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // -------------------- GEÇMİŞ TARAMALAR --------------------
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('scan_history')
                    .where('dogId', isEqualTo: dog.id)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Bu köpek için geçmiş tarama bulunamadı.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final history = ScanHistory.fromMap(
                        docs[index].data() as Map<String, dynamic>,
                      );

                      return HistoryCard(history: history);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- SİLME ONAY PENCERESİ --------------------
  void _confirmDelete(BuildContext context, Dog dog) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${dog.name} silinsin mi?"),
        content: const Text("Bu işlem geri alınamaz."),
        actions: [
          TextButton(
            child: const Text("İptal"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Sil"),
            onPressed: () {
              Navigator.pop(context);
              _deleteDog(context, dog);
            },
          ),
        ],
      ),
    );
  }

  // -------------------- TAM SİLME İŞLEMİ --------------------
  Future<void> _deleteDog(BuildContext context, Dog dog) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1) Köpeği Firestore’dan sil
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dogs')
        .doc(dog.id)
        .delete();

    // 2) Storage’daki fotoğrafı sil
    if (dog.imageUrl.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(dog.imageUrl);
        await ref.delete();
      } catch (e) {
        debugPrint("Foto silinemedi: $e");
      }
    }

    // 3) Bu köpeğe ait tüm tarama geçmişini sil
    final historyQuery = await FirebaseFirestore.instance
        .collection('scan_history')
        .where('dogId', isEqualTo: dog.id)
        .get();

    for (var doc in historyQuery.docs) {
      await doc.reference.delete();
    }

    // Sayfayı kapat
    context.pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${dog.name} silindi."),
      ),
    );
  }
}
