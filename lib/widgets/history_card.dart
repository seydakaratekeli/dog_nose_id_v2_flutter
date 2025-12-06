import 'package:flutter/material.dart';
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
        leading: Image.network(
          history.imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
        title: Text("Skor: ${history.score.toStringAsFixed(3)}"),
        subtitle: Text(
          "Tarih: ${history.timestamp.toLocal()}",
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
