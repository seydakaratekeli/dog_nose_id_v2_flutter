import 'package:flutter/material.dart';

class ModelWarning extends StatelessWidget {
  const ModelWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade700,
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber.shade800,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Bu özellik şu anda geçici modda çalışmaktadır.\n"
              "Derin Öğrenme modeli entegre edildiğinde gerçek biyometrik sonuçlar üretilecektir.",
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
