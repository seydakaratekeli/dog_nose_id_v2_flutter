class ScanHistory {
  final String id;
  final String dogId;
  final String imageUrl;
  final double score;
  final DateTime timestamp;

  ScanHistory({
    required this.id,
    required this.dogId,
    required this.imageUrl,
    required this.score,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dogId': dogId,
      'imageUrl': imageUrl,
      'score': score,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScanHistory.fromMap(Map<String, dynamic> map) {
    return ScanHistory(
      id: map['id'],
      dogId: map['dogId'],
      imageUrl: map['imageUrl'],
      score: map['score'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
