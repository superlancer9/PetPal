import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/article.dart';

/// ViewModel: AdminVM
/// Manages admin article management (CRUD operations)
/// Only accessible to admin users
class AdminVM extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Article> _articles = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = false;

  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _isAdmin;

  StreamSubscription<List<Article>>? _articlesSubscription;
  StreamSubscription<User?>? _authSubscription;
  String? _lastCheckedEmail; // Track last checked email to avoid duplicate checks

  AdminVM() {
    _listenToAuthChanges();
    _listenToArticles();
    // Don't seed here - wait for admin authentication
  }

  /// Listen to auth state changes and check admin status when user changes
  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // Only check admin status when a user is logged in
        checkAdminStatus();
      } else {
        _isAdmin = false;
        notifyListeners();
      }
    });
  }

  /// Check if current user is admin (public method for external access)
  Future<void> checkAdminStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _isAdmin = false;
        notifyListeners();
        return;
      }

      // Check if user email is in admin list
      // For simplicity, we'll use a hardcoded admin email
      // In production, you'd check a Firestore collection or custom claims
      final adminEmails = [
        'admin123@gmail.com', // Primary admin email
        'admin@petpal.com', // Alternative admin email
        // Add more admin emails here
      ];

      final userEmail = user.email?.toLowerCase().trim();
      final wasAdmin = _isAdmin;
      _isAdmin = userEmail != null && adminEmails.contains(userEmail);
      
      // Only print if email changed or admin status changed to avoid spam
      if (_lastCheckedEmail != userEmail || wasAdmin != _isAdmin) {
        debugPrint('🔍 Admin check - Email: $userEmail, IsAdmin: $_isAdmin');
        _lastCheckedEmail = userEmail;
        
        // If user just became admin, ensure articles are seeded
        if (_isAdmin && !wasAdmin) {
          debugPrint('👑 Admin detected, ensuring articles are seeded...');
          _ensureDefaultArticles();
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      _isAdmin = false;
      notifyListeners();
    }
  }

  /// Listen to articles from Firestore
  void _listenToArticles() {
    _articlesSubscription?.cancel();
    
    _articlesSubscription = _firestore
        .collection('articles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Article.fromJson(doc.data(), doc.id);
      }).toList();
    }).listen(
      (articles) {
        _articles = articles;
        notifyListeners();
      },
      onError: (error, stackTrace) {
        debugPrint('❌ Error listening to articles: $error');
        debugPrint('Stack trace: $stackTrace');
        _errorMessage = 'Error loading articles: $error';
        notifyListeners();
      },
    );
  }

  /// Ensure default articles exist (seeding)
  /// Only call this when an admin user is authenticated
  Future<void> _ensureDefaultArticles() async {
    // Check if user is admin before attempting to seed
    if (!_isAdmin) {
      debugPrint('⚠️ Cannot seed articles: User is not an admin');
      return;
    }
    
    try {
      // Wait a bit for Firestore to be ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      final snapshot = await _firestore.collection('articles').get();
      
      debugPrint('📊 Current articles count: ${snapshot.docs.length}');
      
      // If no articles exist or we have less than 9, seed default articles
      if (snapshot.docs.isEmpty || snapshot.docs.length < 9) {
        debugPrint('📝 Seeding default articles... (Current count: ${snapshot.docs.length})');
        // Delete existing articles first to avoid duplicates
        if (snapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          debugPrint('🗑️ Cleared existing articles');
          // Wait a bit after deletion
          await Future.delayed(const Duration(milliseconds: 500));
        }
        await _seedDefaultArticles();
      } else {
        debugPrint('✅ Articles already exist (${snapshot.docs.length} articles)');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking for default articles: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't try to seed if there's a permission error - user might not be admin yet
      if (e.toString().contains('permission-denied')) {
        debugPrint('⚠️ Permission denied - user may not be authenticated as admin yet');
      } else {
        // For other errors, try to seed anyway
        try {
          debugPrint('📝 Attempting to seed articles despite error...');
          await _seedDefaultArticles();
        } catch (seedError) {
          debugPrint('❌ Failed to seed articles: $seedError');
        }
      }
    }
  }
  
  /// Public method to manually seed articles (for admin use)
  Future<bool> seedArticles() async {
    try {
      debugPrint('📝 Manually seeding articles...');
      await _seedDefaultArticles();
      return true;
    } catch (e) {
      debugPrint('Error seeding articles: $e');
      return false;
    }
  }

  /// Seed default articles
  Future<void> _seedDefaultArticles() async {
    try {
      debugPrint('🌱 Starting article seeding process...');
      final defaultArticles = [
      // Featured article (All category)
      {
        'title': '10 Essential Tips for New Pet Owners',
        'content': '''Welcome to pet ownership! Here are 10 essential tips to help you and your new pet get started:

1. **Create a Safe Space**: Set up a comfortable area for your pet with a bed, toys, and food/water bowls.

2. **Establish a Routine**: Pets thrive on routine. Set consistent feeding, walking, and play times.

3. **Proper Nutrition**: Consult with your veterinarian about the best diet for your pet's age, breed, and health needs.

4. **Regular Exercise**: Ensure your pet gets daily exercise appropriate for their breed and age.

5. **Veterinary Care**: Schedule regular check-ups and keep vaccinations up to date.

6. **Training and Socialization**: Start training early and expose your pet to different people, animals, and environments.

7. **Grooming**: Regular grooming keeps your pet healthy and helps you bond.

8. **Pet-Proof Your Home**: Remove hazards and ensure your home is safe for your new companion.

9. **Patience and Love**: Building a relationship takes time. Be patient and show lots of love.

10. **Emergency Preparedness**: Know the location of the nearest emergency vet and have a first aid kit ready.

Remember, every pet is unique. Take time to understand your pet's individual needs and personality!''',
        'category': 'All',
        'readTimeMinutes': 5,
        'isFeatured': true,
      },
      // Health Category - Article 1
      {
        'title': 'Understanding Your Pet\'s Behavior',
        'content': '''Understanding your pet's behavior is key to building a strong bond. Here's what you need to know:

**Body Language**: Learn to read your pet's body language. Tail position, ear position, and posture all communicate how your pet is feeling.

**Vocalizations**: Different sounds mean different things. Pay attention to the context and your pet's overall behavior.

**Common Behaviors**:
- Purring (cats): Usually indicates contentment, but can also signal stress
- Wagging tail (dogs): Not always happy - the speed and position matter
- Hiding: May indicate fear, illness, or need for alone time
- Excessive licking: Could be grooming, anxiety, or a medical issue

**When to Worry**: Sudden behavior changes often indicate health problems. Consult your veterinarian if you notice significant changes.

**Building Trust**: Consistent, positive interactions help build trust. Avoid punishment-based training methods.''',
        'category': 'Health',
        'readTimeMinutes': 8,
        'isFeatured': false,
      },
      // Health Category - Article 2
      {
        'title': 'Common Pet Health Issues',
        'content': '''Being aware of common pet health issues helps you catch problems early:

**Dental Health**:
- Regular brushing prevents periodontal disease
- Watch for bad breath, difficulty eating, or pawing at mouth
- Annual dental cleanings may be necessary

**Obesity**:
- Overweight pets face numerous health risks
- Monitor body condition score
- Regular exercise and portion control are key

**Parasites**:
- Fleas, ticks, and worms are common
- Use preventive medications year-round
- Regular check-ups help catch infestations early

**Skin Issues**:
- Allergies, infections, and parasites can cause skin problems
- Watch for excessive scratching, redness, or hair loss
- Consult your vet for persistent issues

**Ear Infections**:
- Common in dogs with floppy ears
- Signs include head shaking, odor, or discharge
- Regular cleaning helps prevent infections

**Arthritis**:
- Common in older pets
- Signs include limping, stiffness, or reluctance to move
- Weight management and joint supplements can help

**When to See a Vet**:
- Sudden behavior changes
- Loss of appetite
- Vomiting or diarrhea lasting more than 24 hours
- Difficulty breathing
- Signs of pain

Prevention is always better than treatment. Regular veterinary care and attention to your pet's behavior help catch issues early!''',
        'category': 'Health',
        'readTimeMinutes': 10,
        'isFeatured': false,
      },
      // Nutrition Category - Article 1
      {
        'title': 'Nutrition Guide for Healthy Pets',
        'content': '''Proper nutrition is fundamental to your pet's health and longevity. Here's a comprehensive guide:

**Understanding Pet Food Labels**:
- Look for AAFCO (Association of American Feed Control Officials) certification
- First ingredient should be a quality protein source
- Avoid foods with excessive fillers or artificial preservatives

**Life Stage Nutrition**:
- **Puppies/Kittens**: Need higher protein and calories for growth
- **Adults**: Balanced nutrition for maintenance
- **Seniors**: May need lower calories and joint support

**Special Dietary Needs**:
- Some pets have food allergies or sensitivities
- Prescription diets may be needed for medical conditions
- Consult your veterinarian before making major dietary changes

**Feeding Guidelines**:
- Follow package recommendations as a starting point
- Adjust based on your pet's activity level and body condition
- Regular weigh-ins help ensure proper portion control

**Treats and Supplements**:
- Treats should make up no more than 10% of daily calories
- Some supplements can be beneficial, but consult your vet first
- Avoid human foods that are toxic to pets

Remember, every pet is different. Work with your veterinarian to create the best nutrition plan for your pet!''',
        'category': 'Nutrition',
        'readTimeMinutes': 6,
        'isFeatured': false,
      },
      // Nutrition Category - Article 2
      {
        'title': 'Choosing the Right Food for Your Pet',
        'content': '''Selecting the right food for your pet can be overwhelming with so many options available. Here's how to choose:

**Consider Your Pet's Age**:
- Puppies and kittens need growth formulas with higher protein and calories
- Adult pets need maintenance formulas
- Senior pets may benefit from formulas with joint support and lower calories

**Read the Ingredients**:
- Look for named protein sources (e.g., "chicken meal" not "meat meal")
- Whole grains and vegetables provide essential nutrients
- Avoid artificial colors, flavors, and preservatives

**Wet vs. Dry Food**:
- Dry food helps maintain dental health and is more convenient
- Wet food provides hydration and may be more palatable
- Many owners use a combination of both

**Special Considerations**:
- Grain-free diets are only necessary if your pet has grain allergies
- Raw diets require careful handling and may pose health risks
- Prescription diets are available for specific medical conditions

**Transitioning Foods**:
- Gradually mix new food with old food over 7-10 days
- Watch for digestive upset or allergic reactions
- Consult your vet if your pet refuses to eat or shows signs of illness

**Portion Control**:
- Follow feeding guidelines on the package
- Adjust based on your pet's activity level and body condition
- Regular weigh-ins help ensure you're feeding the right amount

Remember, the best food is one that your pet enjoys, provides complete nutrition, and fits your budget. Consult your veterinarian for personalized recommendations!''',
        'category': 'Nutrition',
        'readTimeMinutes': 7,
        'isFeatured': false,
      },
      // Training Category - Article 1
      {
        'title': 'Exercise Routines for Active Dogs',
        'content': '''Regular exercise is crucial for your dog's physical and mental health. Here are exercise routines for active dogs:

**Daily Exercise Needs**:
- Most dogs need 30-60 minutes of exercise daily
- High-energy breeds may need 2+ hours
- Adjust based on age, breed, and health

**Types of Exercise**:
- **Walking**: Basic but essential - vary routes for mental stimulation
- **Running/Jogging**: Great for high-energy dogs (wait until fully grown)
- **Fetch**: Excellent for burning energy quickly
- **Swimming**: Low-impact exercise, great for joints
- **Agility Training**: Mental and physical workout

**Exercise Safety**:
- Avoid exercise in extreme heat
- Ensure your dog is properly hydrated
- Watch for signs of exhaustion
- Start slowly and build endurance gradually

**Mental Exercise**:
- Puzzle toys
- Training sessions
- Nose work games
- Socialization with other dogs

**Age Considerations**:
- Puppies: Short, frequent play sessions
- Adults: Regular, consistent exercise
- Seniors: Lower impact activities, shorter duration

**Signs Your Dog Needs More Exercise**:
- Destructive behavior
- Excessive barking
- Restlessness
- Weight gain

Remember, a tired dog is a happy dog! Regular exercise prevents behavioral issues and keeps your dog healthy.''',
        'category': 'Training',
        'readTimeMinutes': 5,
        'isFeatured': false,
      },
      // Training Category - Article 2
      {
        'title': 'Basic Training Tips for Your Pet',
        'content': '''Training your pet is essential for a happy, well-behaved companion. Here are fundamental training tips:

**Start Early**:
- Begin training as soon as you bring your pet home
- Puppies and kittens are most receptive between 8-16 weeks
- Older pets can still learn, but may require more patience

**Use Positive Reinforcement**:
- Reward good behavior with treats, praise, or play
- Timing is crucial - reward immediately after desired behavior
- Avoid punishment-based methods which can damage trust

**Basic Commands**:
- **Sit**: Foundation for many other commands
- **Stay**: Important for safety and control
- **Come**: Critical for recall and safety
- **Leave it**: Prevents eating dangerous items
- **Down**: Useful for calming and control

**Consistency is Key**:
- Use the same commands and hand signals
- All family members should use the same training methods
- Practice regularly in short sessions (5-15 minutes)

**House Training**:
- Establish a regular schedule for feeding and potty breaks
- Take pets outside immediately after eating, waking, and playing
- Reward successful elimination outside
- Clean accidents thoroughly to remove scent

**Socialization**:
- Expose pets to different people, animals, and environments
- Start early and make experiences positive
- Gradually increase exposure to new situations

**Common Training Mistakes**:
- Inconsistent commands
- Training when frustrated or angry
- Expecting too much too soon
- Not rewarding enough

**When to Seek Professional Help**:
- Aggressive behavior
- Severe anxiety or fear
- Persistent house training issues
- Complex behavioral problems

Remember, training is an ongoing process. Be patient, consistent, and always end training sessions on a positive note!''',
        'category': 'Training',
        'readTimeMinutes': 8,
        'isFeatured': false,
      },
      // Grooming Category - Article 1
      {
        'title': 'Grooming Tips for Long-Haired Breeds',
        'content': '''Long-haired pets require special grooming care to keep their coats healthy and beautiful:

**Daily Brushing**: Essential for preventing mats and tangles. Use the right brush for your pet's coat type.

**Bathing Schedule**: 
- Most long-haired pets need bathing every 4-6 weeks
- Use pet-specific shampoos
- Ensure thorough rinsing to prevent skin irritation

**Professional Grooming**: Regular professional grooming (every 6-8 weeks) helps maintain coat health and prevents matting.

**Common Grooming Tools**:
- Slicker brush for removing tangles
- Undercoat rake for thick coats
- Nail clippers for regular nail maintenance
- Ear cleaning solution for regular ear care

**Preventing Mats**:
- Brush daily, especially behind ears, under legs, and around the tail
- Use detangling spray for difficult areas
- Never pull on mats - cut them out carefully if needed

**Seasonal Considerations**:
- Some breeds benefit from summer trims
- Winter may require more frequent brushing
- Adjust grooming routine based on your pet's needs

Regular grooming is not just about appearance - it's essential for your pet's health and comfort!''',
        'category': 'Grooming',
        'readTimeMinutes': 7,
        'isFeatured': false,
      },
      // Grooming Category - Article 2
      {
        'title': 'Essential Grooming Practices for All Pets',
        'content': '''Regular grooming is essential for your pet's health and well-being. Here's a comprehensive guide:

**Brushing**:
- Frequency depends on coat type (daily for long-haired, weekly for short-haired)
- Removes dead hair, dirt, and distributes natural oils
- Prevents matting and reduces shedding
- Choose the right brush for your pet's coat type

**Bathing**:
- Most pets need bathing every 4-8 weeks
- Use pet-specific shampoos (human shampoo can irritate skin)
- Ensure water temperature is comfortable
- Rinse thoroughly to prevent skin irritation
- Dry completely, especially in cold weather

**Nail Trimming**:
- Trim nails every 2-4 weeks
- Use proper pet nail clippers
- Be careful not to cut the quick (blood vessel)
- If unsure, ask your vet or groomer to demonstrate

**Ear Cleaning**:
- Check ears weekly for dirt, odor, or discharge
- Use pet-specific ear cleaning solution
- Never insert anything deep into the ear canal
- Consult vet if you notice redness, swelling, or odor

**Dental Care**:
- Brush teeth daily or at least 3 times per week
- Use pet-specific toothpaste (never human toothpaste)
- Provide dental chews and toys
- Regular professional cleanings may be necessary

**Eye Care**:
- Wipe around eyes daily with a damp cloth
- Remove discharge gently
- Consult vet if you notice excessive tearing, redness, or discharge

**Benefits of Regular Grooming**:
- Early detection of skin issues, lumps, or parasites
- Prevents matting and skin infections
- Reduces shedding and allergens
- Strengthens bond between you and your pet
- Keeps your pet comfortable and healthy

**When to See a Professional**:
- Difficult matting
- Aggressive behavior during grooming
- Skin issues or infections
- Complex grooming needs

Remember, grooming is not just about appearance - it's an important part of your pet's health care routine!''',
        'category': 'Grooming',
        'readTimeMinutes': 6,
        'isFeatured': false,
      },
    ];

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (var articleData in defaultArticles) {
      final docRef = _firestore.collection('articles').doc();
      batch.set(docRef, {
        ...articleData,
        'createdAt': now,
        'updatedAt': now,
        'imageUrl': null,
      });
    }

      await batch.commit();
      debugPrint('✅ Default articles seeded successfully (${defaultArticles.length} articles)');
      
      // Verify the articles were added
      final verifySnapshot = await _firestore.collection('articles').get();
      debugPrint('✅ Verification: ${verifySnapshot.docs.length} articles now in database');
    } catch (e, stackTrace) {
      debugPrint('❌ Error seeding articles: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Create a new article
  Future<bool> createArticle({
    required String title,
    required String content,
    String? imageUrl,
    required String category,
    int readTimeMinutes = 5,
    bool isFeatured = false,
  }) async {
    if (!_isAdmin) {
      _errorMessage = 'Admin access required';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final now = DateTime.now();
      await _firestore.collection('articles').add({
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'category': category,
        'readTimeMinutes': readTimeMinutes,
        'isFeatured': isFeatured,
        'createdAt': now,
        'updatedAt': now,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating article: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = e.toString().contains('permission-denied')
          ? 'Permission denied. Please check Firestore security rules.'
          : 'Error creating article: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing article
  Future<bool> updateArticle(Article article) async {
    if (!_isAdmin) {
      _errorMessage = 'Admin access required';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore.collection('articles').doc(article.id).update({
        'title': article.title,
        'content': article.content,
        'imageUrl': article.imageUrl,
        'category': article.category,
        'readTimeMinutes': article.readTimeMinutes,
        'isFeatured': article.isFeatured,
        'updatedAt': DateTime.now(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating article: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = e.toString().contains('permission-denied')
          ? 'Permission denied. Please check Firestore security rules.'
          : 'Error updating article: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete an article
  Future<bool> deleteArticle(String articleId) async {
    if (!_isAdmin) {
      _errorMessage = 'Admin access required';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore.collection('articles').doc(articleId).delete();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting article: $e');
      _errorMessage = 'Error deleting article: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _articlesSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}

