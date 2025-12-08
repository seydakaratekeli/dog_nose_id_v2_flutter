import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 📦 EKLENDİ
import '../models/dog.dart';

class FoundDogPage extends StatelessWidget {
  final Dog dog;

  const FoundDogPage({super.key, required this.dog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Köpek Bulundu!")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 120, color: Colors.green),

            const SizedBox(height: 20),

            Text(
              "${dog.name} bulundu!",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            // ⚡ CACHED IMAGE OPTİMİZASYONU
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: dog.imageUrl,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200, width: 200,
                  color: Colors.grey.shade200,
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200, width: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.pets, size: 60, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tamam"),
            )
          ],
        ),
      ),
    );
  }
}