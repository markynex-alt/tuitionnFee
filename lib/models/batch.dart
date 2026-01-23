class Batch {
  final String id;
  final String name;

  Batch({required this.id, required this.name});

  // ✅ Add this method to convert Batch to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Optional: create fromMap if needed
  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
