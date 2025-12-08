import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LostMapPage extends StatefulWidget {
  final String dogId; 

  const LostMapPage({super.key, required this.dogId});

  @override
  State<LostMapPage> createState() => _LostMapPageState();
}

class _LostMapPageState extends State<LostMapPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _noteController = TextEditingController();

  LatLng? _currentCenterPosition; 
  String? _currentAddress; 
  bool _loading = false;
  MapType _currentMapType = MapType.normal;
  
  Set<Marker> _otherLostDogMarkers = {}; 
  
  late Future<LatLng> _initialLocationFuture;

  @override
  void initState() {
    super.initState();
    _initialLocationFuture = _getCurrentLocation();

    if (widget.dogId.isEmpty) {
      _loadOtherLostDogs();
    }
  }

  Future<void> _loadOtherLostDogs() async {
    final snapshot = await FirebaseFirestore.instance.collection('lost_dogs').get();
    final markers = snapshot.docs.map((doc) {
      final data = doc.data();
      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(data['lat'], data['lng']),
        infoWindow: InfoWindow(
          title: data['dogName'] ?? 'Kayıp Köpek',
          snippet: data['address'] ?? data['note'] ?? '', 
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
    }).toSet();

    if (mounted) {
      setState(() {
        _otherLostDogMarkers = markers;
      });
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return const LatLng(41.0082, 28.9784);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      return const LatLng(41.0082, 28.9784);
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return LatLng(pos.latitude, pos.longitude);
  }

  Future<void> _getAddressFromLatLng() async {
    if (_currentCenterPosition == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentCenterPosition!.latitude,
        _currentCenterPosition!.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _currentAddress = "${place.thoroughfare ?? ''} ${place.subLocality ?? ''}, ${place.subAdministrativeArea ?? ''}";
          });
        }
      }
    } catch (e) {
      debugPrint("Adres hatası: $e");
      if (mounted) {
        setState(() {
          _currentAddress = "Adres bulunamadı (${_currentCenterPosition!.latitude.toStringAsFixed(4)}, ${_currentCenterPosition!.longitude.toStringAsFixed(4)})";
        });
      }
    }
  }

  Future<void> _saveLocationAndReport() async {
    if (_currentCenterPosition == null || widget.dogId.isEmpty) return;

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final dogDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dogs')
          .doc(widget.dogId)
          .get();

      if (!dogDoc.exists) throw Exception("Köpek profili bulunamadı!");
      final dogData = dogDoc.data()!;
      
      await FirebaseFirestore.instance.collection("lost_dogs").add({
        "dogId": widget.dogId,
        "userId": uid,
        "dogName": dogData['name'] ?? 'İsimsiz',
        "dogBreed": dogData['breed'] ?? '',
        "dogImage": dogData['imageUrl'] ?? '',
        "ownerPhone": dogData['ownerPhone'] ?? '', 
        "lat": _currentCenterPosition!.latitude,
        "lng": _currentCenterPosition!.longitude,
        "address": _currentAddress ?? "Adres alınamadı",
        "timestamp": FieldValue.serverTimestamp(),
        "note": _noteController.text.trim(),
        "status": "lost",
        "found": false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıp ilanı ve konum yayınlandı!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isReportMode = widget.dogId.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false, 
      appBar: AppBar(
        title: Text(isReportMode ? "Konumu Seçin" : "Kayıp Haritası"),
        actions: [
          IconButton(
            icon: Icon(_currentMapType == MapType.normal ? Icons.satellite_alt : Icons.map),
            onPressed: () => setState(() => _currentMapType = _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal),
          ),
        ],
      ),
      body: FutureBuilder<LatLng>(
        future: _initialLocationFuture, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final initialPos = snapshot.data ?? const LatLng(41.0082, 28.9784);
          
          if (_currentCenterPosition == null) {
            _currentCenterPosition = initialPos;
            if (isReportMode) {
               Future.microtask(() => _getAddressFromLatLng());
            }
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: initialPos, zoom: 15),
                mapType: _currentMapType,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                markers: isReportMode ? {} : _otherLostDogMarkers, 
                
                // ⚡ DÜZELTİLEN KISIM
                onMapCreated: (controller) {
                  if (!_mapController.isCompleted) {
                    _mapController.complete(controller);
                  }
                },
                
                onCameraMove: (pos) {
                  _currentCenterPosition = pos.target;
                },
                
                onCameraIdle: () {
                  if (isReportMode) {
                    _getAddressFromLatLng();
                  }
                },
              ),

              if (isReportMode)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40.0),
                    child: Icon(Icons.location_on, size: 50, color: Colors.red),
                  ),
                ),

              if (isReportMode)
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text("Konum Detayı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              const Icon(Icons.map, color: Colors.blueGrey, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentAddress ?? "Konum belirleniyor...",
                                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          const Divider(height: 24),
                          
                          const Text("Ek Açıklama", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              hintText: "Örn: Tasması kırmızı, parkın girişinde...",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.all(12),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _saveLocationAndReport,
                            icon: const Icon(Icons.campaign, color: Colors.white),
                            label: _loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("KAYIP İLANI OLUŞTUR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}