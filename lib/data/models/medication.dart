class Medication {
  final String id;
  final String petId;
  final String petName;
  final String medicationName;
  final String dosage;
  final String frequency; // e.g., "Once daily", "Twice daily", "Every 8 hours"
  final DateTime startDate;
  final DateTime? endDate;
  final String veterinarian;
  final String? notes;
  final bool isActive;

  Medication({
    required this.id,
    required this.petId,
    required this.petName,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.veterinarian,
    this.notes,
    this.isActive = true,
  });

  Medication copyWith({
    String? id,
    String? petId,
    String? petName,
    String? medicationName,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? veterinarian,
    String? notes,
    bool? isActive,
  }) {
    return Medication(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      veterinarian: veterinarian ?? this.veterinarian,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'veterinarian': veterinarian,
      'notes': notes,
      'isActive': isActive,
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      petId: json['petId'],
      petName: json['petName'],
      medicationName: json['medicationName'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      veterinarian: json['veterinarian'],
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
    );
  }

  bool get isDueForRefill {
    if (endDate == null) return false;
    final daysUntilEnd = endDate!.difference(DateTime.now()).inDays;
    return daysUntilEnd <= 7 && daysUntilEnd > 0;
  }

  bool get isExpired {
    if (endDate == null) return false;
    return endDate!.isBefore(DateTime.now());
  }
}

