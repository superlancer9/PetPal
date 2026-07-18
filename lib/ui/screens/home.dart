import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'petprofile.dart';
import 'nearbyvets.dart';
import 'reminders.dart';
import 'articles.dart';
import 'health_records.dart';
import '../../viewmodels/pet_vm.dart';
import '../../viewmodels/reminder_vm.dart';
import '../../viewmodels/navigation_vm.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/articles_vm.dart';
import '../../data/models/pet.dart';
import '../../data/models/article.dart';
import 'login.dart';

/// View: Main Container
/// Only handles UI, delegates all business logic to ViewModels
class PetContainer extends StatelessWidget {
  const PetContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navVM = context.watch<NavigationVM>();

    final screens = [
      const HomeScreen(),
      const PetProfileScreen(),
      Nearbyvets(),
      TasksContainer(),
      HealthRecordsScreen(),
      Articles(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(context) as PreferredSizeWidget,
      body: screens[navVM.currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final authVM = context.watch<AuthVM>();
    final currentUser = authVM.currentUser;
    
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Text(
            'PetPal',
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // User email/name display
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User',
                style: const TextStyle(
                  color: Color(0xFF697282),
                  fontSize: 14,
                ),
              ),
            ),
          // Menu icon with sign out option
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF333333),
            ),
            onSelected: (value) {
              if (value == 'signout') {
                _handleSignOut(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFFFF5722), size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: TextStyle(color: Color(0xFFFF5722)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleSignOut(BuildContext context) async {
    try {
      // Show confirmation dialog
      final shouldSignOut = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                try {
                  Navigator.of(dialogContext).pop(false);
                } catch (e) {
                  debugPrint('❌ Error closing dialog: $e');
                }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                try {
                  Navigator.of(dialogContext).pop(true);
                } catch (e) {
                  debugPrint('❌ Error closing dialog: $e');
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF5722),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      );

      if (shouldSignOut == true && context.mounted) {
        try {
          final authVM = context.read<AuthVM>();
          await authVM.logout();
          
          // Navigate to login screen
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Error during logout: $e');
          debugPrint('Stack trace: $stackTrace');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error signing out. Please try again.')),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in sign out dialog: $e');
      debugPrint('Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home_outlined, Icons.home, 'Home', 0),
              _buildNavItem(context, Icons.pets_outlined, Icons.pets, 'Pets', 1),
              _buildNavItem(context, Icons.map_outlined, Icons.map, 'Map', 2),
              _buildNavItem(context, Icons.notifications_outlined, Icons.notifications, 'Reminders', 3),
              _buildNavItem(context, Icons.favorite_outlined, Icons.favorite, 'Health', 4),
              _buildNavItem(context, Icons.article_outlined, Icons.article, 'Articles', 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, IconData activeIcon, String label, int index) {
    final navVM = context.watch<NavigationVM>();
    final isActive = navVM.currentIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          context.read<NavigationVM>().setCurrentIndex(index);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? const Color(0xFFF16A8E) : const Color(0xFF697282),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? const Color(0xFFF16A8E) : const Color(0xFF697282),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// View: Home Screen
/// Only handles UI, delegates business logic to ViewModels
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.05;
    
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildYourPetsSection(context),
              const SizedBox(height: 24),
              _buildQuickActionsSection(context),
              const SizedBox(height: 24),
              _buildUpcomingRemindersSection(context),
              const SizedBox(height: 24),
              _buildArticlesSection(context),
              const SizedBox(height: 24),
              _buildActionButtonsSection(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello! 👋',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 28,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome to PetPal',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontFamily: 'Arimo',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYourPetsSection(BuildContext context) {
    final petVM = context.watch<PetVM>();
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              'Your Pets',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 18,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF697282)),
          ],
        ),
        SizedBox(height: screenWidth * 0.04),
        if (petVM.pets.isEmpty)
          _buildEmptyPetsPlaceholder(context)
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...petVM.pets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final pet = entry.value;
                  final colors = _getPetColors(index);
                  return Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.04),
                    child: _buildPetCard(context, pet, colors[0], colors[1]),
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }

  List<Color> _getPetColors(int index) {
    final colorSets = [
      [const Color(0xFFF16A8E), const Color(0xFFCF3F67)],
      [const Color(0xFF0056B4), const Color(0xCC0055B3)],
      [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
      [const Color(0xFFFFD148), const Color(0xFFFFC107)],
      [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
    ];
    return colorSets[index % colorSets.length];
  }

  Widget _buildEmptyPetsPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F4F6)),
      ),
      child: Column(
        children: const [
          Icon(Icons.pets, size: 48, color: Color(0xFF697282)),
          SizedBox(height: 16),
          Text(
            'No pets yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap "Add Pet" below to get started!',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF697282),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, pet, Color color1, Color color2) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.4;
    final iconSize = cardWidth * 0.4;
    final petVM = context.read<PetVM>();
    final navVM = context.read<NavigationVM>();
    
    return GestureDetector(
      onTap: () {
        petVM.selectPet(pet);
        navVM.setCurrentIndex(1);
      },
      child: Container(
        width: cardWidth.clamp(140.0, 180.0),
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: ShapeDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color1, color2],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 10,
              offset: Offset(0, 8),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize.clamp(48.0, 72.0),
              height: iconSize.clamp(48.0, 72.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets,
                color: Colors.white,
                size: iconSize.clamp(24.0, 36.0),
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            Text(
              pet.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: (screenWidth * 0.045).clamp(16.0, 20.0),
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pet.type,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: (screenWidth * 0.035).clamp(12.0, 16.0),
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${pet.age} year${pet.age != 1 ? 's' : ''} old',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: (screenWidth * 0.03).clamp(11.0, 14.0),
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navVM = context.read<NavigationVM>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: screenWidth * 0.04),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context,
                'Health Tracker',
                Icons.favorite_border,
                const Color(0xFFF16A8E),
                () {
                  navVM.setCurrentIndex(1);
                },
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: _buildQuickActionButton(
                context,
                'Vet Nearby',
                Icons.location_on_outlined,
                const Color(0xFF0056B4),
                () {
                  navVM.setCurrentIndex(2);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = (screenWidth * 0.12).clamp(60.0, 80.0);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: buttonHeight,
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: (screenWidth * 0.06).clamp(24.0, 32.0)),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: (screenWidth * 0.035).clamp(14.0, 16.0),
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingRemindersSection(BuildContext context) {
    final reminderVM = context.watch<ReminderVM>();
    final screenWidth = MediaQuery.of(context).size.width;
    final upcomingReminders = reminderVM.getUpcomingReminders(limit: 2);
    final navVM = context.read<NavigationVM>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Reminders',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 18,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                navVM.setCurrentIndex(3);
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: const Color(0xFF0056B4),
                  fontSize: (screenWidth * 0.035).clamp(12.0, 14.0),
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth * 0.03),
        if (upcomingReminders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF2F4F6)),
            ),
            child: const Center(
              child: Text(
                'No upcoming reminders',
                style: TextStyle(color: Color(0xFF697282)),
              ),
            ),
          )
        else
          ...upcomingReminders.map((reminder) {
            final color = reminder.isUrgent ? const Color(0xFFFF5722) : const Color(0xFF0056B4);
            return Padding(
              padding: EdgeInsets.only(bottom: screenWidth * 0.03),
              child: _buildReminderCard(context, reminder, color),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildReminderCard(BuildContext context, reminder, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.12).clamp(48.0, 56.0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          width: reminder.isUrgent ? 2 : 1,
          color: reminder.isUrgent ? color.withOpacity(0.3) : const Color(0xFFE5E5E5),
        ),
        boxShadow: [
          BoxShadow(
            color: reminder.isUrgent ? color.withOpacity(0.1) : const Color(0x14000000),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.alarm, color: color, size: iconSize * 0.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reminder.title,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 16,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (reminder.isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.pets, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      reminder.petName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reminder.description,
                  style: const TextStyle(
                    color: Color(0xFF697282),
                    fontSize: 14,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      reminder.getFormattedTime(),
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesSection(BuildContext context) {
    final articlesVM = context.watch<ArticlesVM>();
    final screenWidth = MediaQuery.of(context).size.width;
    final navVM = context.read<NavigationVM>();
    
    // Get featured articles first, or recent articles if no featured
    final articlesToShow = articlesVM.featuredArticles.isNotEmpty
        ? articlesVM.featuredArticles.take(2).toList()
        : articlesVM.articles.take(2).toList();
    
    if (articlesToShow.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Articles',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 18,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                navVM.setCurrentIndex(5); // Navigate to articles page
              },
              child: const Text(
                'See All',
                style: TextStyle(
                  color: Color(0xFF0056B4),
                  fontSize: 14,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth * 0.04),
        ...articlesToShow.map((article) {
          return Padding(
            padding: EdgeInsets.only(bottom: screenWidth * 0.04),
            child: _buildArticleCard(context, article, navVM),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildArticleCard(BuildContext context, Article article, NavigationVM navVM) {
    final categoryColors = {
      'All': const Color(0xFF4CAF50),
      'Health': const Color(0xFFF16A8E),
      'Nutrition': const Color(0xFF0056B4),
      'Training': const Color(0xFFFFD148),
      'Grooming': const Color(0xFF9C27B0),
    };
    final color = categoryColors[article.category] ?? const Color(0xFF0056B4);
    
    return InkWell(
      onTap: () {
        try {
          navVM.setCurrentIndex(5); // Navigate to articles page
        } catch (e, stackTrace) {
          debugPrint('❌ Error navigating to articles: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5E5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.article,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      if (article.isFeatured) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                      fontFamily: 'Arimo',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        article.readTimeText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                          fontFamily: 'Arimo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF697282)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = (screenWidth * 0.14).clamp(50.0, 60.0);
    
    return Row(
      children: [
        Expanded(
          child: Container(
            height: buttonHeight,
            decoration: ShapeDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF16A8E), Color(0xFFCF3F67)],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 10,
                  offset: Offset(0, 8),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _showAddPetDialog(context);
                },
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: Text(
                    'Add Pet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (screenWidth * 0.04).clamp(14.0, 18.0),
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddPetDialog(BuildContext context) {
    final nameController = TextEditingController();
    final breedController = TextEditingController();
    final ageController = TextEditingController();
    final weightController = TextEditingController();
    String selectedType = 'Dog';
    String selectedGender = 'Male';
    final petVM = context.read<PetVM>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Pet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Pet Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pets),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: breedController,
                  decoration: const InputDecoration(
                    labelText: 'Breed',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age (years)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: ['Male', 'Female']
                      .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedGender = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF16A8E),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please enter a pet name')),
                  );
                  return;
                }

                try {
                  final newPet = Pet(
                    id: '', // Will be set by Firestore
                    name: nameController.text.trim(),
                    breed: breedController.text.trim().isEmpty ? 'Mixed Breed' : breedController.text.trim(),
                    type: selectedType,
                    age: int.tryParse(ageController.text) ?? 1,
                    weight: double.tryParse(weightController.text) ?? 5.0,
                    gender: selectedGender,
                    dateOfBirth: DateTime.now().subtract(Duration(days: (int.tryParse(ageController.text) ?? 1) * 365)).toString().split(' ')[0],
                    microchipId: 'Not registered',
                    veterinarian: 'Not assigned',
                  );
                  
                  // Close dialog first to prevent black screen
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  
                  // Then add the pet
                  final success = await petVM.addPet(newPet);
                  
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${newPet.name} added successfully!'),
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(petVM.errorMessage ?? 'Failed to add pet'),
                          backgroundColor: const Color(0xFFFF5722),
                        ),
                      );
                    }
                  }
                } on FormatException {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid numbers for age and weight'),
                        backgroundColor: Color(0xFFFF5722),
                      ),
                    );
                  }
                } catch (e, stackTrace) {
                  debugPrint('❌ Error in add pet dialog: $e');
                  debugPrint('Stack trace: $stackTrace');
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: const Color(0xFFFF5722),
                      ),
                    );
                  }
                }
              },
              child: const Text('Add Pet'),
            ),
          ],
        ),
      ),
    );
  }
}
