import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_vm.dart';
import '../../data/models/article.dart';

/// View: Admin Article Edit/Create Screen
/// Allows admin to create or edit articles
class AdminArticleEditScreen extends StatefulWidget {
  final Article? article; // If provided, we're editing; if null, we're creating

  const AdminArticleEditScreen({super.key, this.article});

  @override
  State<AdminArticleEditScreen> createState() => _AdminArticleEditScreenState();
}

class _AdminArticleEditScreenState extends State<AdminArticleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _readTimeController = TextEditingController();
  
  String _selectedCategory = 'All';
  bool _isFeatured = false;
  String? _imageUrl;

  final List<String> _categories = ['All', 'Health', 'Nutrition', 'Training', 'Grooming'];

  @override
  void initState() {
    super.initState();
    if (widget.article != null) {
      _titleController.text = widget.article!.title;
      _contentController.text = widget.article!.content;
      _readTimeController.text = widget.article!.readTimeMinutes.toString();
      _selectedCategory = widget.article!.category;
      _isFeatured = widget.article!.isFeatured;
      _imageUrl = widget.article!.imageUrl;
    } else {
      // Set default read time for new articles
      _readTimeController.text = '5';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _readTimeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    final adminVM = context.read<AdminVM>();
    
    // Ensure admin status is checked before saving
    await adminVM.checkAdminStatus();
    
    if (!adminVM.isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin access required. Please log in as admin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final readTime = int.tryParse(_readTimeController.text) ?? 5;

    debugPrint('💾 Saving article...');
    debugPrint('   Title: ${_titleController.text.trim()}');
    debugPrint('   Category: $_selectedCategory');
    debugPrint('   Read Time: $readTime');
    debugPrint('   Is Admin: ${adminVM.isAdmin}');

    bool success;
    try {
      if (widget.article != null) {
        // Update existing article
        debugPrint('📝 Updating existing article: ${widget.article!.id}');
        final updatedArticle = widget.article!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          readTimeMinutes: readTime,
          isFeatured: _isFeatured,
          imageUrl: _imageUrl,
          updatedAt: DateTime.now(),
        );
        success = await adminVM.updateArticle(updatedArticle);
      } else {
        // Create new article
        debugPrint('✨ Creating new article');
        success = await adminVM.createArticle(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          readTimeMinutes: readTime,
          isFeatured: _isFeatured,
          imageUrl: _imageUrl,
        );
      }

      debugPrint('✅ Save result: $success');
      if (!success) {
        debugPrint('❌ Error message: ${adminVM.errorMessage}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception during save: $e');
      debugPrint('Stack trace: $stackTrace');
      success = false;
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Wait a moment before navigating to show the success message
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adminVM.errorMessage ?? 'Failed to save article. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminVM>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(widget.article == null ? 'New Article' : 'Edit Article'),
        backgroundColor: const Color(0xFF0056B4),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: adminVM.isLoading ? null : _handleSave,
            tooltip: 'Save',
          ),
        ],
      ),
      body: adminVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter article title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Content field
                    TextFormField(
                      controller: _contentController,
                      maxLines: 15,
                      decoration: InputDecoration(
                        labelText: 'Content',
                        hintText: 'Enter article content',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter content';
                        }
                        if (value.length < 50) {
                          return 'Content must be at least 50 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Read time field
                    TextFormField(
                      controller: _readTimeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Read Time (minutes)',
                        hintText: '5',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter read time';
                        }
                        final num = int.tryParse(value);
                        if (num == null || num < 1) {
                          return 'Please enter a valid number (min 1)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Image URL field (optional)
                    TextFormField(
                      initialValue: _imageUrl,
                      decoration: InputDecoration(
                        labelText: 'Image URL (optional)',
                        hintText: 'https://example.com/image.jpg',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.image),
                      ),
                      onChanged: (value) {
                        _imageUrl = value.isEmpty ? null : value;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Featured checkbox
                    Card(
                      child: CheckboxListTile(
                        title: const Text('Featured Article'),
                        subtitle: const Text('Show this article in the featured section'),
                        value: _isFeatured,
                        onChanged: (value) {
                          setState(() {
                            _isFeatured = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF0056B4),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Save button
                    ElevatedButton(
                      onPressed: adminVM.isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056B4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Article',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

