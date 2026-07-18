import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/vets_vm.dart';
import '../../data/models/vet.dart';

/// View: Nearby Vets Screen
/// Displays Google Maps with nearby veterinarians
/// Observes VetsVM for state and forwards user actions to ViewModel
class Nearbyvets extends StatefulWidget {
  const Nearbyvets({super.key});

  @override
  State<Nearbyvets> createState() => _NearbyvetsState();
}

class _NearbyvetsState extends State<Nearbyvets> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _mapInitialized = false;
  bool _mapError = false;
  bool _hasCenteredOnLocation = false; // Track if we've already centered on location
  bool _mapReady = false; // Track if map controller is ready to use

  @override
  void initState() {
    super.initState();
    // Request location immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vetsVM = context.read<VetsVM>();
        // Get current location
        vetsVM.getCurrentLocation().then((_) {
          // Wait a bit for location to be obtained, then initialize map
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _mapInitialized = true;
              });
              // Center map on user's location once it's ready
              _centerMapOnUserLocation(vetsVM);
            }
          });
        });
      }
    });
  }

  /// Center the map on the user's current location
  void _centerMapOnUserLocation(VetsVM vetsVM, {double zoom = 13.0, bool force = false}) {
    final position = vetsVM.currentPosition;
    // Only try to move map if it's initialized and ready
    if (position != null && _mapInitialized && _mapReady && (force || !_hasCenteredOnLocation)) {
      try {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          zoom,
        );
        if (!force) {
          _hasCenteredOnLocation = true;
        }
      } catch (e) {
        debugPrint('Error centering map: $e');
        // Map might not be ready yet, wait and try again
        if (!force) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _mapReady) {
              try {
                _mapController.move(
                  LatLng(position.latitude, position.longitude),
                  zoom,
                );
                _hasCenteredOnLocation = true;
              } catch (e2) {
                debugPrint('Error centering map on retry: $e2');
              }
            }
          });
        }
      }
    } else if (position != null && _mapInitialized && !_mapReady) {
      // Map not ready yet, wait a bit and try again
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _mapReady) {
          _centerMapOnUserLocation(vetsVM, zoom: zoom, force: force);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }


  void _onMarkerTap(Vet vet) {
    _showVetDetails(vet);
  }

  void _showVetDetails(Vet vet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVetDetailsSheet(vet),
    );
  }

  Widget _buildVetDetailsSheet(Vet vet) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0056B4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Color(0xFF0056B4),
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vet.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (vet.rating != null)
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Color(0xFFFFD148), size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${vet.rating!.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  if (vet.userRatingsTotal != null) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '(${vet.userRatingsTotal} reviews)',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF697282),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (vet.address != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.location_on, size: 20, color: Color(0xFF697282)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            vet.address!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF697282),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (vet.distance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_walk, size: 16, color: Color(0xFF0056B4)),
                              const SizedBox(width: 6),
                              Text(
                                vet.distanceText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0056B4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: vet.isOpen == true
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          vet.statusText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: vet.isOpen == true
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE57373),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (vet.phoneNumber != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _callVet(vet.phoneNumber!),
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Call'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0056B4),
                              side: const BorderSide(color: Color(0xFF0056B4), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (vet.phoneNumber != null) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _getDirections(vet, context.read<VetsVM>()),
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('Show Route'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0056B4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (vet.website != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final uri = Uri.parse(vet.website!);
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.language, size: 18),
                        label: const Text('Visit Website'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0056B4),
                          side: const BorderSide(color: Color(0xFF0056B4), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _callVet(String phoneNumber) {
    final uri = Uri.parse('tel:$phoneNumber');
    launchUrl(uri);
  }

  void _getDirections(Vet vet, VetsVM vetsVM) async {
    if (vet.latitude == null || vet.longitude == null) return;
    
    // Get route and display it on the map
    await vetsVM.getRouteToVet(vet);
    
    // Center map on route (show both start and end)
    if (vetsVM.currentPosition != null && vet.latitude != null && vet.longitude != null) {
      final startLat = vetsVM.currentPosition!.latitude;
      final startLng = vetsVM.currentPosition!.longitude;
      final endLat = vet.latitude!;
      final endLng = vet.longitude!;
      
      // Calculate center point between start and end
      final centerLat = (startLat + endLat) / 2;
      final centerLng = (startLng + endLng) / 2;
      
      // Calculate zoom level to fit both points
      final latDiff = (startLat - endLat).abs();
      final lngDiff = (startLng - endLng).abs();
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
      double zoom = 13.0;
      if (maxDiff > 0.1) zoom = 11.0;
      if (maxDiff > 0.2) zoom = 10.0;
      if (maxDiff < 0.01) zoom = 15.0;
      
      if (mounted && _mapReady) {
        try {
          _mapController.move(
            LatLng(centerLat, centerLng),
            zoom,
          );
        } catch (e) {
          debugPrint('Error moving map to route: $e');
          // Wait and try again if map not ready
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _mapReady) {
              try {
                _mapController.move(
                  LatLng(centerLat, centerLng),
                  zoom,
                );
              } catch (e2) {
                debugPrint('Error moving map on retry: $e2');
              }
            }
          });
        }
      }
    }
    
    // Close the vet details sheet
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vetsVM = context.watch<VetsVM>();
    final vets = vetsVM.vets;
    final currentPosition = vetsVM.currentPosition;
    final isLoading = vetsVM.isLoading;
    final errorMessage = vetsVM.errorMessage;

    // Center map on user location when first initialized
    if (currentPosition != null && _mapInitialized && !_hasCenteredOnLocation && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMapOnUserLocation(vetsVM);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context, vetsVM),
            Expanded(
              child: Stack(
                children: [
                  // OpenStreetMap - show if initialized and position available
                  // No API key needed - completely free!
                  if (currentPosition != null && _mapInitialized && !_mapError && !isLoading)
                    _buildOpenStreetMap(currentPosition, vets)
                  else
                    _buildMapPlaceholder(context, isLoading, errorMessage),
                  
                  // Location button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            // Get fresh location
                            await vetsVM.getCurrentLocation();
                            // Wait a moment for location to update
                            await Future.delayed(const Duration(milliseconds: 300));
                            // Center map on new location (force = true to always center when button is tapped)
                            if (mounted && _mapReady) {
                              _centerMapOnUserLocation(vetsVM, zoom: 15.0, force: true);
                            } else if (mounted) {
                              // Map not ready yet, wait and try again
                              Future.delayed(const Duration(milliseconds: 500), () {
                                if (mounted && _mapReady) {
                                  _centerMapOnUserLocation(vetsVM, zoom: 15.0, force: true);
                                }
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(28),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.my_location, color: Color(0xFF4CAF50), size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Loading indicator
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
            // Vets list
            if (vets.isNotEmpty) _buildVetsList(context, vets, vetsVM),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenStreetMap(Position currentPosition, List<Vet> vets) {
    final vetsVM = context.watch<VetsVM>();
    final routePoints = vetsVM.routePoints;
    
    // Using OpenStreetMap with flutter_map (free, no API key needed)
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(currentPosition.latitude, currentPosition.longitude),
        initialZoom: 13.0,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        // OpenStreetMap tile layer (free, no API key)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.petpal',
          maxZoom: 19,
        ),
        // Route polyline (if route is active)
        if (routePoints != null && routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.0,
                color: const Color(0xFF0056B4),
                borderStrokeWidth: 2.0,
                borderColor: Colors.white,
              ),
            ],
          ),
        // Markers for veterinarians
        MarkerLayer(
          markers: _buildMarkers(vets),
        ),
        // Current location marker
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(currentPosition.latitude, currentPosition.longitude),
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.my_location, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder(BuildContext context, bool isLoading, String? errorMessage) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0056B4)),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0056B4).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map, size: 64, color: Color(0xFF0056B4)),
                ),
                const SizedBox(height: 24),
                Text(
                  errorMessage ?? 'Getting your location...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (errorMessage != null && errorMessage.contains('Billing must be enabled'))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Text(
                          'Quick Fix:\n1. Enable billing in Google Cloud Console\n2. Enable Places API\n3. Wait 2-3 minutes\n4. Click Retry\n\nNote: Free tier includes \$200/month credit',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF697282),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  )
                else if (errorMessage != null && errorMessage.contains('Places API access denied'))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const Text(
                          'To fix this:\n1. Go to Google Cloud Console\n2. Enable Places API\n3. Enable billing (required)\n4. Wait 2-3 minutes\n5. Click Retry',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF697282),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    final vetsVM = context.read<VetsVM>();
                    // Clear any previous errors
                    setState(() {
                      _mapError = false;
                    });
                    // Request location again
                    await vetsVM.getCurrentLocation();
                    // Wait a bit and then initialize map if location is obtained
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted && vetsVM.currentPosition != null) {
                        setState(() {
                          _mapInitialized = true;
                        });
                        // Center map once it's ready
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted && _mapReady) {
                            _centerMapOnUserLocation(vetsVM);
                          }
                        });
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056B4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(List<Vet> vets) {
    final markers = <Marker>[];
    
    // Add marker for each vet
    for (int i = 0; i < vets.length; i++) {
      final vet = vets[i];
      if (vet.latitude != null && vet.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(vet.latitude!, vet.longitude!),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _onMarkerTap(vet),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0056B4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return markers;
  }

  Widget _buildSearchBar(BuildContext context, VetsVM vetsVM) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search, color: Color(0xFF697282), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search veterinarians...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Color(0xFF697282),
                    fontSize: 15,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(fontSize: 15),
                onSubmitted: (query) {
                  vetsVM.searchNearbyVets(query: query.isEmpty ? null : query);
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.tune, color: Color(0xFF0056B4), size: 22),
                onPressed: () => _showFilterDialog(context, vetsVM),
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(width: 4),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF697282), size: 20),
                  onPressed: () {
                    _searchController.clear();
                    vetsVM.searchNearbyVets();
                  },
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, VetsVM vetsVM) {
    // Store initial radius to allow cancel
    final initialRadius = vetsVM.searchRadius;
    double currentRadius = initialRadius;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Search Radius'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${currentRadius.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0056B4),
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: currentRadius,
                  min: 1.0,
                  max: 20.0,
                  divisions: 19,
                  label: '${currentRadius.toStringAsFixed(1)} km',
                  onChanged: (value) {
                    setDialogState(() {
                      currentRadius = value;
                    });
                    // Update ViewModel and trigger search
                    vetsVM.setSearchRadius(value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1 km',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '20 km',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Restore original radius if cancelled
                  vetsVM.setSearchRadius(initialRadius);
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056B4),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVetsList(BuildContext context, List<Vet> vets, VetsVM vetsVM) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
        minHeight: 200,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${vets.length} Nearby Veterinarian${vets.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAllVets(context, vets),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF0056B4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: vets.length > 5 ? 5 : vets.length,
              itemBuilder: (context, index) {
                final vet = vets[index];
                return _buildVetCard(vet, vetsVM, isFullWidth: false);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildVetCard(Vet vet, VetsVM vetsVM, {bool isFullWidth = false}) {
    return GestureDetector(
      onTap: () {
        _onMarkerTap(vet);
        if (vet.latitude != null && vet.longitude != null) {
          _mapController.move(
            LatLng(vet.latitude!, vet.longitude!),
            15.0,
          );
        }
      },
      child: Container(
        width: isFullWidth ? double.infinity : 300,
        margin: EdgeInsets.only(
          right: isFullWidth ? 0 : 16,
          bottom: isFullWidth ? 12 : 0,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF2F4F6), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0056B4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Color(0xFF0056B4),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vet.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (vet.rating != null)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Color(0xFFFFD148)),
                            const SizedBox(width: 4),
                            Text(
                              '${vet.rating!.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF697282),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (vet.address != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.location_on, size: 16, color: Color(0xFF697282)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      vet.address!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF697282),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_walk, size: 14, color: Color(0xFF0056B4)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          vet.distanceText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0056B4),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: vet.isOpen == true
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vet.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: vet.isOpen == true
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE57373),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAllVets(BuildContext context, List<Vet> vets) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'All Nearby Veterinarians',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: vets.length,
                itemBuilder: (context, index) {
                  final vet = vets[index];
                  return _buildVetCard(vet, context.read<VetsVM>(), isFullWidth: true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
