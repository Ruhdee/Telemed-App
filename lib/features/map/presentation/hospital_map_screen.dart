import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/glass_panel.dart';

/// Hospital map screen matching `hospital-map/page.tsx`.
///
/// Uses flutter_map with TomTom tiles (replaces react-leaflet).
/// Shows user's location + nearby hospital markers.
class HospitalMapScreen extends StatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(18.5204, 73.8567); // Default: Pune
  LatLng? _userLocation;
  bool _isLoadingLocation = true;
  final List<_Hospital> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadNearbyHospitals();
  }

  Future<void> _getUserLocation() async {
    AppLogger.info('MAP', 'Getting user location');

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied || requested == LocationPermission.deniedForever) {
          AppLogger.warning('MAP', 'Location permission denied');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _center = _userLocation!;
        _isLoadingLocation = false;
      });

      AppLogger.info('MAP', 'Location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      AppLogger.error('MAP', 'Failed to get location', e);
      setState(() => _isLoadingLocation = false);
    }
  }

  void _loadNearbyHospitals() {
    // Mock hospital data (in production, this would come from TomTom Places API)
    _hospitals.addAll([
      _Hospital(name: 'Sassoon General Hospital', lat: 18.5195, lng: 73.8553, rating: 4.2, distance: '0.5 km'),
      _Hospital(name: 'Ruby Hall Clinic', lat: 18.5362, lng: 73.8779, rating: 4.7, distance: '1.8 km'),
      _Hospital(name: 'Jehangir Hospital', lat: 18.5285, lng: 73.8749, rating: 4.5, distance: '2.1 km'),
      _Hospital(name: 'KEM Hospital', lat: 18.4889, lng: 73.8397, rating: 4.3, distance: '3.4 km'),
    ]);
    AppLogger.info('MAP', 'Loaded ${_hospitals.length} nearby hospitals');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Map'),
        actions: [
          if (_userLocation != null)
            IconButton(
              icon: const Icon(LucideIcons.locate),
              onPressed: () {
                _mapController.move(_userLocation!, 15);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=${ApiConstants.tomtomApiKey}',
                userAgentPackageName: 'com.telemedcare.app',
              ),
              // User marker
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.my_location, color: Colors.blue, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              // Hospital markers
              MarkerLayer(
                markers: _hospitals.map((h) {
                  return Marker(
                    point: LatLng(h.lat, h.lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showHospitalSheet(h),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.local_hospital, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Hospital list (bottom sheet overlay)
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text('Nearby Hospitals', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const Spacer(),
                          Text('${_hospitals.length} found', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _hospitals.length,
                        itemBuilder: (context, index) {
                          final h = _hospitals[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _HospitalCard(
                              hospital: h,
                              onTap: () => _mapController.move(LatLng(h.lat, h.lng), 16),
                            ),
                          ).animate().fadeIn(delay: (index * 60).ms);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          if (_isLoadingLocation)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: GlassPanel(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldPrimary),
                    ),
                    const SizedBox(width: 12),
                    const Text('Getting your location...', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ).animate().fadeIn(),
            ),
        ],
      ),
    );
  }

  void _showHospitalSheet(_Hospital h) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(h.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: AppColors.goldPrimary),
                  const SizedBox(width: 4),
                  Text('${h.rating}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Icon(LucideIcons.mapPin, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(h.distance, style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(LucideIcons.navigation, size: 16),
                      label: const Text('Directions'),
                      onPressed: () {
                        AppLogger.info('MAP', 'Get directions to ${h.name}');
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.phone, size: 16),
                      label: const Text('Call'),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Hospital {
  final String name;
  final double lat;
  final double lng;
  final double rating;
  final String distance;

  const _Hospital({
    required this.name,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.distance,
  });
}

class _HospitalCard extends StatelessWidget {
  final _Hospital hospital;
  final VoidCallback onTap;

  const _HospitalCard({required this.hospital, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_hospital, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hospital.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: AppColors.goldPrimary),
                      const SizedBox(width: 4),
                      Text('${hospital.rating}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(hospital.distance, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.navigation, size: 16, color: AppColors.goldPrimary),
          ],
        ),
      ),
    );
  }
}
