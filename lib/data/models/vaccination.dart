class Vaccination {
  final String id;
  final String petId;
  final String petName;
  final String vaccineName;
  final DateTime dateGiven;
  final DateTime? dueDate;
  final String veterinarian;
  final String? batchNumber;
  final String? notes;
  final bool isCompleted;

  Vaccination({
    required this.id,
    required this.petId,
    required this.petName,
    required this.vaccineName,
    required this.dateGiven,
    this.dueDate,
    required this.veterinarian,
    this.batchNumber,
    this.notes,
    this.isCompleted = true,
  });

  Vaccination copyWith({
    String? id,
    String? petId,
    String? petName,
    String? vaccineName,
    DateTime? dateGiven,
    DateTime? dueDate,
    String? veterinarian,
    String? batchNumber,
    String? notes,
    bool? isCompleted,
  }) {
    return Vaccination(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      vaccineName: vaccineName ?? this.vaccineName,
      dateGiven: dateGiven ?? this.dateGiven,
      dueDate: dueDate ?? this.dueDate,
      veterinarian: veterinarian ?? this.veterinarian,
      batchNumber: batchNumber ?? this.batchNumber,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool get isDue {
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now().add(const Duration(days: 30)));
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  String getStatus() {
    if (isOverdue) return 'Overdue';
    if (isDue) return 'Due Soon';
    return 'Up to Date';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'vaccineName': vaccineName,
      'dateGiven': dateGiven.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'veterinarian': veterinarian,
      'batchNumber': batchNumber,
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  factory Vaccination.fromJson(Map<String, dynamic> json) {
    return Vaccination(
      id: json['id'],
      petId: json['petId'],
      petName: json['petName'],
      vaccineName: json['vaccineName'],
      dateGiven: DateTime.parse(json['dateGiven']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      veterinarian: json['veterinarian'],
      batchNumber: json['batchNumber'],
      notes: json['notes'],
      isCompleted: json['isCompleted'] ?? true,
    );
  }
}

