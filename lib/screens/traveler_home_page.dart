import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/supabase_service.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';
import '../services/notification_service.dart';
import '../services/distance_service.dart';
import '../services/wallet_service.dart';
import 'activity_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';

class TravelerHomePage extends StatefulWidget {
  final bool embedded;

  const TravelerHomePage({super.key, this.embedded = false});

  @override
  State<TravelerHomePage> createState() => _TravelerHomePageState();
}

class _TravelerHomePageState extends State<TravelerHomePage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _selectedIndex = 0;
  String userName = "Juan"; // Will be loaded from database
  int activeTrips = 0; // Will be loaded from TripService
  int totalEarnings = 0; // Will be loaded from TripService
  bool _isVerified = false;
  bool _isLoading = true;

  // Trip form controllers
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _slotsController = TextEditingController(
    text: '5',
  );

  // Distance and pricing
  double? _totalDistanceKm;
  double? _calculatedPrice;
  bool _isCalculatingDistance = false;
  final DistanceService _distanceService = DistanceService();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Location coordinates
  double? _departureLat;
  double? _departureLng;
  double? _destinationLat;
  double? _destinationLng;
  double? _currentLat;
  double? _currentLng;

  // Map controller
  GoogleMapController? _mapController;
  GoogleMapController? _expandedMapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final TripService _tripService = TripService();
  final NotificationService _notificationService = NotificationService();
  final WalletService _walletService = WalletService();
  int _unreadNotifications = 0;
  RealtimeChannel? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkVerificationStatus();
    _loadUserName();
    _loadTripStats();
    _loadTotalEarnings();
    _loadUnreadNotifications();
    _setupNotificationSubscription();
    _setDefaultDeparture(); // Set current location as default departure
  }

  void _setupNotificationSubscription() {
    try {
      _notificationSubscription = _notificationService.subscribeToNotifications(
        (notification) {
          if (mounted) {
            _loadUnreadNotifications();

            // Show a snackbar for new notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(notification.title),
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsPage(),
                      ),
                    );
                  },
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    } catch (e) {
      print('Error subscribing to notifications: $e');
    }
  }

  Future<void> _loadUnreadNotifications() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotifications = count;
      });
    }
  }

  Future<void> _loadUserName() async {
    final supabaseService = SupabaseService();
    final userData = await supabaseService.getUserData();

    if (userData != null && mounted) {
      setState(() {
        // Get first name only for greeting
        userName = userData['first_name'] ?? 'Juan';
      });
    }
  }

  Future<void> _loadTripStats() async {
    try {
      final stats = await _tripService.getTripStats();
      if (mounted) {
        setState(() {
          activeTrips = stats.activeTrips;
        });
      }
    } catch (e) {
      print('Error loading trip stats: $e');
    }
  }

  Future<void> _loadTotalEarnings() async {
    try {
      final earnings = await _walletService.getTotalEarnings();
      if (mounted) {
        setState(() {
          totalEarnings = earnings.toInt();
        });
      }
    } catch (e) {
      print('Error loading total earnings: $e');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.unsubscribe();
    _departureController.dispose();
    _destinationController.dispose();
    _slotsController.dispose();
    _mapController?.dispose();
    _expandedMapController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app comes back to foreground
      _checkVerificationStatus();
      _loadUserName();
      _loadTripStats();
      _loadTotalEarnings();
      _loadUnreadNotifications();
    }
  }

  Future<void> _checkVerificationStatus() async {
    final supabaseService = SupabaseService();
    final prefs = await SharedPreferences.getInstance();
    final userId = supabaseService.currentUser?.id ?? '';
    final hasShownKey = 'has_shown_verified_$userId';

    final isVerified = await supabaseService.isUserVerified();
    final hasShownVerifiedMessage = prefs.getBool(hasShownKey) ?? false;

    setState(() {
      _isVerified = isVerified;
      _isLoading = false;
    });

    // Show verified message only once per user, ever
    if (isVerified && !hasShownVerifiedMessage && mounted) {
      // Mark as shown for this user
      await prefs.setBool(hasShownKey, true);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.verified, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Congratulations! Your account has been verified.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _updateMapMarkers() async {
    Set<Marker> newMarkers = {};
    Set<Polyline> newPolylines = {};

    // Try to geocode departure if we have text but no coordinates
    if (_departureController.text.isNotEmpty &&
        (_departureLat == null || _departureLng == null)) {
      try {
        final locations = await locationFromAddress(
          _departureController.text.trim(),
        );
        if (locations.isNotEmpty) {
          _departureLat = locations.first.latitude;
          _departureLng = locations.first.longitude;
          print('✅ Geocoded departure: $_departureLat, $_departureLng');
        }
      } catch (e) {
        print('❌ Could not geocode departure: $e');
      }
    }

    // Try to geocode destination if we have text but no coordinates
    if (_destinationController.text.isNotEmpty &&
        (_destinationLat == null || _destinationLng == null)) {
      try {
        final locations = await locationFromAddress(
          _destinationController.text.trim(),
        );
        if (locations.isNotEmpty) {
          _destinationLat = locations.first.latitude;
          _destinationLng = locations.first.longitude;
          print('✅ Geocoded destination: $_destinationLat, $_destinationLng');
        }
      } catch (e) {
        print('❌ Could not geocode destination: $e');
      }
    }

    // Fetch and draw route polyline if both locations are set
    if (_departureLat != null &&
        _departureLng != null &&
        _destinationLat != null &&
        _destinationLng != null) {
      try {
        print('🗺️ Fetching route polyline...');
        final routePoints = await _distanceService.getRoutePolyline(
          originLat: _departureLat!,
          originLng: _departureLng!,
          destLat: _destinationLat!,
          destLng: _destinationLng!,
        );

        print('📍 Got ${routePoints.length} route points');

        if (routePoints.length > 2) {
          // Real route from API - draw polyline only, no markers
          newPolylines.add(
            Polyline(
              polylineId: PolylineId('route'),
              points: routePoints,
              color: Color(0xFF00B4D8), // Cyan color matching the UI
              width: 6,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
          print(
            '✅ Route polyline added with ${routePoints.length} points - NO MARKERS',
          );
        } else {
          // Fallback straight line - still draw it but thicker to be visible
          newPolylines.add(
            Polyline(
              polylineId: PolylineId('route'),
              points: routePoints,
              color: Color(0xFF00B4D8),
              width: 6,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
          print('⚠️ Using straight line fallback (API may not be enabled)');
        }
      } catch (e) {
        print('❌ Error fetching route polyline: $e');
      }
    } else {
      // Show individual markers only when we don't have both locations yet
      if (_departureLat != null && _departureLng != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('departure'),
            position: LatLng(_departureLat!, _departureLng!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: 'Departure',
              snippet: _departureController.text.isEmpty
                  ? 'Starting point'
                  : _departureController.text,
            ),
          ),
        );
      }
      if (_destinationLat != null && _destinationLng != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('destination'),
            position: LatLng(_destinationLat!, _destinationLng!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: _destinationController.text.isEmpty
                  ? 'End point'
                  : _destinationController.text,
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _polylines = newPolylines;
      });

      // Animate camera to show both markers
      if (_departureLat != null &&
          _departureLng != null &&
          _destinationLat != null &&
          _destinationLng != null) {
        try {
          // Calculate bounds
          final double south = _departureLat! < _destinationLat!
              ? _departureLat!
              : _destinationLat!;
          final double north = _departureLat! > _destinationLat!
              ? _departureLat!
              : _destinationLat!;
          final double west = _departureLng! < _destinationLng!
              ? _departureLng!
              : _destinationLng!;
          final double east = _departureLng! > _destinationLng!
              ? _departureLng!
              : _destinationLng!;

          // Add padding to bounds
          final double latPadding = (north - south) * 0.3;
          final double lngPadding = (east - west) * 0.3;

          await _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(south - latPadding, west - lngPadding),
                northeast: LatLng(north + latPadding, east + lngPadding),
              ),
              50,
            ),
          );
          print('✅ Map zoomed to show both markers');
        } catch (e) {
          print('❌ Error zooming map: $e');
        }
      } else if (_departureLat != null && _departureLng != null) {
        // Only departure, zoom to it
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_departureLat!, _departureLng!),
            13,
          ),
        );
      } else if (_destinationLat != null && _destinationLng != null) {
        // Only destination, zoom to it
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_destinationLat!, _destinationLng!),
            13,
          ),
        );
      }
    }
  }

  Future<void> _registerTrip() async {
    // Validation
    if (_departureController.text.isEmpty) {
      _showSnackBar('Please enter departure location', Colors.orange);
      return;
    }

    if (_destinationController.text.isEmpty) {
      _showSnackBar('Please enter destination location', Colors.orange);
      return;
    }

    if (_selectedDate == null) {
      _showSnackBar('Please select departure date', Colors.orange);
      return;
    }

    if (_selectedTime == null) {
      _showSnackBar('Please select departure time', Colors.orange);
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // Try to geocode locations if not already set
      if (_departureLat == null || _departureLng == null) {
        try {
          final depLocations = await locationFromAddress(
            _departureController.text.trim(),
          );
          if (depLocations.isNotEmpty) {
            _departureLat = depLocations.first.latitude;
            _departureLng = depLocations.first.longitude;
          }
        } catch (e) {
          print('Could not geocode departure location: $e');
          // Continue without coordinates
        }
      }

      if (_destinationLat == null || _destinationLng == null) {
        try {
          final destLocations = await locationFromAddress(
            _destinationController.text.trim(),
          );
          if (destLocations.isNotEmpty) {
            _destinationLat = destLocations.first.latitude;
            _destinationLng = destLocations.first.longitude;
          }
        } catch (e) {
          print('Could not geocode destination location: $e');
          // Continue without coordinates
        }
      }

      // Format time as HH:mm:ss
      final timeString =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      // Parse slots
      final slots = int.tryParse(_slotsController.text.trim()) ?? 5;

      // Use calculated price (both services use same price based on distance)
      final servicePrice = _calculatedPrice ?? 50.0;

      await _tripService.createTrip(
        departureLocation: _departureController.text.trim(),
        departureLat: _departureLat,
        departureLng: _departureLng,
        destinationLocation: _destinationController.text.trim(),
        destinationLat: _destinationLat,
        destinationLng: _destinationLng,
        departureDate: _selectedDate!,
        departureTime: timeString,
        availableCapacity: slots,
        baseFee: 0.0,
        pasabayPrice: servicePrice,
        pabakalPrice: servicePrice,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Clear form
        _departureController.clear();
        _destinationController.clear();
        _slotsController.text = '5';
        setState(() {
          _selectedDate = null;
          _selectedTime = null;
          _departureLat = null;
          _departureLng = null;
          _destinationLat = null;
          _destinationLng = null;
          _totalDistanceKm = null;
          _calculatedPrice = null;
          _markers.clear();
        });

        // Reload stats
        _loadTripStats();

        _showSnackBar('Trip registered successfully!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSnackBar('Failed to register trip: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Please enable location services', Colors.orange);
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permissions are denied', Colors.orange);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
          'Location permissions are permanently denied',
          Colors.red,
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });

      print('✅ Current location: $_currentLat, $_currentLng');
    } catch (e) {
      print('❌ Error getting location: $e');
      _showSnackBar('Could not get current location', Colors.orange);
    }
  }

  /// Set current city as default departure location
  Future<void> _setDefaultDeparture() async {
    try {
      // Check if location permission is granted
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Get current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          _departureLat = position.latitude;
          _departureLng = position.longitude;
        });

        // Get city name from coordinates
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final cityName =
                place.locality ?? place.subAdministrativeArea ?? '';
            if (cityName.isNotEmpty) {
              _departureController.text = cityName;
              print('✅ Default departure set to: $cityName');
            }
          }
        } catch (e) {
          print('⚠️ Could not get city name: $e');
          _departureController.text = 'Current Location';
        }

        _updateMapMarkers();
      }
    } catch (e) {
      print('⚠️ Could not set default departure: $e');
      // Silent fail - user can manually enter location
    }
  }

  /// Calculate distance and price when both locations are set
  Future<void> _calculateDistanceAndPrice() async {
    if (_departureLat == null ||
        _departureLng == null ||
        _destinationLat == null ||
        _destinationLng == null) {
      return;
    }

    setState(() {
      _isCalculatingDistance = true;
    });

    try {
      final result = await _distanceService.calculateDistance(
        originLat: _departureLat!,
        originLng: _departureLng!,
        destLat: _destinationLat!,
        destLng: _destinationLng!,
      );

      if (result.success) {
        setState(() {
          _totalDistanceKm = result.distanceInKm;
          _calculatedPrice = result.price;
          _isCalculatingDistance = false;
        });
        print('✅ Distance: ${result.distanceInKm.toStringAsFixed(2)} km');
        print('✅ Price: ₱${result.price.toStringAsFixed(2)}');
      } else {
        setState(() {
          _isCalculatingDistance = false;
        });
        _showSnackBar(
          'Could not calculate distance: ${result.errorMessage}',
          Colors.orange,
        );
      }
    } catch (e) {
      setState(() {
        _isCalculatingDistance = false;
      });
      print('❌ Error calculating distance: $e');
    }
  }

  Widget _buildExpandedMapWidget(
    double scaleFactor, [
    VoidCallback? onMarkerUpdate,
  ]) {
    // Determine initial camera position
    LatLng initialPosition;
    double initialZoom = 11.0;

    if (_departureLat != null &&
        _departureLng != null &&
        _destinationLat != null &&
        _destinationLng != null) {
      // Center between both points
      initialPosition = LatLng(
        (_departureLat! + _destinationLat!) / 2,
        (_departureLng! + _destinationLng!) / 2,
      );
      initialZoom = 10.0;
    } else if (_currentLat != null && _currentLng != null) {
      initialPosition = LatLng(_currentLat!, _currentLng!);
      initialZoom = 13.0;
    } else if (_departureLat != null && _departureLng != null) {
      initialPosition = LatLng(_departureLat!, _departureLng!);
      initialZoom = 13.0;
    } else if (_destinationLat != null && _destinationLng != null) {
      initialPosition = LatLng(_destinationLat!, _destinationLng!);
      initialZoom = 13.0;
    } else {
      // Default to Manila
      initialPosition = LatLng(14.5995, 120.9842);
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: initialZoom,
      ),
      markers: _markers,
      polylines: _polylines,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
        Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
        Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
        Factory<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(),
        ),
        Factory<HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(),
        ),
      },
      onMapCreated: (GoogleMapController controller) {
        if (!mounted) return;
        _expandedMapController = controller;
        print('✅ Expanded map initialized');
      },
      onTap: (LatLng position) {
        _handleMapTap(position, onMarkerUpdate);
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapType: MapType.normal,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
    );
  }

  Future<void> _showExpandedMap(double scaleFactor) async {
    // Don't wait for location - show map immediately
    // Location will be fetched in background if needed
    if (_currentLat == null || _currentLng == null) {
      _getCurrentLocation(); // Fire and forget
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24 * scaleFactor),
                  topRight: Radius.circular(24 * scaleFactor),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16 * scaleFactor),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Select Location on Map',
                            style: TextStyle(
                              fontSize: 18 * scaleFactor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateMapMarkers();
                          },
                          icon: Icon(Icons.check, size: 20 * scaleFactor),
                          label: Text('Done'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppConstants.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expanded Map
                  Expanded(
                    child: _buildExpandedMapWidget(scaleFactor, () {
                      setModalState(() {});
                      setState(() {});
                    }),
                  ),
                  // Instructions
                  Container(
                    padding: EdgeInsets.all(16 * scaleFactor),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppConstants.primaryColor,
                          size: 20 * scaleFactor,
                        ),
                        SizedBox(width: 12 * scaleFactor),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tap on the map to drop pins',
                                style: TextStyle(
                                  fontSize: 14 * scaleFactor,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4 * scaleFactor),
                              Text(
                                'First tap = Departure (🟢), Second tap = Destination (🔴)',
                                style: TextStyle(
                                  fontSize: 12 * scaleFactor,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Optimized map tap handler - non-blocking
  void _handleMapTap(LatLng position, VoidCallback? onMarkerUpdate) {
    // Immediately update coordinates and show feedback
    if (_departureController.text.isEmpty ||
        (_departureLat == null && _destinationLat != null)) {
      // Set as departure
      setState(() {
        _departureLat = position.latitude;
        _departureLng = position.longitude;
        _departureController.text =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
      _showSnackBar('🟢 Departure set!', Colors.green);

      // Geocode in background (non-blocking)
      _geocodeLocationAsync(position, true);
    } else if (_destinationController.text.isEmpty || _destinationLat == null) {
      // Set as destination
      setState(() {
        _destinationLat = position.latitude;
        _destinationLng = position.longitude;
        _destinationController.text =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
      _showSnackBar('🔴 Destination set!', Colors.red);

      // Geocode in background (non-blocking)
      _geocodeLocationAsync(position, false);

      // Calculate distance if both locations are set
      if (_departureLat != null && _departureLng != null) {
        _calculateDistanceAndPrice();
      }
    } else {
      _showSnackBar('Clear a location first to set a new one', Colors.orange);
      return;
    }

    // Update markers immediately
    _updateMapMarkersSync();
    if (onMarkerUpdate != null) {
      onMarkerUpdate();
    }
  }

  // Sync version for immediate marker update (without route fetching)
  void _updateMapMarkersSync() {
    Set<Marker> newMarkers = {};

    // Always show departure marker if set
    if (_departureLat != null && _departureLng != null) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('departure'),
          position: LatLng(_departureLat!, _departureLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: 'Departure'),
        ),
      );
    }

    // Always show destination marker if set
    if (_destinationLat != null && _destinationLng != null) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('destination'),
          position: LatLng(_destinationLat!, _destinationLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Destination'),
        ),
      );
    }

    // Update markers immediately for visual feedback
    setState(() {
      _markers = newMarkers;
    });

    // If both are set, fetch route async (will update markers again with route)
    if (_departureLat != null &&
        _departureLng != null &&
        _destinationLat != null &&
        _destinationLng != null) {
      _updateMapMarkers(); // This will fetch route in background
    }
  }

  // Background geocoding - doesn't block UI
  Future<void> _geocodeLocationAsync(LatLng position, bool isDeparture) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address =
            '${place.locality ?? place.subAdministrativeArea ?? ''}, ${place.country ?? ''}'
                .trim();
        if (address.isNotEmpty && address != ', ') {
          setState(() {
            if (isDeparture) {
              _departureController.text = address;
            } else {
              _destinationController.text = address;
            }
          });
        }
      }
    } catch (e) {
      // Keep the coordinate text, geocoding failed silently
      print('Geocoding failed: $e');
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    // Determine which location to set based on what's empty
    if (_departureController.text.isEmpty ||
        (_departureLat == null && _destinationLat != null)) {
      // Set as departure
      setState(() {
        _departureLat = position.latitude;
        _departureLng = position.longitude;
      });

      // Try to get address for this location
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address =
              '${place.locality ?? place.subAdministrativeArea ?? ''}, ${place.country ?? ''}';
          _departureController.text = address.trim();
        }
      } catch (e) {
        _departureController.text =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      _showSnackBar('🟢 Departure location set!', Colors.green);
    } else if (_destinationController.text.isEmpty || _destinationLat == null) {
      // Set as destination
      setState(() {
        _destinationLat = position.latitude;
        _destinationLng = position.longitude;
      });

      // Try to get address for this location
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address =
              '${place.locality ?? place.subAdministrativeArea ?? ''}, ${place.country ?? ''}';
          _destinationController.text = address.trim();
        }
      } catch (e) {
        _destinationController.text =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      _showSnackBar('🔴 Destination location set!', Colors.red);

      // Calculate distance if both locations are set
      if (_departureLat != null && _departureLng != null) {
        await _calculateDistanceAndPrice();
      }
    } else {
      // Both are set, ask which one to replace
      _showSnackBar('Clear a location first to set a new one', Colors.orange);
    }

    _updateMapMarkers();
  }

  Widget _buildMapWidget(double scaleFactor) {
    // Return a simpler map widget with better error handling
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16 * scaleFactor),
      ),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(14.5995, 120.9842), // Manila, Philippines
          zoom: 11,
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (GoogleMapController controller) async {
          if (!mounted) return;

          try {
            _mapController = controller;
            print('✅ Google Maps initialized successfully!');

            // Wait a bit before updating markers
            await Future.delayed(Duration(milliseconds: 300));

            // Auto-update markers if locations are already set
            if (_departureController.text.isNotEmpty ||
                _destinationController.text.isNotEmpty) {
              _updateMapMarkers();
            }
          } catch (e) {
            print('⚠️ Map initialization warning: $e');
          }
        },
        onTap: _onMapTap, // Allow tapping to drop pins
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
        compassEnabled: true,
        rotateGesturesEnabled: true,
        scrollGesturesEnabled: true,
        tiltGesturesEnabled: true,
        zoomGesturesEnabled: true,
        // Add padding to avoid UI overlap
        padding: EdgeInsets.only(top: 40 * scaleFactor),
      ),
    );
  }

  Widget _buildMapWidgetWithErrorHandling(double scaleFactor) {
    try {
      return _buildMapWidget(scaleFactor);
    } catch (e) {
      print('❌ Google Maps error: $e');
      // Fallback if there's any issue with Maps
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16 * scaleFactor),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48 * scaleFactor,
                color: Colors.orange,
              ),
              SizedBox(height: 12 * scaleFactor),
              Text(
                'Map Loading...',
                style: TextStyle(
                  fontSize: 16 * scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4 * scaleFactor),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24 * scaleFactor),
                child: Text(
                  'Please wait or check your internet connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11 * scaleFactor,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _checkVerificationStatus,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12 * scaleFactor),
                  // Top bar: logo and role icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36 * scaleFactor,
                            height: 36 * scaleFactor,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                8 * scaleFactor,
                              ),
                              image: const DecorationImage(
                                image: AssetImage(AppConstants.logoPath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * scaleFactor),
                          Text(
                            'Pasabay',
                            style: TextStyle(
                              fontSize: 18 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF00B4D8),
                              borderRadius: BorderRadius.circular(
                                10 * scaleFactor,
                              ),
                            ),
                            padding: EdgeInsets.all(8 * scaleFactor),
                            child: Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: 28 * scaleFactor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16 * scaleFactor),
                  // Search bar with notifications
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search for location, route, etc.',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 15 * scaleFactor,
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16 * scaleFactor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12 * scaleFactor),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsPage(),
                            ),
                          );
                          _loadUnreadNotifications();
                        },
                        child: Container(
                          width: 44 * scaleFactor,
                          height: 44 * scaleFactor,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: AppConstants.primaryColor,
                                  size: 26 * scaleFactor,
                                ),
                              ),
                              if (_unreadNotifications > 0)
                                Positioned(
                                  right: 10 * scaleFactor,
                                  top: 10 * scaleFactor,
                                  child: Container(
                                    width: 10 * scaleFactor,
                                    height: 10 * scaleFactor,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18 * scaleFactor),

                  // Verification Status Banner (only show warning if not verified)
                  if (!_isLoading && !_isVerified)
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(14 * scaleFactor),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF4E6),
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
                            border: Border.all(
                              color: Color(0xFFFFB74D),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFF57C00),
                                size: 24 * scaleFactor,
                              ),
                              SizedBox(width: 12 * scaleFactor),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Account Not Verified',
                                      style: TextStyle(
                                        fontSize: 15 * scaleFactor,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF57C00),
                                      ),
                                    ),
                                    SizedBox(height: 4 * scaleFactor),
                                    Text(
                                      'Please verify your identity to start accepting delivery requests.',
                                      style: TextStyle(
                                        fontSize: 13 * scaleFactor,
                                        color: Color(0xFF5D4037),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8 * scaleFactor),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    '/identity_verification',
                                  );
                                  // Refresh status when returning from verification screen
                                  _checkVerificationStatus();
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12 * scaleFactor,
                                    vertical: 8 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF57C00),
                                    borderRadius: BorderRadius.circular(
                                      8 * scaleFactor,
                                    ),
                                  ),
                                  child: Text(
                                    'Verify Now',
                                    style: TextStyle(
                                      fontSize: 13 * scaleFactor,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 18 * scaleFactor),
                      ],
                    ),

                  // Greeting
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $userName!',
                        style: TextStyle(
                          fontSize: 28 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6 * scaleFactor),
                      Text(
                        "Here's your overview for ${DateFormat('MMMM').format(DateTime.now())}",
                        style: TextStyle(
                          fontSize: 15 * scaleFactor,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24 * scaleFactor),
                  // Cards: Active Trips & Total Earnings
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16 * scaleFactor),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              16 * scaleFactor,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8 * scaleFactor),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    8 * scaleFactor,
                                  ),
                                ),
                                child: Icon(
                                  Icons.directions_car_filled,
                                  color: AppConstants.primaryColor,
                                  size: 20 * scaleFactor,
                                ),
                              ),
                              SizedBox(height: 12 * scaleFactor),
                              Text(
                                'Active Trips',
                                style: TextStyle(
                                  fontSize: 13 * scaleFactor,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4 * scaleFactor),
                              Text(
                                '$activeTrips',
                                style: TextStyle(
                                  fontSize: 24 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12 * scaleFactor),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16 * scaleFactor),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              16 * scaleFactor,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8 * scaleFactor),
                                decoration: BoxDecoration(
                                  color: Color(0xFF00B4D8).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    8 * scaleFactor,
                                  ),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: Color(0xFF00B4D8),
                                  size: 20 * scaleFactor,
                                ),
                              ),
                              SizedBox(height: 12 * scaleFactor),
                              Text(
                                'Total Earnings',
                                style: TextStyle(
                                  fontSize: 13 * scaleFactor,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4 * scaleFactor),
                              Text(
                                '₱$totalEarnings',
                                style: TextStyle(
                                  fontSize: 24 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24 * scaleFactor),
                  SizedBox(height: 24 * scaleFactor),
                  // Plan Your Route
                  Text(
                    'Plan Your Route',
                    style: TextStyle(
                      fontSize: 20 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16 * scaleFactor),

                  // Route Card (Cyan) - Matching Requester's Find Travelers style
                  Container(
                    padding: EdgeInsets.all(20 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Color(0xFF00B4D8),
                      borderRadius: BorderRadius.circular(16 * scaleFactor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route',
                          style: TextStyle(
                            fontSize: 32 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8 * scaleFactor),
                        Text(
                          'Set your departure and destination',
                          style: TextStyle(
                            fontSize: 14 * scaleFactor,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 16 * scaleFactor),

                        // Departure Location Input
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16 * scaleFactor,
                            vertical: 4 * scaleFactor,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.trip_origin,
                                color: Color(0xFF00B4D8),
                                size: 22 * scaleFactor,
                              ),
                              SizedBox(width: 12 * scaleFactor),
                              Expanded(
                                child: TextField(
                                  controller: _departureController,
                                  decoration: InputDecoration(
                                    hintText: 'From (e.g., Iloilo)',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      fontSize: 15 * scaleFactor,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 15 * scaleFactor,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  onSubmitted: (value) async {
                                    if (value.isNotEmpty) {
                                      try {
                                        final locations =
                                            await locationFromAddress(value);
                                        if (locations.isNotEmpty) {
                                          setState(() {
                                            _departureLat =
                                                locations.first.latitude;
                                            _departureLng =
                                                locations.first.longitude;
                                          });
                                          _updateMapMarkers();
                                          if (_destinationLat != null &&
                                              _destinationLng != null) {
                                            await _calculateDistanceAndPrice();
                                          }
                                        }
                                      } catch (e) {
                                        _showSnackBar(
                                          'Could not find location',
                                          Colors.orange,
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                              // Use current location button
                              GestureDetector(
                                onTap: () async {
                                  await _setDefaultDeparture();
                                  _showSnackBar(
                                    'Using current location',
                                    Colors.green,
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8 * scaleFactor),
                                  child: Icon(
                                    Icons.my_location,
                                    color: Color(0xFF00B4D8),
                                    size: 22 * scaleFactor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 12 * scaleFactor),

                        // Destination Location Input
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16 * scaleFactor,
                            vertical: 4 * scaleFactor,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Color(0xFF00B4D8),
                                size: 22 * scaleFactor,
                              ),
                              SizedBox(width: 12 * scaleFactor),
                              Expanded(
                                child: TextField(
                                  controller: _destinationController,
                                  decoration: InputDecoration(
                                    hintText: 'To (e.g., Roxas)',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      fontSize: 15 * scaleFactor,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 15 * scaleFactor,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  onSubmitted: (value) async {
                                    if (value.isNotEmpty) {
                                      try {
                                        final locations =
                                            await locationFromAddress(value);
                                        if (locations.isNotEmpty) {
                                          setState(() {
                                            _destinationLat =
                                                locations.first.latitude;
                                            _destinationLng =
                                                locations.first.longitude;
                                          });
                                          _updateMapMarkers();
                                          if (_departureLat != null &&
                                              _departureLng != null) {
                                            await _calculateDistanceAndPrice();
                                          }
                                        }
                                      } catch (e) {
                                        _showSnackBar(
                                          'Could not find location',
                                          Colors.orange,
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                              // Clear destination button
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _destinationController.clear();
                                    _destinationLat = null;
                                    _destinationLng = null;
                                    _totalDistanceKm = null;
                                    _calculatedPrice = null;
                                    _polylines.clear();
                                  });
                                  _updateMapMarkers();
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8 * scaleFactor),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.grey[500],
                                    size: 22 * scaleFactor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16 * scaleFactor),

                  // Open Map Button
                  GestureDetector(
                    onTap: () => _showExpandedMap(scaleFactor),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14 * scaleFactor),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                        border: Border.all(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            color: AppConstants.primaryColor,
                            size: 22 * scaleFactor,
                          ),
                          SizedBox(width: 8 * scaleFactor),
                          Text(
                            'Open Map to Select Destination',
                            style: TextStyle(
                              fontSize: 15 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 18 * scaleFactor),
                  SizedBox(height: 18 * scaleFactor),
                  // Schedule
                  Container(
                    padding: EdgeInsets.all(20 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20 * scaleFactor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: AppConstants.primaryColor,
                              size: 20 * scaleFactor,
                            ),
                            SizedBox(width: 8 * scaleFactor),
                            Text(
                              'Schedule',
                              style: TextStyle(
                                fontSize: 16 * scaleFactor,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16 * scaleFactor),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _selectDate,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14 * scaleFactor,
                                    horizontal: 12 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(
                                      12 * scaleFactor,
                                    ),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 18 * scaleFactor,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 8 * scaleFactor),
                                      Expanded(
                                        child: Text(
                                          _selectedDate == null
                                              ? 'Select Date'
                                              : DateFormat(
                                                  'MMM dd, yyyy',
                                                ).format(_selectedDate!),
                                          style: TextStyle(
                                            fontSize: 14 * scaleFactor,
                                            color: _selectedDate == null
                                                ? Colors.grey[500]
                                                : Colors.black87,
                                            fontWeight: _selectedDate == null
                                                ? FontWeight.normal
                                                : FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12 * scaleFactor),
                            Expanded(
                              child: GestureDetector(
                                onTap: _selectTime,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14 * scaleFactor,
                                    horizontal: 12 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(
                                      12 * scaleFactor,
                                    ),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_outlined,
                                        size: 18 * scaleFactor,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 8 * scaleFactor),
                                      Expanded(
                                        child: Text(
                                          _selectedTime == null
                                              ? 'Select Time'
                                              : _selectedTime!.format(context),
                                          style: TextStyle(
                                            fontSize: 14 * scaleFactor,
                                            color: _selectedTime == null
                                                ? Colors.grey[500]
                                                : Colors.black87,
                                            fontWeight: _selectedTime == null
                                                ? FontWeight.normal
                                                : FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18 * scaleFactor),
                  // Service Pricing & Capacity
                  Container(
                    padding: EdgeInsets.all(20 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20 * scaleFactor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: AppConstants.primaryColor,
                              size: 20 * scaleFactor,
                            ),
                            SizedBox(width: 8 * scaleFactor),
                            Text(
                              'Pricing & Capacity',
                              style: TextStyle(
                                fontSize: 16 * scaleFactor,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16 * scaleFactor),
                        // Available Slots
                        Text(
                          'Available Slots',
                          style: TextStyle(
                            fontSize: 13 * scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8 * scaleFactor),
                        TextField(
                          controller: _slotsController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 14 * scaleFactor),
                          decoration: InputDecoration(
                            hintText: 'Number of available slots',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14 * scaleFactor,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16 * scaleFactor,
                              vertical: 14 * scaleFactor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                12 * scaleFactor,
                              ),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                12 * scaleFactor,
                              ),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                12 * scaleFactor,
                              ),
                              borderSide: BorderSide(
                                color: AppConstants.primaryColor,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: Icon(
                              Icons.people_outline,
                              color: Colors.grey[600],
                              size: 20 * scaleFactor,
                            ),
                          ),
                        ),
                        SizedBox(height: 16 * scaleFactor),
                        // Distance and Price Display
                        if (_totalDistanceKm != null &&
                            _calculatedPrice != null) ...[
                          Container(
                            padding: EdgeInsets.all(16 * scaleFactor),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                12 * scaleFactor,
                              ),
                              border: Border.all(
                                color: AppConstants.primaryColor.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.route,
                                          color: AppConstants.primaryColor,
                                          size: 20 * scaleFactor,
                                        ),
                                        SizedBox(width: 8 * scaleFactor),
                                        Text(
                                          'Total Distance',
                                          style: TextStyle(
                                            fontSize: 14 * scaleFactor,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _distanceService.formatDistance(
                                        _totalDistanceKm!,
                                      ),
                                      style: TextStyle(
                                        fontSize: 16 * scaleFactor,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12 * scaleFactor),
                                Divider(height: 1),
                                SizedBox(height: 12 * scaleFactor),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          color: Colors.green[700],
                                          size: 20 * scaleFactor,
                                        ),
                                        SizedBox(width: 8 * scaleFactor),
                                        Text(
                                          'Service Fee',
                                          style: TextStyle(
                                            fontSize: 14 * scaleFactor,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _distanceService.formatPrice(
                                        _calculatedPrice!,
                                      ),
                                      style: TextStyle(
                                        fontSize: 18 * scaleFactor,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8 * scaleFactor),
                                Text(
                                  'Same price for both Pasabay & Pabakal',
                                  style: TextStyle(
                                    fontSize: 11 * scaleFactor,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_isCalculatingDistance) ...[
                          Container(
                            padding: EdgeInsets.all(16 * scaleFactor),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(
                                12 * scaleFactor,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20 * scaleFactor,
                                  height: 20 * scaleFactor,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12 * scaleFactor),
                                Text(
                                  'Calculating distance...',
                                  style: TextStyle(
                                    fontSize: 13 * scaleFactor,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: EdgeInsets.all(16 * scaleFactor),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(
                                12 * scaleFactor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.grey[600],
                                  size: 20 * scaleFactor,
                                ),
                                SizedBox(width: 12 * scaleFactor),
                                Expanded(
                                  child: Text(
                                    'Set both locations to calculate service fee',
                                    style: TextStyle(
                                      fontSize: 13 * scaleFactor,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 20 * scaleFactor),
                  // Map
                  Container(
                    height: 200 * scaleFactor,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20 * scaleFactor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20 * scaleFactor),
                      child: Stack(
                        children: [
                          // Map Widget with error handling
                          _buildMapWidgetWithErrorHandling(scaleFactor),

                          // Route preview badge (when polyline exists)
                          if (_polylines.isNotEmpty)
                            Positioned(
                              top: 12 * scaleFactor,
                              left: 12 * scaleFactor,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12 * scaleFactor,
                                  vertical: 6 * scaleFactor,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    12 * scaleFactor,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.route,
                                      color: AppConstants.primaryColor,
                                      size: 14 * scaleFactor,
                                    ),
                                    SizedBox(width: 6 * scaleFactor),
                                    Text(
                                      'Route Preview',
                                      style: TextStyle(
                                        fontSize: 13 * scaleFactor,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 18 * scaleFactor),
                  // Register Travel Button
                  SizedBox(
                    width: double.infinity,
                    height: 56 * scaleFactor,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isVerified
                            ? AppConstants.primaryColor
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: AppConstants.primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16 * scaleFactor),
                        ),
                      ),
                      onPressed: _isVerified ? _registerTrip : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 24 * scaleFactor,
                          ),
                          SizedBox(width: 10 * scaleFactor),
                          Text(
                            'Register Travel',
                            style: TextStyle(
                              fontSize: 18 * scaleFactor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24 * scaleFactor),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppConstants.primaryColor,
              unselectedItemColor: Colors.grey,
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (index == 1) {
                  // Navigate to Activity page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActivityPage(),
                    ),
                  ).then((_) {
                    // Reset to home tab when returning from Activity page
                    setState(() {
                      _selectedIndex = 0;
                    });
                  });
                } else if (index == 2) {
                  // Navigate to Messages page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MessagesPage(),
                    ),
                  ).then((_) {
                    // Reset to home tab when returning from Messages page
                    setState(() {
                      _selectedIndex = 0;
                    });
                  });
                } else if (index == 3) {
                  // Navigate to Profile page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  ).then((_) {
                    // Reset to home tab when returning from Profile page
                    setState(() {
                      _selectedIndex = 0;
                    });
                  });
                } else {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.show_chart),
                  label: 'Activity',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  label: 'Messages',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
