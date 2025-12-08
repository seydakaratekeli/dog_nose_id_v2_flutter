import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:cached_network_image/cached_network_image.dart';
import '../models/dog.dart';

class MatchResultPage extends StatelessWidget {
  final Dog dog;
  final double score;
  final File image;

  const MatchResultPage({
    super.key,
    required this.dog,
    required this.score,
    required this.image,
  });

  //  ARAMA YAPMA FONKSİYONU
  Future<void> _callOwner(BuildContext context, String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bu köpeğin sahibine ait telefon kaydı yok.")),
      );
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Simülatörde arama yapılamaz uyarısı
      debugPrint("Arama başlatılamadı (Simülatörde olabilir).");
    }
  }

  //  WHATSAPP MESAJ FONKSİYONU
  Future<void> _messageOwner(BuildContext context, String phone, String dogName) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Telefon numarası bulunamadı.")),
      );
      return;
    }
    
    // Telefon numarasını temizle (boşluk vs varsa)
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), ''); 
    // Türkiye kodu ekle (eğer başında yoksa) - Opsiyonel
    if (!cleanPhone.startsWith('90')) {
       cleanPhone = '90$cleanPhone';
    }

    final message = "Merhaba, uygulamanız üzerinden $dogName isimli köpeğinizle eşleşen bir köpek buldum.";
    final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("WhatsApp açılamadı.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (score * 100).clamp(0, 100).toStringAsFixed(1);
    
    // Test için numara yoksa varsayılan gösterelim (Geliştirme aşamasında kolaylık)
    final displayPhone = dog.ownerPhone.isNotEmpty ? dog.ownerPhone : "05550000000"; 

    return Scaffold(
      appBar: AppBar(title: const Text("Eşleşme Sonucu")),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTOĞRAFLAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildImageCard("Taradığın", Image.file(image)),
                // YENİ: CachedNetworkImage ile sarmalanmış widget gönderiyoruz
                _buildImageCard("Eşleşen", CachedNetworkImage(
                  imageUrl: dog.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (c, u, e) => const Icon(Icons.error),
                )),
              ],
            ),

            const SizedBox(height: 20),

            // BENZERLİK ORANI
            Center(
              child: Column(
                children: [
                  Text(
                    "Benzerlik Oranı: %$percent",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: score.clamp(0, 1),
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(12),
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // KÖPEK BİLGİ KARTI
            Card(
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      // YENİ: CachedNetworkImageProvider
                      backgroundImage: CachedNetworkImageProvider(dog.imageUrl),
                      radius: 36,
                      // Hata durumunu CircleAvatar'da yönetmek zordur, 
                      // ama cache provider işinizi görür.
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dog.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text("${dog.breed} • ${dog.age} Yaş", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // --- İLETİŞİM BUTONLARI ---
            const Text("Sahibiyle İletişime Geç", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.call),
                    label: const Text("Ara"),
                    onPressed: () => _callOwner(context, displayPhone),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp Yeşili
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.message), // Chat ikonu
                    label: const Text("WhatsApp"),
                    onPressed: () => _messageOwner(context, displayPhone, dog.name),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // DİĞER BUTONLAR
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push("/dog-detail", extra: dog),
                child: const Text("Detaylı Profil"),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Yeniden Tara"),
                onPressed: () => context.go("/scan"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String title, Widget imageWidget) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: FittedBox(fit: BoxFit.cover, child: imageWidget),
            ),
          ),
        ],
      ),
    );
  }
}