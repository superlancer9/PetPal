class Pet {
  final String id;
  final String name;
  final String breed;
  final String type; // Dog, Cat, etc.
  final int age;
  final double weight;
  final String gender;
  final String dateOfBirth;
  final String microchipId;
  final String veterinarian;
  final int healthScore;
  final double temperature;
  final int heartRate;
  final String imageUrl; // For future use

  Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.type,
    required this.age,
    required this.weight,
    required this.gender,
    required this.dateOfBirth,
    required this.microchipId,
    required this.veterinarian,
    this.healthScore = 85,
    this.temperature = 38.5,
    this.heartRate = 80,
    this.imageUrl = '',
  });

  // Create a copy with modified fields
  Pet copyWith({
    String? id,
    String? name,
    String? breed,
    String? type,
    int? age,
    double? weight,
    String? gender,
    String? dateOfBirth,
    String? microchipId,
    String? veterinarian,
    int? healthScore,
    double? temperature,
    int? heartRate,
    String? imageUrl,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      type: type ?? this.type,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      microchipId: microchipId ?? this.microchipId,
      veterinarian: veterinarian ?? this.veterinarian,
      healthScore: healthScore ?? this.healthScore,
      temperature: temperature ?? this.temperature,
      heartRate: heartRate ?? this.heartRate,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // For JSON serialization (future use with database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'type': type,
      'age': age,
      'weight': weight,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'microchipId': microchipId,
      'veterinarian': veterinarian,
      'healthScore': healthScore,
      'temperature': temperature,
      'heartRate': heartRate,
      'imageUrl': imageUrl,
    };
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      breed: json['breed'] ?? '',
      type: json['type'] ?? '',
      age: json['age'] is int ? json['age'] : (json['age'] as num).toInt(),
      weight: json['weight'] is double ? json['weight'] : (json['weight'] as num).toDouble(),
      gender: json['gender'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      microchipId: json['microchipId'] ?? '',
      veterinarian: json['veterinarian'] ?? '',
      healthScore: json['healthScore'] is int ? (json['healthScore'] ?? 85) : ((json['healthScore'] as num?)?.toInt() ?? 85),
      temperature: json['temperature'] is double ? (json['temperature'] ?? 38.5) : ((json['temperature'] as num?)?.toDouble() ?? 38.5),
      heartRate: json['heartRate'] is int ? (json['heartRate'] ?? 80) : ((json['heartRate'] as num?)?.toInt() ?? 80),
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}

