import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_vm.dart';
import '../../viewmodels/auth_vm.dart';
import '../../data/models/article.dart';
import 'admin_article_edit.dart';

/// View: Admin Articles Management Screen
/// Allows admin to view, create, edit, and delete articles
class AdminArticlesScreen extends StatelessWidget {
  const AdminArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminVM>();
    final authVM = context.watch<AuthVM>();

    // Check admin status
    if (!adminVM.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: const Center(
          child: Text('Admin access required'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Admin - Articles'),
        backgroundColor: const Color(0xFF0056B4),
        foregroundColor: Colors.white,
        actions: [
          // Logout button - make sure it's always clickable
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  // Clear any navigation routes first (e.g., if on edit article screen)
                  while (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  // Then logout - AuthWrapper will automatically show LoginScreen
                  await authVM.logout();
                } catch (e) {
                  debugPrint('Error during logout: $e');
                  // Force logout even if navigation fails
                  await authVM.logout();
                }
              },
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: adminVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : adminVM.articles.isEmpty
              ? _buildEmptyState(context)
              : _buildArticlesList(context, adminVM),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AdminArticleEditScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF0056B4),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Article',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No articles yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first article',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesList(BuildContext context, AdminVM adminVM) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: adminVM.articles.length,
      itemBuilder: (context, index) {
        final article = adminVM.articles[index];
        return _buildArticleCard(context, article, adminVM);
      },
    );
  }

  Widget _buildArticleCard(BuildContext context, Article article, AdminVM adminVM) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminArticleEditScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  if (article.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(article.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article.category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(article.category),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    article.readTimeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                article.content.length > 150
                    ? '${article.content.substring(0, 150)}...'
                    : article.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminArticleEditScreen(article: article),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0056B4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showDeleteDialog(context, article, adminVM),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return const Color(0xFFF16A8E);
      case 'nutrition':
        return const Color(0xFF0056B4);
      case 'training':
        return const Color(0xFFFFD148);
      case 'grooming':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  void _showDeleteDialog(BuildContext context, Article article, AdminVM adminVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Article'),
        content: Text('Are you sure you want to delete "${article.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await adminVM.deleteArticle(article.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Article deleted successfully' : 'Failed to delete article',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

