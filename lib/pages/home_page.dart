import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/dog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // 1. Kayıp köpekler koleksiyonunu dinleyen Stream
  Stream<List<Map<String, dynamic>>> _lostDogsStream() {
    return FirebaseFirestore.instance
        .collection('lost_dogs')
        .orderBy('timestamp', descending: true) // En yeniden eskiye
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // 2. Köpeğin detaylarını sahibinin profilinden çeken yardımcı fonksiyon
  Future<Dog?> _getDog(String? dogId, String? ownerId) async {
    if (dogId == null || ownerId == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .collection('dogs')
          .doc(dogId)
          .get();

      if (doc.exists) {
        return Dog.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint("Köpek verisi çekilemedi: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kayıp İhbarları"), // Başlık değişti
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),

      // Kendi köpeğini eklemek isteyenler için buton kalabilir
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-dog'),
        icon: const Icon(Icons.add),
        label: const Text("Köpek Ekle"),
      ),

      body: Column(
        children: [
          // ---------------------------------------------
          // ÜST KISIM (Header: Karşılama ve Butonlar)
          // ---------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    (user?.email ?? "U")[0].toUpperCase(),
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Merhaba, ${user?.email?.split('@')[0] ?? ""}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        "Çevrendeki kayıplara göz at",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Hızlı Erişim Butonları
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  tooltip: "Burun izi tara",
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    foregroundColor: Colors.blue,
                  ),
                  onPressed: () => context.push('/scan'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  tooltip: "Kayıp haritası",
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                  ),
                  // DİKKAT: Router string beklediği için boş string gönderiyoruz
                  onPressed: () => context.push('/map', extra: ''),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // ---------------------------------------------
          // LİSTE KISMI (StreamBuilder)
          // ---------------------------------------------
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _lostDogsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Hata: ${snapshot.error}"));
                }

                final lostList = snapshot.data ?? [];

                if (lostList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                        const SizedBox(height: 16),
                        const Text(
                          "Harika! Şu an kayıp ihbarı yok.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: lostList.length,
                  itemBuilder: (context, index) {
                    final item = lostList[index];

                    // 'ownerId' veya eski kayıtlarda 'userId' olabilir
                    final ownerId = item["ownerId"] ?? item["userId"];
                    final dogId = item["dogId"];
                    
                    // Veri eksikse gösterme
                    if (ownerId == null || dogId == null) return const SizedBox();

                    return FutureBuilder<Dog?>(
                      future: _getDog(dogId, ownerId),
                      builder: (context, dogSnap) {
                        // Veri yüklenirken placeholder (iskelet) göster
                        if (dogSnap.connectionState == ConnectionState.waiting) {
                          return const Card(
                            child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                          );
                        }

                        // Köpek verisi silinmişse gösterme
                        if (!dogSnap.hasData || dogSnap.data == null) {
                          return const SizedBox();
                        }

                        final dog = dogSnap.data!;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.red.shade100, width: 1), // Kırmızı çerçeve
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              // Detay sayfasına git
                              context.push('/dog-detail', extra: dog);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  // FOTOĞRAF
                                  Hero(
                                    tag: dog.id,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        dog.imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          width: 70, height: 70,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.pets, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // BİLGİLER
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              dog.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                "KAYIP",
                                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${dog.breed} • ${dog.age} Yaşında",
                                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                "Konumu görmek için tıkla",
                                                style: TextStyle(color: Colors.blue[600], fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}