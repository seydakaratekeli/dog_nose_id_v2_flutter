import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/dog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/scan_history.dart';
import '../widgets/history_card.dart';

class DogDetailPage extends StatefulWidget {
  final Dog dog;

  const DogDetailPage({super.key, required this.dog});

  @override
  State<DogDetailPage> createState() => _DogDetailPageState();
}

class _DogDetailPageState extends State<DogDetailPage> with AutomaticKeepAliveClientMixin {
  bool _isLost = false;
  String? _lostRecordId;
  bool _statusChecked = false; // Cache kontrolü

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!_statusChecked) {
      _checkLostStatus();
    }
  }

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
          _statusChecked = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _statusChecked = true;
        });
      }
    }
  }

  void _scanForFound() {
    context.push("/scan-for-found", extra: {
      "lostDogId": widget.dog.id,
      "lostRecordId": _lostRecordId,
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
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
              child: CachedNetworkImage(
                imageUrl: widget.dog.imageUrl,
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 260,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 260,
                  color: Colors.grey.shade300,
                  child: const Center(
                      child: Icon(Icons.pets, size: 50, color: Colors.grey)),
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
                      style:
                          const TextStyle(fontSize: 18, color: Colors.grey),
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

            // PROFESYONEL RESPONSIVE BUTONLAR
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 380;

                return isSmall
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: _buildLostButton(),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _buildFoundButton(),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildLostButton()),
                          const SizedBox(width: 14),
                          Expanded(child: _buildFoundButton()),
                        ],
                      );
              },
            ),

            const SizedBox(height: 24),

            const Text(
              "Geçmiş Taramalar",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

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
                              d.data() as Map<String, dynamic>)))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLostButton() {
    return ElevatedButton(
      onPressed: () {
        context.push("/map/report/${widget.dog.id}").then((_) 
        
        {
          _checkLostStatus();
        });
      },
      style: _primaryButtonStyle(Colors.red.shade600),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.location_off, size: 20),
          SizedBox(width: 6),
          Text("Kayıp Olarak İşaretle"),
        ],
      ),
    );
  }

  Widget _buildFoundButton() {
    return ElevatedButton(
      onPressed: _isLost ? _scanForFound : null,
      style: _primaryButtonStyle(
        _isLost ? Colors.green.shade600 : Colors.grey.shade400,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.search, size: 20),
          SizedBox(width: 6),
          Text("Bulundu mu?"),
        ],
      ),
    );
  }

  ButtonStyle _primaryButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
    );
  }
}
