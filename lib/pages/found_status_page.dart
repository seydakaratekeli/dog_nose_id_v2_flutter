import 'package:flutter/material.dart';
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
            const Icon(Icons.check_circle,
                size: 120, color: Colors.green),

            const SizedBox(height: 20),

            Text(
              "${dog.name} bulundu!",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                dog.imageUrl,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
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
