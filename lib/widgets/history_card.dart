import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 📦 EKLENDİ
import '../models/scan_history.dart';

class HistoryCard extends StatelessWidget {
  final ScanHistory history;

  const HistoryCard({super.key, required this.history});

  void _showScanDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarama Fotoğrafı
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: history.imageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 250,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 250,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Başlık
              const Row(
                children: [
                  Icon(Icons.document_scanner, color: Colors.blue, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Tarama Detayı',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Eşleşme Skoru
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      history.score > 0.8 ? Colors.green.shade50 : Colors.orange.shade50,
                      history.score > 0.8 ? Colors.green.shade100 : Colors.orange.shade100,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: history.score > 0.8 ? Colors.green : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Eşleşme Skoru:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(history.score * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: history.score > 0.8 ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Tarih
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tarih: ${_formatDate(history.timestamp)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Saat
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Saat: ${_formatTime(history.timestamp)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Sonuç Değerlendirmesi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      history.score > 0.8 ? Icons.check_circle : Icons.info,
                      color: history.score > 0.8 ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        history.score > 0.8
                            ? 'Yüksek eşleşme! Bu köpek olabilir.'
                            : history.score > 0.6
                                ? 'Orta eşleşme. Benzerlikleri var.'
                                : 'Düşük eşleşme. Benzerlik az.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Kapat Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: () => _showScanDetails(context),
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