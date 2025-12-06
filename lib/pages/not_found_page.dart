import 'package:flutter/material.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Eşleşme Yok")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel,
                size: 120, color: Colors.red),

            const SizedBox(height: 20),

            const Text(
              "Maalesef eşleşme bulunamadı.",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tekrar dene"),
            )
          ],
        ),
      ),
    );
  }
}
