import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LostMapPage extends StatefulWidget {
  final String dogId; // hangi köpek kayıp işaretleniyor

  const LostMapPage({super.key, required this.dogId});

  @override
  State<LostMapPage> createState() => _LostMapPageState();
}

class _LostMapPageState extends State<LostMapPage> {
  Completer<GoogleMapController> _mapController = Completer();
  LatLng? _selectedPosition;
  bool _loading = false;

  // -------------------------
  // KONUM İZNİ VE GPS KONUMU
  // -------------------------
  Future<LatLng> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LatLng(41.015137, 28.979530); // İstanbul fallback
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return const LatLng(41.015137, 28.979530);
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    return LatLng(pos.latitude, pos.longitude);
  }

  // -------------------------
  // KONUMU KAYIP OLARAK İŞARETLE
  // -------------------------
  Future<void> _markAsLost() async {
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen haritadan bir konum seç.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection("lost_dogs").add({
        "dogId": widget.dogId,
        "userId": uid,
        "lat": _selectedPosition!.latitude,
        "lng": _selectedPosition!.longitude,
        "timestamp": DateTime.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıp konumu kaydedildi.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getCurrentLocation(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final startPos = snapshot.data as LatLng;

        return Scaffold(
          appBar: AppBar(title: const Text("Kayıp Konumu İşaretle")),

          body: Stack(
            children: [
              // -------------------------
              // GOOGLE MAPS
              // -------------------------
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: startPos,
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  if (!_mapController.isCompleted) {
                    _mapController.complete(controller);
                  }
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,

                onTap: (pos) {
                  setState(() => _selectedPosition = pos);
                },

                markers: _selectedPosition == null
                    ? {}
                    : {
                        Marker(
                          markerId: const MarkerId("selected"),
                          position: _selectedPosition!,
                        )
                      },
              ),

              // -------------------------
              // ALTTAKİ BUTON
              // -------------------------
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _markAsLost,
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ))
                      : const Text("Bu Konumu Kayıp Olarak İşaretle"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
