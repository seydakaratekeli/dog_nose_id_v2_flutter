import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/model_warning.dart';
import '../models/dog.dart';

class LostDogListPage extends StatelessWidget {
  const LostDogListPage({super.key});

  Stream<List<Map<String, dynamic>>> _lostDogsStream() {
    return FirebaseFirestore.instance
        .collection("lost_dogs")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }

  Future<Dog?> _getDog(String dogId, String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("dogs")
        .doc(dogId)
        .get();

    if (doc.exists) {
      return Dog.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıp Köpek İhbarları")),

      body: Column(
        children: [
          const ModelWarning(),
          const SizedBox(height: 6),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _lostDogsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final lostList = snapshot.data!;

                if (lostList.isEmpty) {
                  return const Center(
                    child: Text(
                      "Herhangi bir kayıp ihbarı bulunmuyor.",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: lostList.length,
                  itemBuilder: (context, index) {
                    final item = lostList[index];

                    return FutureBuilder<Dog?>(
                      future: _getDog(item["dogId"], item["userId"]),
                      builder: (context, dogSnap) {
                        if (!dogSnap.hasData) {
                          return const SizedBox();
                        }

                        final dog = dogSnap.data!;
                        final posLat = item["lat"];
                        final posLng = item["lng"];

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundImage: dog.imageUrl.isNotEmpty
                                  ? NetworkImage(dog.imageUrl)
                                  : null,
                              child: dog.imageUrl.isEmpty
                                  ? const Icon(Icons.pets, size: 28)
                                  : null,
                            ),

                            title: Text(
                              dog.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            subtitle: Text(
                              "Irk: ${dog.breed} • Yaş: ${dog.age}\n"
                              "Konum: (${posLat.toStringAsFixed(4)}, ${posLng.toStringAsFixed(4)})",
                            ),

                            trailing: IconButton(
                              icon: const Icon(Icons.map_outlined,
                                  color: Colors.blue),
                              tooltip: "Haritada Göster",
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
