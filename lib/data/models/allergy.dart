import 'package:flutter/material.dart';

class Allergy {
  final String id;
  final String petId;
  final String petName;
  final String allergen; // e.g., "Chicken", "Pollen", "Flea bites"
  final String severity; // "Mild", "Moderate", "Severe"
  final String? symptoms;
  final String? treatment;
  final DateTime? diagnosedDate;
  final String veterinarian;
  final String? notes;

  Allergy({
    required this.id,
    required this.petId,
    required this.petName,
    required this.allergen,
    required this.severity,
    this.symptoms,
    this.treatment,
    this.diagnosedDate,
    required this.veterinarian,
    this.notes,
  });

  Allergy copyWith({
    String? id,
    String? petId,
    String? petName,
    String? allergen,
    String? severity,
    String? symptoms,
    String? treatment,
    DateTime? diagnosedDate,
    String? veterinarian,
    String? notes,
  }) {
    return Allergy(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      allergen: allergen ?? this.allergen,
      severity: severity ?? this.severity,
      symptoms: symptoms ?? this.symptoms,
      treatment: treatment ?? this.treatment,
      diagnosedDate: diagnosedDate ?? this.diagnosedDate,
      veterinarian: veterinarian ?? this.veterinarian,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'allergen': allergen,
      'severity': severity,
      'symptoms': symptoms,
      'treatment': treatment,
      'diagnosedDate': diagnosedDate?.toIso8601String(),
      'veterinarian': veterinarian,
      'notes': notes,
    };
  }

  factory Allergy.fromJson(Map<String, dynamic> json) {
    return Allergy(
      id: json['id'],
      petId: json['petId'],
      petName: json['petName'],
      allergen: json['allergen'],
      severity: json['severity'],
      symptoms: json['symptoms'],
      treatment: json['treatment'],
      diagnosedDate: json['diagnosedDate'] != null ? DateTime.parse(json['diagnosedDate']) : null,
      veterinarian: json['veterinarian'],
      notes: json['notes'],
    );
  }

  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'severe':
        return const Color(0xFFFF5722);
      case 'moderate':
        return const Color(0xFFFFD148);
      default:
        return const Color(0xFF4CAF50);
    }
  }
}

