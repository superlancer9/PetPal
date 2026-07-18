import 'package:flutter_test/flutter_test.dart';
import 'package:petpal/viewmodels/navigation_vm.dart';

void main() {
  group('NavigationVM Tests', () {
    test('NavigationVM initializes with correct default index', () {
      // Act
      final navVM = NavigationVM();

      // Assert
      expect(navVM.currentIndex, 0);
    });

    test('setCurrentIndex updates currentIndex correctly', () {
      // Arrange
      final navVM = NavigationVM();
      int? notifiedIndex;

      // Listen to changes
      navVM.addListener(() {
        notifiedIndex = navVM.currentIndex;
      });

      // Act
      navVM.setCurrentIndex(2);

      // Assert
      expect(navVM.currentIndex, 2);
      expect(notifiedIndex, 2);
    });

    test('setCurrentIndex handles multiple index changes', () {
      // Arrange
      final navVM = NavigationVM();

      // Act & Assert
      navVM.setCurrentIndex(1);
      expect(navVM.currentIndex, 1);

      navVM.setCurrentIndex(3);
      expect(navVM.currentIndex, 3);

      navVM.setCurrentIndex(0);
      expect(navVM.currentIndex, 0);

      navVM.setCurrentIndex(5);
      expect(navVM.currentIndex, 5);
    });

    test('setCurrentIndex notifies listeners on change', () {
      // Arrange
      final navVM = NavigationVM();
      int notificationCount = 0;

      navVM.addListener(() {
        notificationCount++;
      });

      // Act
      navVM.setCurrentIndex(1);
      navVM.setCurrentIndex(2);
      navVM.setCurrentIndex(3);

      // Assert
      expect(notificationCount, 3);
    });
  });
}

