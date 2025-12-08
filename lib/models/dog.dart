class Dog {
  final String id;
  final String name;
  final String breed;
  final int age;
  final String imageUrl;
  final List<double> embedding; 
  final String ownerPhone;

  Dog({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.imageUrl,
    required this.embedding,
    required this.ownerPhone,

  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'age': age,
      'imageUrl': imageUrl,
      'embedding': embedding,
      'ownerPhone': ownerPhone,
    };
  }

  factory Dog.fromMap(Map<String, dynamic> map) {
    return Dog(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      age: (map['age'] ?? 0) as int,
      imageUrl: map['imageUrl'] ?? '',
      embedding: List<double>.from(map['embedding'] ?? []),
      ownerPhone: map['ownerPhone'] ?? '',
    );
  }
}
