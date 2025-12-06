import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/dog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Stream<List<Dog>> _dogStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dogs')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Dog.fromMap(doc.data())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Köpeklerim"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-dog'),
        icon: const Icon(Icons.add),
        label: const Text("Köpek ekle"),
      ),

      body: Column(
        children: [
          // Üst kısım: karşılama
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                CircleAvatar(
                  child: Text(
                    (user?.email ?? "U")[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Merhaba, ${user?.email ?? ""}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  tooltip: "Burun izi tara",
                  onPressed: () => context.push('/scan'),
                ),
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  tooltip: "Kayıp köpekler haritası",
                  onPressed: () => context.push('/map'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: StreamBuilder<List<Dog>>(
              stream: _dogStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Hata oluştu: ${snapshot.error}"),
                  );
                }

                final dogs = snapshot.data ?? [];

                if (dogs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Henüz kayıtlı bir köpeğin yok.\nSağ alttan 'Köpek ekle' ile başlayabilirsin.",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: dogs.length,
                  itemBuilder: (context, index) {
                    final dog = dogs[index];

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundImage: dog.imageUrl.isNotEmpty
                              ? NetworkImage(dog.imageUrl)
                              : null,
                          child: dog.imageUrl.isEmpty
                              ? const Icon(Icons.pets)
                              : null,
                        ),
                        title: Text(
                          dog.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          dog.breed.isNotEmpty
                              ? "${dog.breed} • Yaş: ${dog.age}"
                              : "Yaş: ${dog.age}",
                        ),
                        onTap: () {
                          context.push('/dog-detail', extra: dog);
                        },
                      ),
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
