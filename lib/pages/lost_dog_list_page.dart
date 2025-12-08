import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 📦 Paket import edildi
import '../models/dog.dart';

class LostDogListPage extends StatelessWidget {
  const LostDogListPage({super.key});

  Stream<List<Map<String, dynamic>>> _lostDogsStream() {
    // 'lost_dogs' koleksiyonunu dinliyoruz
    return FirebaseFirestore.instance
        .collection("lost_dogs")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }

  // Köpeğin detaylarını sahibinin profilinden çekiyoruz
  Future<Dog?> _getDog(String? dogId, String? userId) async {
    if (dogId == null || userId == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("dogs")
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
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıp Köpek İhbarları")),

      body: Column(
        children: [
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
                  return const Center(
                    child: Text(
                      "Şu an kayıp ihbarı bulunmuyor.",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: lostList.length,
                  itemBuilder: (context, index) {
                    final item = lostList[index];

                    // ID Kontrolleri
                    final ownerId = item["ownerId"] ?? item["userId"];
                    final dogId = item["dogId"];
                    
                    // Konum verilerini güvenli alalım
                    final rawLat = item["latitude"] ?? item["lat"];
                    final rawLng = item["longitude"] ?? item["lng"];
                    
                    final double lat = (rawLat is num) ? rawLat.toDouble() : 0.0;
                    final double lng = (rawLng is num) ? rawLng.toDouble() : 0.0;

                    if (ownerId == null || dogId == null) {
                      return const SizedBox();
                    }

                    return FutureBuilder<Dog?>(
                      future: _getDog(dogId, ownerId),
                      builder: (context, dogSnap) {
                        if (dogSnap.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 100, 
                            child: Center(child: LinearProgressIndicator())
                          );
                        }

                        if (!dogSnap.hasData || dogSnap.data == null) {
                          return const SizedBox();
                        }

                        final dog = dogSnap.data!;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            onTap: () {
                              context.push("/dog-detail", extra: dog);
                            },

                            // ⚡ CACHED IMAGE OPTİMİZASYONU BURADA
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: dog.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                // Yüklenirken gösterilecek (Placeholder)
                                placeholder: (context, url) => Container(
                                  width: 60, 
                                  height: 60, 
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.downloading, size: 20, color: Colors.grey),
                                ),
                                // Hata durumunda gösterilecek (Error)
                                errorWidget: (context, url, error) => Container(
                                  width: 60, 
                                  height: 60, 
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.pets, size: 30, color: Colors.grey),
                                ),
                              ),
                            ),

                            title: Text(
                              dog.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text("Irk: ${dog.breed} • Yaş: ${dog.age}"),
                                const SizedBox(height: 2),
                                Text(
                                  "Konum: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}",
                                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                ),
                              ],
                            ),

                            trailing: IconButton(
                              icon: const Icon(Icons.map_outlined, color: Colors.blue),
                              tooltip: "Konumu Gör",
                              onPressed: () {
                                context.push("/map", extra: dog.id);
                              },
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