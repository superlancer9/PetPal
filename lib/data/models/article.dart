/// Data model for articles
/// Used by AdminVM and Articles screen
class Article {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int readTimeMinutes; // Estimated reading time
  final bool isFeatured; // Whether this article is featured

  Article({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.readTimeMinutes = 5,
    this.isFeatured = false,
  });

  /// Create Article from Firestore document
  factory Article.fromJson(Map<String, dynamic> json, String id) {
    return Article(
      id: id,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String? ?? 'All',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
      readTimeMinutes: json['readTimeMinutes'] as int? ?? 5,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }

  /// Convert Article to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'readTimeMinutes': readTimeMinutes,
      'isFeatured': isFeatured,
    };
  }

  /// Create a copy with updated fields
  Article copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? readTimeMinutes,
    bool? isFeatured,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  String get readTimeText {
    return '$readTimeMinutes min read';
  }
}

