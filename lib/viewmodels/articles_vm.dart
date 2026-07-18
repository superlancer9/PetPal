import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/article.dart';

/// ViewModel: ArticlesVM
/// Manages article data for client-side viewing
/// Read-only access to articles from Firestore
class ArticlesVM extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Article> _articles = [];
  String? _selectedCategory = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  List<Article> get articles {
    if (_selectedCategory == 'All') {
      return _articles;
    }
    return _articles.where((article) => article.category == _selectedCategory).toList();
  }

  List<Article> get featuredArticles {
    return _articles.where((article) => article.isFeatured).toList();
  }

  String? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSubscription<List<Article>>? _articlesSubscription;

  ArticlesVM() {
    _listenToArticles();
  }

  /// Listen to articles from Firestore
  void _listenToArticles() {
    try {
      _articlesSubscription?.cancel();
      
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      _articlesSubscription = _firestore
          .collection('articles')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        try {
          return snapshot.docs.map((doc) {
            try {
              return Article.fromJson(doc.data(), doc.id);
            } catch (e, stackTrace) {
              debugPrint('❌ Error parsing article ${doc.id}: $e');
              debugPrint('Stack trace: $stackTrace');
              rethrow;
            }
          }).toList();
        } catch (e, stackTrace) {
          debugPrint('❌ Error processing articles snapshot: $e');
          debugPrint('Stack trace: $stackTrace');
          rethrow;
        }
      }).listen(
        (articles) {
          try {
            _articles = articles;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          } catch (e, stackTrace) {
            debugPrint('❌ Error updating articles state: $e');
            debugPrint('Stack trace: $stackTrace');
            _isLoading = false;
            _errorMessage = 'Error updating articles: $e';
            notifyListeners();
          }
        },
        onError: (error, stackTrace) {
          debugPrint('❌ Error listening to articles: $error');
          debugPrint('Stack trace: $stackTrace');
          _errorMessage = 'Error loading articles: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error setting up articles listener: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = 'Failed to load articles: $e';
      notifyListeners();
    }
  }

  /// Set selected category filter
  void setCategory(String? category) {
    _selectedCategory = category ?? 'All';
    notifyListeners();
  }

  @override
  void dispose() {
    _articlesSubscription?.cancel();
    super.dispose();
  }
}

