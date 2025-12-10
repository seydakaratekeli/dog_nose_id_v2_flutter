import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/dog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pati İzi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(
              "Merhaba, ${user?.email?.split('@')[0] ?? 'Misafir'}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "KAYIP İLANLARI", icon: Icon(Icons.search_off)),
            Tab(text: "GÖRÜLENLER", icon: Icon(Icons.visibility)),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 1) {
            context.push('/report-found');
          } else {
            context.push('/add-dog');
          }
        },
        icon: Icon(_tabController.index == 1 ? Icons.camera_alt : Icons.add),
        label: Text(_tabController.index == 1 ? "Görüldü Bildir" : "Köpek Ekle"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      body: TabBarView(
        controller: _tabController,
        children: const [
          // Optimize edilmiş, durumu koruyan sekmeler
          LostDogsTab(),
          FoundDogsTab(),
        ],
      ),
    );
  }
}

// =================================================================
// 1. SEKME: KAYIP LİSTESİ (Durumunu Koruyan Widget)
// =================================================================
class LostDogsTab extends StatefulWidget {
  const LostDogsTab({super.key});

  @override
  State<LostDogsTab> createState() => _LostDogsTabState();
}

class _LostDogsTabState extends State<LostDogsTab> with AutomaticKeepAliveClientMixin {
  // Bu mixin sayesinde sekme değişse bile liste yeniden yüklenmez
  @override
  bool get wantKeepAlive => true;

  // Stream'i instance variable olarak tanımla - her build'de yeniden oluşturulmaz
  late final Stream<QuerySnapshot> _lostDogsStream;

  @override
  void initState() {
    super.initState();
    _lostDogsStream = FirebaseFirestore.instance
        .collection('lost_dogs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mixin için gerekli

    return Column(
      children: [
        // Hızlı Erişim Butonları
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/scan'),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text("Hızlı Tara"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/map'),
                  icon: const Icon(Icons.map),
                  label: const Text("Harita"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _lostDogsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final docs = snapshot.data?.docs ?? [];
              
              if (docs.isEmpty) {
                return _buildEmptyState("Şu an kayıp ilanı yok.", Icons.thumb_up_alt_outlined);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: docs.length,
                addAutomaticKeepAlives: true, // Liste öğelerinin state'ini koru
                addRepaintBoundaries: true, // Repaint optimizasyonu
                cacheExtent: 500, // Ekran dışındaki öğeleri cache'le
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;
                  
                  return LostDogCard(
                    key: ValueKey(docId), // Her kart için unique key
                    data: data,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// =================================================================
// 2. SEKME: GÖRÜLENLER LİSTESİ (Durumunu Koruyan Widget)
// =================================================================
class FoundDogsTab extends StatefulWidget {
  const FoundDogsTab({super.key});

  @override
  State<FoundDogsTab> createState() => _FoundDogsTabState();
}

class _FoundDogsTabState extends State<FoundDogsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Sekme değişse de canlı tut

  // Stream'i instance variable olarak tanımla
  late final Stream<QuerySnapshot> _foundDogsStream;

  @override
  void initState() {
    super.initState();
    _foundDogsStream = FirebaseFirestore.instance
        .collection('found_dogs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mixin

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.orange.shade50,
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 8),
              const Expanded(child: Text("Sokakta sahipsiz bir köpek mi gördün?", style: TextStyle(fontSize: 12))),
              TextButton(
                onPressed: () => context.push('/report-found'),
                child: const Text("BİLDİR"),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _foundDogsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return _buildEmptyState("Henüz bildirim yapılmamış.", Icons.visibility_off_outlined);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
                cacheExtent: 500,
                itemBuilder: (context, index) {
                  final item = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;
                  
                  return FoundDogCard(
                    key: ValueKey(docId),
                    data: item,
                    index: index,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Yardımcı Fonksiyon
Widget _buildEmptyState(String message, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    ),
  );
}

// =================================================================
// KAYIP KÖPEK KARTI (State'i Korunan Widget)
// =================================================================
class LostDogCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const LostDogCard({super.key, required this.data});

  @override
  State<LostDogCard> createState() => _LostDogCardState();
}

class _LostDogCardState extends State<LostDogCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Widget'ın state'ini koru

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mixin için gerekli

    final imageUrl = widget.data['dogImage'] ?? widget.data['imageUrl'] ?? '';
    final name = widget.data['dogName'] ?? 'İsimsiz';
    final breed = widget.data['dogBreed'] ?? 'Irkı Bilinmiyor';
    final address = widget.data['address'] ?? 'Konum bilgisi yok';

    final simpleDog = Dog(
      id: widget.data['dogId'] ?? '',
      name: name,
      breed: breed,
      age: 0,
      imageUrl: imageUrl,
      embedding: [],
      ownerPhone: widget.data['ownerPhone'] ?? '',
    );

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () => context.push('/dog-detail', extra: simpleDog),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheHeight: 300, // Memory cache optimizasyonu
                      memCacheWidth: 600,
                      placeholder: (context, url) => Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.pets, color: Colors.grey, size: 50),
                      ),
                    )
                  : Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                        child: const Text("KAYIP", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(breed, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(address, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// GÖRÜLEN KÖPEK KARTI (State'i Korunan Widget)
// =================================================================
class FoundDogCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;

  const FoundDogCard({super.key, required this.data, required this.index});

  @override
  State<FoundDogCard> createState() => _FoundDogCardState();
}

class _FoundDogCardState extends State<FoundDogCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/found-dog-detail', extra: widget.data),
        child: Column(
          children: [
            Hero(
              tag: widget.data['imageUrl'] ?? 'no_img_${widget.index}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: widget.data['imageUrl'] ?? '',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  memCacheHeight: 360,
                  memCacheWidth: 600,
                  placeholder: (context, url) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.data['breed'] ?? "Irk Bilinmiyor",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                        child: const Text("GÖRÜLDÜ",
                            style: TextStyle(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(widget.data['note'] ?? "Açıklama yok",
                      style: TextStyle(color: Colors.grey[800], fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(widget.data['address'] ?? "Konum yok",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}