import 'dart:math' as math;

/// Data model for a veterinarian clinic
/// Used by VetsVM to store vet information from Google Places API
class Vet {
  final String id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? userRatingsTotal;
  final String? phoneNumber;
  final String? website;
  final List<String>? openingHours;
  final bool? isOpen;
  final String? placeId;
  final String? photoReference;
  final double? distance; // Distance from user in kilometers

  Vet({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.rating,
    this.userRatingsTotal,
    this.phoneNumber,
    this.website,
    this.openingHours,
    this.isOpen,
    this.placeId,
    this.photoReference,
    this.distance,
  });

  /// Create Vet from Overpass API (OpenStreetMap) JSON response
  factory Vet.fromOverpassJson(Map<String, dynamic> json, {double? userLat, double? userLng}) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};
    final name = tags['name'] as String? ?? 
                 tags['operator'] as String? ?? 
                 'Veterinary Clinic';
    
    // Get coordinates - Overpass returns different structures for nodes vs ways
    double? lat, lng;
    if (json['type'] == 'node') {
      lat = (json['lat'] as num?)?.toDouble();
      lng = (json['lon'] as num?)?.toDouble();
    } else if (json['type'] == 'way' && json['center'] != null) {
      final center = json['center'] as Map<String, dynamic>;
      lat = (center['lat'] as num?)?.toDouble();
      lng = (center['lon'] as num?)?.toDouble();
    }
    
    // Calculate distance if user location is provided
    double? distance;
    if (userLat != null && userLng != null && lat != null && lng != null) {
      distance = _calculateDistance(userLat, userLng, lat, lng);
    }
    
    // Get address from tags or construct from location
    String? address;
    if (tags['addr:full'] != null) {
      address = tags['addr:full'] as String;
    } else {
      final parts = <String>[];
      if (tags['addr:street'] != null) parts.add(tags['addr:street'] as String);
      if (tags['addr:housenumber'] != null) parts.add(tags['addr:housenumber'] as String);
      if (tags['addr:city'] != null) parts.add(tags['addr:city'] as String);
      if (parts.isNotEmpty) address = parts.join(' ');
    }
    
    // Get phone number
    final phoneNumber = tags['phone'] as String? ?? 
                       tags['contact:phone'] as String?;
    
    // Get website
    final website = tags['website'] as String? ?? 
                   tags['contact:website'] as String?;
    
    return Vet(
      id: json['id'].toString(),
      name: name,
      address: address,
      latitude: lat,
      longitude: lng,
      rating: null, // Overpass doesn't provide ratings
      userRatingsTotal: null,
      phoneNumber: phoneNumber,
      website: website,
      openingHours: null, // Would need to parse opening_hours tag
      isOpen: null,
      placeId: json['id'].toString(),
      photoReference: null,
      distance: distance,
    );
  }
  
  /// Create Vet from Google Places API JSON response (kept for backward compatibility)
  factory Vet.fromPlacesJson(Map<String, dynamic> json, {double? userLat, double? userLng}) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = location?['lat'] as double?;
    final lng = location?['lng'] as double?;
    
    // Calculate distance if user location is provided
    double? distance;
    if (userLat != null && userLng != null && lat != null && lng != null) {
      distance = _calculateDistance(userLat, userLng, lat, lng);
    }
    
    // Get first photo reference if available
    final photos = json['photos'] as List<dynamic>?;
    final photoReference = photos?.isNotEmpty == true
        ? photos![0]['photo_reference'] as String?
        : null;
    
    // Get opening hours
    final openingHours = json['opening_hours'] as Map<String, dynamic>?;
    final weekdayText = openingHours?['weekday_text'] as List<dynamic>?;
    final List<String>? hours = weekdayText?.map((e) => e.toString()).toList();
    
    return Vet(
      id: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      address: json['vicinity'] as String? ?? json['formatted_address'] as String?,
      latitude: lat,
      longitude: lng,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      phoneNumber: json['formatted_phone_number'] as String?,
      website: json['website'] as String?,
      openingHours: hours,
      isOpen: openingHours?['open_now'] as bool?,
      placeId: json['place_id'] as String?,
      photoReference: photoReference,
      distance: distance,
    );
  }

  /// Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * (3.141592653589793 / 180.0);
  
  String get distanceText {
    if (distance == null) return 'Distance unknown';
    if (distance! < 1) {
      return '${(distance! * 1000).toStringAsFixed(0)} m away';
    }
    return '${distance!.toStringAsFixed(1)} km away';
  }
  
  String get statusText {
    if (isOpen == null) return 'Hours unknown';
    if (isOpen == true) return 'Open now';
    return 'Closed';
  }
}

