import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart'; // Paylaşım için (opsiyonel)
import 'package:cached_network_image/cached_network_image.dart';

class FoundDogDetailPage extends StatelessWidget {
  final Map<String, dynamic> data; // Veritabanından gelen ham veri

  const FoundDogDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Verileri güvenli şekilde alalım
    final imageUrl = data['imageUrl'] ?? '';
    final breed = data['breed'] ?? 'Bilinmiyor';
    final note = data['note'] ?? '';
    final address = data['address'] ?? 'Konum yok';
    final double lat = data['lat'] ?? 0.0;
    final double lng = data['lng'] ?? 0.0;
    
    // Tarih formatlama (Basitçe string çevirimi)
    // Gerçek projede 'intl' paketi ile daha şık yapılabilir.
    final timestamp = data['timestamp'];
    String dateStr = "Tarih bilinmiyor";
    if (timestamp != null) {
      // Firebase Timestamp'i DateTime'a çevir
      DateTime date = timestamp.toDate();
      dateStr = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirim Detayı"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              if (imageUrl.isNotEmpty) {
                Share.share("Bu köpeği $address konumunda gördüm! Detaylar uygulamada.");
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. BÜYÜK FOTOĞRAF
            Hero(
              tag: imageUrl, 
              // ⚡ OPTİMİZE EDİLDİ
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 300, 
                  color: Colors.grey.shade200, 
                  child: const Center(child: CircularProgressIndicator())
                ),
                errorWidget: (context, url, error) => Container(
                  height: 300, 
                  color: Colors.grey.shade300, 
                  child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)
                ),
              ),
            ),

            // 2. BİLGİ ALANI
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık ve Etiket
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        breed,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "GÖRÜLDÜ",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  Text(dateStr, style: TextStyle(color: Colors.grey.shade600)),
                  
                  const SizedBox(height: 20),
                  
                  // Notlar
                  const Text("Açıklama:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(
                    note.isNotEmpty ? note : "Ek açıklama girilmemiş.",
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),

                  const SizedBox(height: 24),
                  
                  // 3. KONUM VE MİNİ HARİTA
                  const Text("Görüldüğü Konum:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(address, style: const TextStyle(fontSize: 15))),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Mini Harita (Google Maps)
                  // Lat/Lng 0 değilse haritayı göster
                  if (lat != 0.0 && lng != 0.0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(lat, lng),
                            zoom: 15,
                          ),
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false, // Sayfa kaydırılırken harita oynamasın
                          rotateGesturesEnabled: false,
                          markers: {
                            Marker(
                              markerId: const MarkerId("found_loc"),
                              position: LatLng(lat, lng),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                            ),
                          },
                        ),
                      ),
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