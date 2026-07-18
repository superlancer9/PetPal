import 'package:flutter_test/flutter_test.dart';
import 'package:petpal/data/models/pet.dart';

void main() {
  group('Pet Health Score Tests', () {
    test('Pet model has default health score of 85', () {
      // Arrange & Act
      final pet = Pet(
        id: 'test-id',
        name: 'Test Pet',
        breed: 'Test Breed',
        type: 'Dog',
        age: 1,
        weight: 10.0,
        gender: 'Male',
        dateOfBirth: '2023-01-01',
        microchipId: 'CHIP',
        veterinarian: 'Dr. Vet',
      );

      // Assert
      expect(pet.healthScore, 85);
    });

    test('Pet model allows custom health score', () {
      // Arrange & Act
      final pet = Pet(
        id: 'test-id',
        name: 'Test Pet',
        breed: 'Test Breed',
        type: 'Dog',
        age: 1,
        weight: 10.0,
        gender: 'Male',
        dateOfBirth: '2023-01-01',
        microchipId: 'CHIP',
        veterinarian: 'Dr. Vet',
        healthScore: 95,
      );

      // Assert
      expect(pet.healthScore, 95);
    });

    test('Pet copyWith can update health score', () {
      // Arrange
      final originalPet = Pet(
        id: 'test-id',
        name: 'Test Pet',
        breed: 'Test Breed',
        type: 'Dog',
        age: 1,
        weight: 10.0,
        gender: 'Male',
        dateOfBirth: '2023-01-01',
        microchipId: 'CHIP',
        veterinarian: 'Dr. Vet',
        healthScore: 85,
      );

      // Act
      final updatedPet = originalPet.copyWith(healthScore: 90);

      // Assert
      expect(updatedPet.healthScore, 90);
      expect(originalPet.healthScore, 85); // Original unchanged
    });

    test('Pet health score is stored correctly in JSON', () {
      // Arrange
      final pet = Pet(
        id: 'test-id',
        name: 'Test Pet',
        breed: 'Test Breed',
        type: 'Dog',
        age: 1,
        weight: 10.0,
        gender: 'Male',
        dateOfBirth: '2023-01-01',
        microchipId: 'CHIP',
        veterinarian: 'Dr. Vet',
        healthScore: 88,
      );

      // Act
      final json = pet.toJson();

      // Assert
      expect(json['healthScore'], 88);
    });
  });
}

