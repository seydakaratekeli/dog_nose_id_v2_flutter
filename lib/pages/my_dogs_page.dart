import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/dog.dart';

class MyDogsPage extends StatelessWidget {
  const MyDogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Oturum hatası: Giriş yapılmamış.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Köpeklerim")),
      
      // Sağ altta "Hızlı Köpek Ekle" butonu
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-dog'),
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        // Sadece giriş yapan kullanıcının (uid) köpeklerini dinliyoruz
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('dogs')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "Henüz kayıtlı köpeğin yok.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.push('/add-dog'),
                    child: const Text("Hemen Köpek Ekle"),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              // Veri modeline çevir
              final dog = Dog.fromMap(data);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      dog.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 60, height: 60,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.pets),
                      ),
                    ),
                  ),
                  title: Text(
                    dog.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("${dog.breed} • ${dog.age} Yaş"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Detay sayfasına git
                    context.push('/dog-detail', extra: dog);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}