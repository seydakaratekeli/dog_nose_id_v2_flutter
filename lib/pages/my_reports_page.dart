import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // 🔥 İLAN SİLME FONKSİYONU
  Future<void> _deleteReport(String collection, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("İlanı Sil"),
        content: const Text("Bu ilanı yayından kaldırmak istediğine emin misin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İlan silindi.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const Scaffold(body: Center(child: Text("Giriş yapmalısınız.")));

    return Scaffold(
      appBar: AppBar(
        title: const Text("İlanlarım & Bildirimlerim"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Kayıp İlanlarım"),
            Tab(text: "Gördüklerim"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. SEKME: BENİM KAYIP İLANLARIM
          _buildMyList(
            collection: 'lost_dogs',
            queryField: 'userId', // Lost dog modelinde userId kaydediyoruz
            emptyMsg: "Henüz kayıp ilanı vermediniz.",
            isLost: true,
          ),

          // 2. SEKME: BENİM GÖRDÜĞÜM KÖPEKLER
          _buildMyList(
            collection: 'found_dogs',
            queryField: 'reporterId', // Report found modelinde reporterId var
            emptyMsg: "Henüz bir buluntu bildirimi yapmadınız.",
            isLost: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMyList({required String collection, required String queryField, required String emptyMsg, required bool isLost}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where(queryField, isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            
            // Veri modeline göre alan isimleri
            final image = isLost ? (data['dogImage'] ?? '') : (data['imageUrl'] ?? '');
            final title = isLost ? (data['dogName'] ?? 'İsimsiz') : (data['breed'] ?? 'Irk Bilinmiyor');
            final sub = data['note'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                // ⚡ OPTİMİZE EDİLDİ
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: image,
                    width: 50, 
                    height: 50, 
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.downloading, size: 16)),
                    errorWidget: (c, u, e) => Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
                  ),
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteReport(collection, docId),
                  tooltip: "İlanı Kaldır",
                ),
              ),
            );
          },
        );
      },
    );
  }
}