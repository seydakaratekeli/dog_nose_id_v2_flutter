import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/lost_report.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportLostDogDialog extends StatefulWidget {
  @override
  _ReportLostDogDialogState createState() => _ReportLostDogDialogState();
}

class _ReportLostDogDialogState extends State<ReportLostDogDialog> {
  bool _loading = false;

  Future<void> _reportLostDog() async {
    setState(() => _loading = true);

    // 1. Konum al
    final position = await Geolocator.getCurrentPosition();

    // 2. Kullanıcı köpeklerinden seçmesini isteyebiliriz
    // Şimdilik otomatik olarak ilk köpeği alıyoruz (istersen seçim ekranı ekleyebilirim)

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final dogQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dogs')
        .get();

    if (dogQuery.docs.isEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hiç köpek kaydın yok")),
      );
      return;
    }

    final dog = dogQuery.docs.first.data();
    final dogId = dog['id'];

    final reportId = FirebaseFirestore.instance.collection('lost_reports').doc().id;

    final report = LostReport(
      reportId: reportId,
      dogId: dogId,
      dogName: dog['name'],
      imageUrl: dog['imageUrl'],
      lat: position.latitude,
      lng: position.longitude,
      timestamp: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('lost_reports')
        .doc(reportId)
        .set(report.toMap());

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Kayıp köpek ilanı oluşturuldu")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Köpeğimi Kaybettim"),
      content: Text("Son görüldüğü konuma göre ilan oluşturulacak."),
      actions: [
        TextButton(
          child: Text("İptal"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _reportLostDog,
          child: _loading
              ? CircularProgressIndicator()
              : Text("Oluştur"),
        ),
      ],
    );
  }
}
