class VetVisit {
  final String id;
  final String petId;
  final String petName;
  final DateTime visitDate;
  final String reason; // e.g., "Annual checkup", "Sick visit", "Vaccination"
  final String? diagnosis;
  final String? treatment;
  final String veterinarian;
  final String? notes;
  final double? cost;

  VetVisit({
    required this.id,
    required this.petId,
    required this.petName,
    required this.visitDate,
    required this.reason,
    this.diagnosis,
    this.treatment,
    required this.veterinarian,
    this.notes,
    this.cost,
  });

  VetVisit copyWith({
    String? id,
    String? petId,
    String? petName,
    DateTime? visitDate,
    String? reason,
    String? diagnosis,
    String? treatment,
    String? veterinarian,
    String? notes,
    double? cost,
  }) {
    return VetVisit(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      visitDate: visitDate ?? this.visitDate,
      reason: reason ?? this.reason,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      veterinarian: veterinarian ?? this.veterinarian,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'visitDate': visitDate.toIso8601String(),
      'reason': reason,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'veterinarian': veterinarian,
      'notes': notes,
      'cost': cost,
    };
  }

  factory VetVisit.fromJson(Map<String, dynamic> json) {
    return VetVisit(
      id: json['id'],
      petId: json['petId'],
      petName: json['petName'],
      visitDate: DateTime.parse(json['visitDate']),
      reason: json['reason'],
      diagnosis: json['diagnosis'],
      treatment: json['treatment'],
      veterinarian: json['veterinarian'],
      notes: json['notes'],
      cost: json['cost']?.toDouble(),
    );
  }
}

