class LostReport {
  final String reportId;
  final String dogId;
  final String dogName;
  final String imageUrl;
  final double lat;
  final double lng;
  final DateTime timestamp;

  LostReport({
    required this.reportId,
    required this.dogId,
    required this.dogName,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'dogId': dogId,
      'dogName': dogName,
      'imageUrl': imageUrl,
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LostReport.fromMap(Map<String, dynamic> map) {
    return LostReport(
      reportId: map['reportId'],
      dogId: map['dogId'],
      dogName: map['dogName'],
      imageUrl: map['imageUrl'],
      lat: map['lat'],
      lng: map['lng'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
