class Surgery {
  final String id;
  final String petId;
  final String petName;
  final String surgeryName;
  final DateTime surgeryDate;
  final String veterinarian;
  final String? clinic;
  final String? reason;
  final String? procedure;
  final String? recoveryNotes;
  final double? cost;
  final bool isCompleted;

  Surgery({
    required this.id,
    required this.petId,
    required this.petName,
    required this.surgeryName,
    required this.surgeryDate,
    required this.veterinarian,
    this.clinic,
    this.reason,
    this.procedure,
    this.recoveryNotes,
    this.cost,
    this.isCompleted = true,
  });

  Surgery copyWith({
    String? id,
    String? petId,
    String? petName,
    String? surgeryName,
    DateTime? surgeryDate,
    String? veterinarian,
    String? clinic,
    String? reason,
    String? procedure,
    String? recoveryNotes,
    double? cost,
    bool? isCompleted,
  }) {
    return Surgery(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      surgeryName: surgeryName ?? this.surgeryName,
      surgeryDate: surgeryDate ?? this.surgeryDate,
      veterinarian: veterinarian ?? this.veterinarian,
      clinic: clinic ?? this.clinic,
      reason: reason ?? this.reason,
      procedure: procedure ?? this.procedure,
      recoveryNotes: recoveryNotes ?? this.recoveryNotes,
      cost: cost ?? this.cost,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'surgeryName': surgeryName,
      'surgeryDate': surgeryDate.toIso8601String(),
      'veterinarian': veterinarian,
      'clinic': clinic,
      'reason': reason,
      'procedure': procedure,
      'recoveryNotes': recoveryNotes,
      'cost': cost,
      'isCompleted': isCompleted,
    };
  }

  factory Surgery.fromJson(Map<String, dynamic> json) {
    return Surgery(
      id: json['id'],
      petId: json['petId'],
      petName: json['petName'],
      surgeryName: json['surgeryName'],
      surgeryDate: DateTime.parse(json['surgeryDate']),
      veterinarian: json['veterinarian'],
      clinic: json['clinic'],
      reason: json['reason'],
      procedure: json['procedure'],
      recoveryNotes: json['recoveryNotes'],
      cost: json['cost']?.toDouble(),
      isCompleted: json['isCompleted'] ?? true,
    );
  }
}

