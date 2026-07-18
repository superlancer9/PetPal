import 'package:flutter/foundation.dart';

/// ViewModel for Navigation state
/// Manages the current tab index in bottom navigation
class NavigationVM extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}

