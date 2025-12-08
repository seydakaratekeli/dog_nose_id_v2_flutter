import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Üzgün Köpek İkonu veya Görseli
              Icon(Icons.search_off, size: 100, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              
              const Text(
                "Eşleşme Bulunamadı",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Sistemimizdeki kayıtlı köpeklerle bir eşleşme yakalayamadık.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              
              const SizedBox(height: 40),

              // 1. Seçenek: Tekrar Dene
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/scan'),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Tekrar Tara"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------
              // ⭐ YENİ SENARYO: GÖRÜLDÜ BİLDİRİMİ OLUŞTUR
              // -------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Yeni sayfaya yönlendiriyoruz (Henüz oluşturmadık)
                    context.push('/report-found'); 
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text("Bu Köpeği Gördüğünü Bildir"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Dikkat çekici renk
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Eğer bu köpeğin kayıp olduğunu düşünüyorsan, fotoğrafını ve konumunu paylaşarak sahibinin bulmasına yardım et.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}