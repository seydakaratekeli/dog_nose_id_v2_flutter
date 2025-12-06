import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/dog.dart';

class MatchResultPage extends StatelessWidget {
  final Dog dog;                 // Eşleşen köpek
  final double score;            // Cosine similarity sonucu
  final File image;              // Kullanıcının çektiği/eklediği fotoğraf

  const MatchResultPage({
    super.key,
    required this.dog,
    required this.score,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (score * 100).clamp(0, 100).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(title: const Text("Eşleşme Sonucu")),
      body: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------
            // TARANAN FOTOĞRAF + EŞLEŞEN FOTOĞRAF
            // -----------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildImageCard("Taradığın Fotoğraf", Image.file(image)),
                _buildImageCard("Eşleşen Köpek", Image.network(dog.imageUrl)),
              ],
            ),

            const SizedBox(height: 30),

            // -----------------------------------
            // BENZERLİK YÜZDESİ
            // -----------------------------------
            Text(
              "Benzerlik Oranı",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: score.clamp(0, 1),
              minHeight: 10,
              borderRadius: BorderRadius.circular(12),
            ),

            const SizedBox(height: 8),

            Text(
              "% $percent",
              style: theme.textTheme.titleMedium,
            ),

            const SizedBox(height: 30),

            // -----------------------------------
            // EŞLEŞEN KÖPEK ÖZET BİLGİSİ
            // -----------------------------------
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),

              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(dog.imageUrl),
                      radius: 32,
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dog.name,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text("Irk: ${dog.breed}"),
                          Text("Yaş: ${dog.age}"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // -----------------------------------
            // BUTONLAR
            // -----------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text("Detayları Gör"),
                onPressed: () {
                  context.push("/dog-detail", extra: dog);
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Yeniden Tara"),
                onPressed: () {
                  context.go("/scan");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------
  // FOTOĞRAF GÖSTEREN KART
  // -----------------------------------
  Widget _buildImageCard(String title, Widget imageWidget) {
    return Expanded(
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              )),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: imageWidget,
            ),
          ),
        ],
      ),
    );
  }
}
