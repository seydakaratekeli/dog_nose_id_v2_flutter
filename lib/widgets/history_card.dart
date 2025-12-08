import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 📦 EKLENDİ
import '../models/scan_history.dart';

class HistoryCard extends StatelessWidget {
  final ScanHistory history;

  const HistoryCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        // ⚡ CACHED IMAGE OPTİMİZASYONU
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: history.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 60, height: 60, 
              color: Colors.grey[200],
              child: const Icon(Icons.downloading, size: 20),
            ),
            errorWidget: (context, url, error) => Container(
              width: 60, height: 60, 
              color: Colors.grey[200],
              child: const Icon(Icons.error),
            ),
          ),
        ),
        title: Text("Skor: ${history.score.toStringAsFixed(3)}"),
        subtitle: Text(
          "Tarih: ${history.timestamp.toLocal()}",
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}