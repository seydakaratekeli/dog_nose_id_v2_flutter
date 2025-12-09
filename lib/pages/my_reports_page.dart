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

  // 🔍 İLAN DETAY GÖSTERME FONKSİYONU
  void _showReportDetails(Map<String, dynamic> data, bool isLost) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fotoğraf
                if ((isLost ? data['dogImage'] : data['imageUrl']) != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: isLost ? data['dogImage'] : data['imageUrl'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.pets, size: 60, color: Colors.grey),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Başlık
                Row(
                  children: [
                    Icon(
                      isLost ? Icons.warning_amber : Icons.visibility,
                      color: isLost ? Colors.red : Colors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isLost ? 'Kayıp İlanı' : 'Görülme Bildirimi',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Köpek İsmi / Irk
                _buildInfoRow(
                  Icons.pets,
                  isLost ? 'Köpek' : 'ırk',
                  isLost ? (data['dogName'] ?? 'İsimsiz') : (data['breed'] ?? 'Bilinmiyor'),
                  Colors.blue,
                ),
                
                // Irk Bilgisi (Kayıp için)
                if (isLost && data['dogBreed'] != null && data['dogBreed'].toString().isNotEmpty)
                  _buildInfoRow(
                    Icons.info_outline,
                    'ırk',
                    data['dogBreed'],
                    Colors.purple,
                  ),
                
                // Konum
                if (data['address'] != null)
                  _buildInfoRow(
                    Icons.location_on,
                    'Konum',
                    data['address'],
                    Colors.red,
                  ),
                
                // Not
                if (data['note'] != null && data['note'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.note, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Not:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(data['note']),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Telefon (Kayıp için)
                if (isLost && data['ownerPhone'] != null && data['ownerPhone'].toString().isNotEmpty)
                  _buildInfoRow(
                    Icons.phone,
                    'Telefon',
                    data['ownerPhone'],
                    Colors.green,
                  ),
                
                // Tarih
                if (data['timestamp'] != null)
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Tarih',
                    _formatTimestamp(data['timestamp']),
                    Colors.grey,
                  ),
                
                const SizedBox(height: 20),
                
                // Kapat Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLost ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'KAPAT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Bilinmiyor';
    try {
      DateTime dt;
      if (timestamp is Timestamp) {
        dt = timestamp.toDate();
      } else if (timestamp is String) {
        dt = DateTime.parse(timestamp);
      } else {
        return 'Bilinmiyor';
      }
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Bilinmiyor';
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
                onTap: () => _showReportDetails(data, isLost),
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