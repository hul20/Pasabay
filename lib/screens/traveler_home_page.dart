import 'package:flutter/material.dart';
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
import 'activity_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';

class TravelerHomePage extends StatefulWidget {
  const TravelerHomePage({super.key});

  @override
  State<TravelerHomePage> createState() => _TravelerHomePageState();
}

class _TravelerHomePageState extends State<TravelerHomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String userName = "Juan"; // Will be loaded from database
  int activeTrips = 0; // Will be loaded from TripService
  int totalEarnings = 0; // Will be loaded from TripService
  bool _isVerified = false;
  bool _isLoading = true;
  
  // Trip form controllers
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkVerificationStatus();
    _loadUserName();
    _loadTripStats();
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
          totalEarnings = stats.currentMonthEarnings.toInt();
        });
      }
    } catch (e) {
      print('Error loading trip stats: $e');
    }
  }

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
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
    
    // Try to geocode departure if we have text but no coordinates
    if (_departureController.text.isNotEmpty && (_departureLat == null || _departureLng == null)) {
      try {
        final locations = await locationFromAddress(_departureController.text.trim());
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
    if (_destinationController.text.isNotEmpty && (_destinationLat == null || _destinationLng == null)) {
      try {
        final locations = await locationFromAddress(_destinationController.text.trim());
        if (locations.isNotEmpty) {
          _destinationLat = locations.first.latitude;
          _destinationLng = locations.first.longitude;
          print('✅ Geocoded destination: $_destinationLat, $_destinationLng');
        }
      } catch (e) {
        print('❌ Could not geocode destination: $e');
      }
    }
    
    // Add departure marker
    if (_departureLat != null && _departureLng != null) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('departure'),
          position: LatLng(_departureLat!, _departureLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Departure',
            snippet: _departureController.text.isEmpty ? 'Starting point' : _departureController.text,
          ),
        ),
      );
    }
    
    // Add destination marker
    if (_destinationLat != null && _destinationLng != null) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('destination'),
          position: LatLng(_destinationLat!, _destinationLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationController.text.isEmpty ? 'End point' : _destinationController.text,
          ),
        ),
      );
    }
    
    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
      
      // Animate camera to show both markers
      if (_departureLat != null && _departureLng != null && _destinationLat != null && _destinationLng != null) {
        try {
          // Calculate bounds
          final double south = _departureLat! < _destinationLat! ? _departureLat! : _destinationLat!;
          final double north = _departureLat! > _destinationLat! ? _departureLat! : _destinationLat!;
          final double west = _departureLng! < _destinationLng! ? _departureLng! : _destinationLng!;
          final double east = _departureLng! > _destinationLng! ? _departureLng! : _destinationLng!;
          
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
          final depLocations = await locationFromAddress(_departureController.text.trim());
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
          final destLocations = await locationFromAddress(_destinationController.text.trim());
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
      final timeString = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';
      
      await _tripService.createTrip(
        departureLocation: _departureController.text.trim(),
        departureLat: _departureLat,
        departureLng: _departureLng,
        destinationLocation: _destinationController.text.trim(),
        destinationLat: _destinationLat,
        destinationLng: _destinationLng,
        departureDate: _selectedDate!,
        departureTime: timeString,
        availableCapacity: 5,
        baseFee: 0.0,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Clear form
        _departureController.clear();
        _destinationController.clear();
        setState(() {
          _selectedDate = null;
          _selectedTime = null;
          _departureLat = null;
          _departureLng = null;
          _destinationLat = null;
          _destinationLng = null;
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
        _showSnackBar('Location permissions are permanently denied', Colors.red);
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

  Widget _buildExpandedMapWidget(double scaleFactor, [VoidCallback? onMarkerUpdate]) {
    // Determine initial camera position
    LatLng initialPosition;
    double initialZoom = 11.0;

    if (_currentLat != null && _currentLng != null) {
      // Use current location if available
      initialPosition = LatLng(_currentLat!, _currentLng!);
      initialZoom = 13.0;
    } else if (_departureLat != null && _departureLng != null) {
      // Use departure location
      initialPosition = LatLng(_departureLat!, _departureLng!);
    } else if (_destinationLat != null && _destinationLng != null) {
      // Use destination location
      initialPosition = LatLng(_destinationLat!, _destinationLng!);
    } else {
      // Default to Manila
      initialPosition = LatLng(14.5995, 120.9842);
    }

    return GoogleMap(
      key: ValueKey('expanded_map_${_markers.length}'), // Force rebuild when markers change
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: initialZoom,
      ),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (GoogleMapController controller) async {
        if (!mounted) return;
        
        try {
          _expandedMapController = controller;
          print('✅ Expanded map initialized successfully!');
          
          // Center on current location if available
          if (_currentLat != null && _currentLng != null) {
            await Future.delayed(Duration(milliseconds: 500));
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(_currentLat!, _currentLng!),
                13.0,
              ),
            );
          }
          
          // Update markers after a short delay
          await Future.delayed(Duration(milliseconds: 300));
          await _updateMapMarkers();
          if (onMarkerUpdate != null) {
            onMarkerUpdate();
          }
        } catch (e) {
          print('⚠️ Expanded map initialization warning: $e');
        }
      },
      onTap: (LatLng position) async {
        await _onMapTap(position);
        if (onMarkerUpdate != null) {
          onMarkerUpdate();
        }
      },
      myLocationEnabled: true, // Show user location
      myLocationButtonEnabled: true, // Show location button
      zoomControlsEnabled: true,
      mapType: MapType.normal,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true, // Enable dragging
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true, // Enable zooming
    );
  }

  Future<void> _showExpandedMap(double scaleFactor) async {
    // Get current location before showing map
    await _getCurrentLocation();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            _expandedMapController?.dispose();
                            _expandedMapController = null;
                            Navigator.pop(context);
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Pin Locations on Map',
                            style: TextStyle(
                              fontSize: 18 * scaleFactor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_departureController.text.isNotEmpty || _destinationController.text.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              _expandedMapController?.dispose();
                              _expandedMapController = null;
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
                    child: Container(
                      child: Builder(
                        builder: (context) {
                          // Create a callback that updates both parent and modal state
                          return _buildExpandedMapWidget(scaleFactor, () {
                            setModalState(() {});
                            setState(() {});
                          });
                        },
                      ),
                    ),
                  ),
              // Instructions
              Container(
                padding: EdgeInsets.all(16 * scaleFactor),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
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

  Future<void> _onMapTap(LatLng position) async {
    // Determine which location to set based on what's empty
    if (_departureController.text.isEmpty || (_departureLat == null && _destinationLat != null)) {
      // Set as departure
      setState(() {
        _departureLat = position.latitude;
        _departureLng = position.longitude;
      });
      
      // Try to get address for this location
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address = '${place.locality ?? place.subAdministrativeArea ?? ''}, ${place.country ?? ''}';
          _departureController.text = address.trim();
        }
      } catch (e) {
        _departureController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
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
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address = '${place.locality ?? place.subAdministrativeArea ?? ''}, ${place.country ?? ''}';
          _destinationController.text = address.trim();
        }
      } catch (e) {
        _destinationController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }
      
      _showSnackBar('🔴 Destination location set!', Colors.red);
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
            if (_departureController.text.isNotEmpty || _destinationController.text.isNotEmpty) {
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
                              image: NetworkImage(AppConstants.logoUrl),
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
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF00B4D8),
                        borderRadius: BorderRadius.circular(10 * scaleFactor),
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
                SizedBox(height: 16 * scaleFactor),
                // Search bar with notifications
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12 * scaleFactor),
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
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 16 * scaleFactor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * scaleFactor),
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_none,
                            size: 28 * scaleFactor,
                            color: Colors.black,
                          ),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 8 * scaleFactor,
                          top: 8 * scaleFactor,
                          child: Container(
                            width: 16 * scaleFactor,
                            height: 16 * scaleFactor,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '2',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10 * scaleFactor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                          borderRadius: BorderRadius.circular(12 * scaleFactor),
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
                                await Navigator.pushNamed(context, '/identity_verification');
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
                                  borderRadius: BorderRadius.circular(8 * scaleFactor),
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
                Text(
                  'Hello, $userName!',
                  style: TextStyle(
                    fontSize: 28 * scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6 * scaleFactor),
                Text(
                  "Here's an overview for this month of October",
                  style: TextStyle(
                    fontSize: 15 * scaleFactor,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 18 * scaleFactor),
                // Cards: Active Trips & Total Earnings
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(16 * scaleFactor),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16 * scaleFactor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Trips',
                              style: TextStyle(
                                fontSize: 15 * scaleFactor,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8 * scaleFactor),
                            Text(
                              '$activeTrips',
                              style: TextStyle(
                                fontSize: 28 * scaleFactor,
                                fontWeight: FontWeight.bold,
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
                          borderRadius: BorderRadius.circular(16 * scaleFactor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Earnings',
                              style: TextStyle(
                                fontSize: 15 * scaleFactor,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8 * scaleFactor),
                            Text(
                              '₱$totalEarnings',
                              style: TextStyle(
                                fontSize: 28 * scaleFactor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24 * scaleFactor),
                // Plan Your Route
                Text(
                  'Plan Your Route',
                  style: TextStyle(
                    fontSize: 20 * scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12 * scaleFactor),
                Container(
                  padding: EdgeInsets.all(16 * scaleFactor),
                  decoration: BoxDecoration(
                    color: Color(0xFFDBF6FF),
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destination',
                        style: TextStyle(
                          fontSize: 22 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B4D8),
                        ),
                      ),
                      SizedBox(height: 4 * scaleFactor),
                      Text(
                        'Tap to pin departure and target location',
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 12 * scaleFactor),
                      TextField(
                        controller: _departureController,
                              decoration: InputDecoration(
                          hintText: 'Departure Location (e.g., Manila, Philippines)',
                                border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8 * scaleFactor),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(
                                  Icons.location_on_outlined,
                            color: Colors.green,
                          ),
                          suffixIcon: _departureController.text.isNotEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.search, size: 20, color: Colors.green),
                                      onPressed: () {
                                        _updateMapMarkers();
                                      },
                                      tooltip: 'Find on map',
                            ),
                                    IconButton(
                                      icon: Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _departureController.clear();
                                          _departureLat = null;
                                          _departureLng = null;
                                        });
                                        _updateMapMarkers();
                                      },
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _updateMapMarkers();
                          }
                        },
                      ),
                      SizedBox(height: 8 * scaleFactor),
                      TextField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'Destination Location (e.g., Baguio, Philippines)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8 * scaleFactor),
                            borderSide: BorderSide.none,
                              ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(
                            Icons.place_outlined,
                            color: Colors.red,
                          ),
                          suffixIcon: _destinationController.text.isNotEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.search, size: 20, color: Colors.red),
                                      onPressed: () {
                                        _updateMapMarkers();
                                      },
                                      tooltip: 'Find on map',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _destinationController.clear();
                                          _destinationLat = null;
                                          _destinationLng = null;
                                        });
                                        _updateMapMarkers();
                                      },
                          ),
                        ],
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _updateMapMarkers();
                          }
                        },
                      ),
                      SizedBox(height: 12 * scaleFactor),
                      // Pin on Maps Button
                      GestureDetector(
                        onTap: () => _showExpandedMap(scaleFactor),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 12 * scaleFactor,
                            horizontal: 16 * scaleFactor,
                          ),
                            decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10 * scaleFactor),
                            border: Border.all(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                color: AppConstants.primaryColor,
                                size: 20 * scaleFactor,
                              ),
                              SizedBox(width: 8 * scaleFactor),
                              Text(
                                'Pin on Maps',
                                style: TextStyle(
                                  fontSize: 15 * scaleFactor,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                              SizedBox(width: 4 * scaleFactor),
                              Icon(
                                Icons.open_in_full,
                                color: AppConstants.primaryColor,
                                size: 18 * scaleFactor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18 * scaleFactor),
                // Schedule
                Container(
                  padding: EdgeInsets.all(16 * scaleFactor),
                  decoration: BoxDecoration(
                    color: Color(0xFFDBF6FF),
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 22 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B4D8),
                        ),
                      ),
                      SizedBox(height: 4 * scaleFactor),
                      Text(
                        'Tap to add travel date and time',
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 12 * scaleFactor),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    8 * scaleFactor,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: 14 * scaleFactor,
                                ),
                              ),
                              icon: Icon(Icons.calendar_today_outlined),
                              label: Text(
                                _selectedDate == null
                                    ? 'Select Date'
                                    : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                                style: TextStyle(fontSize: 13 * scaleFactor),
                              ),
                              onPressed: _selectDate,
                            ),
                          ),
                          SizedBox(width: 8 * scaleFactor),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    8 * scaleFactor,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: 14 * scaleFactor,
                                ),
                              ),
                              icon: Icon(Icons.access_time_outlined),
                              label: Text(
                                _selectedTime == null
                                    ? 'Select Time'
                                    : _selectedTime!.format(context),
                                style: TextStyle(fontSize: 13 * scaleFactor),
                              ),
                              onPressed: _selectTime,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18 * scaleFactor),
                // Map
                Container(
                  height: 200 * scaleFactor,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                  child: Stack(
                    children: [
                        // Map Widget with error handling
                        _buildMapWidgetWithErrorHandling(scaleFactor),
                        // Instructions banner
                        if (_markers.isEmpty)
                          Positioned(
                            top: 12 * scaleFactor,
                            left: 12 * scaleFactor,
                            right: 12 * scaleFactor,
                            child: Container(
                              padding: EdgeInsets.all(12 * scaleFactor),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor,
                                borderRadius: BorderRadius.circular(12 * scaleFactor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    color: Colors.white,
                                    size: 20 * scaleFactor,
                                  ),
                                  SizedBox(width: 8 * scaleFactor),
                                  Expanded(
                        child: Text(
                                      'Tap map to drop pins or type locations above',
                          style: TextStyle(
                                        fontSize: 12 * scaleFactor,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Route preview badge (when markers exist)
                        if (_markers.isNotEmpty)
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
                                borderRadius: BorderRadius.circular(12 * scaleFactor),
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
                                    '${_markers.length} location${_markers.length > 1 ? 's' : ''}',
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
                  height: 54 * scaleFactor,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isVerified ? AppConstants.primaryColor : Colors.grey,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16 * scaleFactor),
                      ),
                    ),
                    onPressed: _isVerified ? _registerTrip : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 22 * scaleFactor),
                        SizedBox(width: 8 * scaleFactor),
                        Text(
                      'Register Travel',
                      style: TextStyle(
                        fontSize: 18 * scaleFactor,
                        fontWeight: FontWeight.bold,
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
      bottomNavigationBar: BottomNavigationBar(
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
