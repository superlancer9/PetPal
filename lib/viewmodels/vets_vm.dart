import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import '../data/models/vet.dart';

/// ViewModel for managing nearby veterinarians and map state
/// Contains all business logic for vet search, location tracking, and Places API integration
class VetsVM extends ChangeNotifier {
  // ========== STATE ==========
  List<Vet> _vets = [];
  Position? _currentPosition;
  bool _isLoading = false;
  String? _errorMessage;
  String? _searchQuery;
  double _searchRadius = 5.0; // Default 5km radius
  List<LatLng>? _routePoints; // Route polyline points
  Vet? _selectedVetForRoute; // Vet selected for directions
  
  // ========== GETTERS ==========
  List<Vet> get vets => _vets;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get searchQuery => _searchQuery;
  double get searchRadius => _searchRadius;
  List<LatLng>? get routePoints => _routePoints;
  Vet? get selectedVetForRoute => _selectedVetForRoute;
  
  // ========== OPENSTREETMAP / OVERPASS API ==========
  // Using Overpass API (free, no API key needed) to search for veterinarians
  // Alternative: Using Nominatim for geocoding (also free)
  static const String _overpassApiUrl = 'https://overpass-api.de/api/interpreter';
  static const String _nominatimApiUrl = 'https://nominatim.openstreetmap.org';
  // OSRM (Open Source Routing Machine) for directions - free, no API key needed
  static const String _osrmApiUrl = 'https://router.project-osrm.org/route/v1';
  
  VetsVM() {
    _initializeLocation();
  }
  
  // ========== LOCATION METHODS ==========
  
  /// Initialize and request location permissions
  Future<void> _initializeLocation() async {
    await requestLocationPermission();
    await getCurrentLocation();
  }
  
  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      // Check if plugin is available
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled. Please enable them.';
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permissions are denied.';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied. Please enable them in settings.';
        notifyListeners();
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error requesting location permission: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Handle MissingPluginException - plugin not linked yet
      if (e.toString().contains('MissingPluginException')) {
        _errorMessage = 'Location plugin not available. Please restart the app after installing dependencies.';
      } else {
        _errorMessage = 'Error accessing location: $e';
      }
      notifyListeners();
      return false;
    }
  }
  
  /// Get current device location
  Future<void> getCurrentLocation() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      debugPrint('📍 Current location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      
      // Automatically search for vets when location is obtained
      if (_currentPosition != null) {
        await searchNearbyVets();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting current location: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Handle MissingPluginException
      if (e.toString().contains('MissingPluginException')) {
        _errorMessage = 'Location plugin not available. Please do a full restart (not hot reload) after installing dependencies.';
      } else if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        _errorMessage = 'Location request timed out. Please try again.';
      } else if (e.toString().contains('permission')) {
        _errorMessage = 'Location permission denied. Please enable location permissions in settings.';
      } else {
        _errorMessage = 'Error getting location: $e';
      }
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ========== OVERPASS API METHODS (OpenStreetMap - Free, No API Key) ==========
  
  /// Search for nearby veterinarians using Overpass API (OpenStreetMap - free, no API key)
  Future<void> searchNearbyVets({String? query}) async {
    if (_currentPosition == null) {
      _errorMessage = 'Location not available. Please enable location services.';
      notifyListeners();
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      _searchQuery = query;
      notifyListeners();
      
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      final radius = (_searchRadius * 1000).toInt(); // Convert km to meters
      
      // Build Overpass API query to find veterinarians
      // Searching for nodes with amenity=veterinary or healthcare=veterinary
      String overpassQuery = '''
[out:json][timeout:25];
(
  node["amenity"="veterinary"](around:$radius,$lat,$lng);
  node["healthcare"="veterinary"](around:$radius,$lat,$lng);
  way["amenity"="veterinary"](around:$radius,$lat,$lng);
  way["healthcare"="veterinary"](around:$radius,$lat,$lng);
);
out center meta;
''';
      
      debugPrint('🔍 Searching for vets using Overpass API (OpenStreetMap)...');
      
      final response = await http.post(
        Uri.parse(_overpassApiUrl),
        headers: {'Content-Type': 'text/plain'},
        body: overpassQuery,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List<dynamic>? ?? [];
        debugPrint('📋 Found ${elements.length} results from Overpass API');
        
        try {
          _vets = elements.map((element) {
            try {
              return Vet.fromOverpassJson(
                element as Map<String, dynamic>,
                userLat: lat,
                userLng: lng,
              );
            } catch (e) {
              debugPrint('❌ Error parsing vet: $e');
              return null;
            }
          }).whereType<Vet>().toList();
          
          // Filter by search query if provided
          if (query != null && query.isNotEmpty) {
            final lowerQuery = query.toLowerCase();
            _vets = _vets.where((vet) {
              return vet.name.toLowerCase().contains(lowerQuery) ||
                     (vet.address?.toLowerCase().contains(lowerQuery) ?? false);
            }).toList();
          }
          
          // Sort by distance (closest first)
          _vets.sort((a, b) {
            final distA = a.distance ?? double.infinity;
            final distB = b.distance ?? double.infinity;
            return distA.compareTo(distB);
          });
          
          debugPrint('✅ Successfully parsed ${_vets.length} veterinarians');
          
          if (_vets.isEmpty) {
            _errorMessage = 'No veterinarians found in this area. Try increasing the search radius.';
          }
        } catch (e) {
          debugPrint('❌ Error processing vet results: $e');
          _errorMessage = 'Error processing results: $e';
          _vets = [];
        }
      } else {
        _errorMessage = 'Failed to search for veterinarians. Status code: ${response.statusCode}';
        debugPrint('❌ Overpass API Error: ${response.statusCode} - ${response.body}');
        _vets = [];
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error searching for vets: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (e.toString().contains('SocketException') || e.toString().contains('network')) {
        _errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        _errorMessage = 'Request timed out. Please try again.';
      } else {
        _errorMessage = 'Error searching for veterinarians: $e';
      }
      _isLoading = false;
      _vets = [];
      notifyListeners();
    }
  }
  
  /// Get detailed information about a vet using Nominatim (OpenStreetMap)
  Future<Map<String, dynamic>?> getVetDetails(String placeId) async {
    try {
      // Use Nominatim to get details by OSM ID
      final url = '$_nominatimApiUrl/lookup?osm_ids=W$placeId&format=json&addressdetails=1';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0] as Map<String, dynamic>;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting vet details: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
    return null;
  }
  
  /// Update search radius
  void setSearchRadius(double radius) {
    _searchRadius = radius;
    debugPrint('🔧 Search radius updated to: ${_searchRadius} km');
    notifyListeners();
    // Re-search with new radius
    if (_currentPosition != null) {
      debugPrint('🔄 Re-searching with new radius: ${_searchRadius} km');
      searchNearbyVets(query: _searchQuery);
    } else {
      debugPrint('⚠️ Cannot re-search: current position is null');
    }
  }
  
  /// Clear search and reset
  void clearSearch() {
    _searchQuery = null;
    _vets = [];
    notifyListeners();
  }
  
  // ========== ROUTING METHODS ==========
  
  /// Get route from current location to a vet using OSRM (free, no API key)
  Future<void> getRouteToVet(Vet vet) async {
    if (_currentPosition == null || vet.latitude == null || vet.longitude == null) {
      _errorMessage = 'Location or vet location not available';
      notifyListeners();
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      _selectedVetForRoute = vet;
      notifyListeners();
      
      final startLat = _currentPosition!.latitude;
      final startLng = _currentPosition!.longitude;
      final endLat = vet.latitude!;
      final endLng = vet.longitude!;
      
      // OSRM route API: /route/v1/{profile}/{coordinates}?overview=full&geometries=geojson
      final url = '$_osrmApiUrl/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';
      
      debugPrint('🗺️ Getting route: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          
          // Decode GeoJSON LineString coordinates
          if (geometry['type'] == 'LineString' && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List<dynamic>;
            _routePoints = coordinates.map((coord) {
              // GeoJSON format is [longitude, latitude]
              return LatLng(coord[1] as double, coord[0] as double);
            }).toList();
            
            debugPrint('✅ Route obtained: ${_routePoints!.length} points');
          } else {
            _errorMessage = 'Invalid route format';
            _routePoints = null;
          }
        } else {
          _errorMessage = 'No route found';
          _routePoints = null;
        }
      } else {
        _errorMessage = 'Failed to get route. Status: ${response.statusCode}';
        _routePoints = null;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting route: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (e.toString().contains('SocketException') || e.toString().contains('network')) {
        _errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        _errorMessage = 'Route request timed out. Please try again.';
      } else {
        _errorMessage = 'Error getting route: $e';
      }
      _routePoints = null;
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Clear the current route
  void clearRoute() {
    _routePoints = null;
    _selectedVetForRoute = null;
    notifyListeners();
  }
}

