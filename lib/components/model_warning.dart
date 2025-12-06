import 'package:flutter/material.dart';

class ModelWarning extends StatelessWidget {
  const ModelWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "⚠️ Bu özellik geçici olarak çalışmaktadır. "
              "Derin Öğrenme modeli entegre edildiğinde gerçek sonuçlar üretilecektir.",
              style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
