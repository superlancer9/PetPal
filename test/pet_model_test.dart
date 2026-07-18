import 'package:flutter_test/flutter_test.dart';
import 'package:petpal/data/models/pet.dart';

void main() {
  group('Pet Model Tests', () {
    test('Pet fromJson creates correct Pet object', () {
      // Arrange
      final json = {
        'id': 'test-id-123',
        'name': 'Buddy',
        'breed': 'Golden Retriever',
        'type': 'Dog',
        'age': 3,
        'weight': 25.5,
        'gender': 'Male',
        'dateOfBirth': '2021-01-15',
        'microchipId': 'CHIP123',
        'veterinarian': 'Dr. Smith',
        'healthScore': 85,
        'temperature': 38.5,
        'heartRate': 80,
        'imageUrl': '',
      };

      // Act
      final pet = Pet.fromJson(json);

      // Assert
      expect(pet.id, 'test-id-123');
      expect(pet.name, 'Buddy');
      expect(pet.breed, 'Golden Retriever');
      expect(pet.type, 'Dog');
      expect(pet.age, 3);
      expect(pet.weight, 25.5);
      expect(pet.gender, 'Male');
      expect(pet.dateOfBirth, '2021-01-15');
      expect(pet.microchipId, 'CHIP123');
      expect(pet.veterinarian, 'Dr. Smith');
      expect(pet.healthScore, 85);
      expect(pet.temperature, 38.5);
      expect(pet.heartRate, 80);
    });

    test('Pet toJson creates correct JSON map', () {
      // Arrange
      final pet = Pet(
        id: 'test-id-456',
        name: 'Luna',
        breed: 'Persian',
        type: 'Cat',
        age: 2,
        weight: 4.2,
        gender: 'Female',
        dateOfBirth: '2022-05-20',
        microchipId: 'CHIP456',
        veterinarian: 'Dr. Johnson',
        healthScore: 90,
        temperature: 38.0,
        heartRate: 120,
      );

      // Act
      final json = pet.toJson();

      // Assert
      expect(json['id'], 'test-id-456');
      expect(json['name'], 'Luna');
      expect(json['breed'], 'Persian');
      expect(json['type'], 'Cat');
      expect(json['age'], 2);
      expect(json['weight'], 4.2);
      expect(json['gender'], 'Female');
      expect(json['dateOfBirth'], '2022-05-20');
      expect(json['microchipId'], 'CHIP456');
      expect(json['veterinarian'], 'Dr. Johnson');
      expect(json['healthScore'], 90);
      expect(json['temperature'], 38.0);
      expect(json['heartRate'], 120);
    });

    test('Pet copyWith creates new Pet with updated fields', () {
      // Arrange
      final originalPet = Pet(
        id: 'test-id',
        name: 'Original',
        breed: 'Breed',
        type: 'Dog',
        age: 1,
        weight: 10.0,
        gender: 'Male',
        dateOfBirth: '2023-01-01',
        microchipId: 'CHIP',
        veterinarian: 'Dr. Vet',
      );

      // Act
      final updatedPet = originalPet.copyWith(
        name: 'Updated',
        age: 2,
        healthScore: 95,
      );

      // Assert
      expect(updatedPet.id, 'test-id'); // Unchanged
      expect(updatedPet.name, 'Updated'); // Changed
      expect(updatedPet.age, 2); // Changed
      expect(updatedPet.healthScore, 95); // Changed
      expect(updatedPet.breed, 'Breed'); // Unchanged
      expect(originalPet.name, 'Original'); // Original unchanged
    });
  });
}

