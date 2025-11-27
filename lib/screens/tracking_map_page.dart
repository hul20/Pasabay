import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/location_tracking_service.dart';
import '../services/distance_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class TrackingMapPage extends StatefulWidget {
  final String requestId;
  final String travelerName;
  final String serviceType;
  final String status;

  const TrackingMapPage({
    super.key,
    required this.requestId,
    required this.travelerName,
    required this.serviceType,
    required this.status,
  });

  @override
  State<TrackingMapPage> createState() => _TrackingMapPageState();
}

class _TrackingMapPageState extends State<TrackingMapPage> {
  final LocationTrackingService _trackingService = LocationTrackingService();
  final DistanceService _distanceService = DistanceService();
  final _supabase = Supabase.instance.client;

  GoogleMapController? _mapController;
  RealtimeChannel? _locationChannel;

  LatLng? _travelerLocation;
  LatLng? _destinationLocation;
  String? _destinationName;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool _isLoading = true;
  String _errorMessage = '';

  // ETA and distance
  double _distanceKm = 0;
  double _durationMinutes = 0;
  bool _isCalculatingRoute = false;

  // Custom marker icons
  BitmapDescriptor? _travelerIcon;
  BitmapDescriptor? _destinationIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
    _loadDestinationAndLocation();
    _subscribeToLocationUpdates();
  }

  @override
  void dispose() {
    _trackingService.unsubscribeFromLocation();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCustomIcons() async {
    // Create traveler icon (delivery truck)
    _travelerIcon = await _createCustomIcon(
      Icons.local_shipping,
      AppConstants.primaryColor,
      56,
    );

    // Create destination icon (location pin)
    _destinationIcon = await _createCustomIcon(
      Icons.location_on,
      Colors.red,
      56,
    );

    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _createCustomIcon(
    IconData iconData,
    Color color,
    double size,
  ) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;

    // Draw circle background
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Draw white inner circle
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 4,
      Paint()..color = Colors.white,
    );

    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
        fontFamily: iconData.fontFamily,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _loadDestinationAndLocation() async {
    try {
      // Get request details including destination
      final requestData = await _supabase
          .from('service_requests')
          .select('''
            *,
            trips:trip_id (
              destination_location,
              destination_lat,
              destination_lng
            )
          ''')
          .eq('id', widget.requestId)
          .single();

      // Get destination from trip
      final tripData = requestData['trips'];
      if (tripData != null) {
        _destinationName = tripData['destination_location'];

        // Get destination coordinates
        if (tripData['destination_lat'] != null &&
            tripData['destination_lng'] != null) {
          _destinationLocation = LatLng(
            (tripData['destination_lat'] as num).toDouble(),
            (tripData['destination_lng'] as num).toDouble(),
          );
        }
      }

      // Get traveler's current location
      final location = await _trackingService.getCurrentLocation(
        widget.requestId,
      );

      if (location != null && mounted) {
        setState(() {
          _travelerLocation = LatLng(
            location['latitude']!,
            location['longitude']!,
          );
          _isLoading = false;
        });

        await _updateMarkersAndRoute();
        _fitMapToBounds();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Traveler location not available yet';
        });
      }
    } catch (e) {
      print('❌ Error loading destination and location: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading tracking data';
      });
    }
  }

  void _subscribeToLocationUpdates() {
    _locationChannel = _trackingService.subscribeToLocation(widget.requestId, (
      lat,
      lng,
    ) {
      if (mounted) {
        setState(() {
          _travelerLocation = LatLng(lat, lng);
        });

        _updateMarkersAndRoute();
      }
    });
  }

  Future<void> _updateMarkersAndRoute() async {
    if (_travelerLocation == null) return;

    // Update markers
    final markers = <Marker>{
      // Traveler marker
      Marker(
        markerId: const MarkerId('traveler'),
        position: _travelerLocation!,
        icon:
            _travelerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        flat: true,
        anchor: const Offset(0.5, 0.5),
        rotation: 0,
        infoWindow: InfoWindow(
          title: widget.travelerName,
          snippet: 'On the way',
        ),
      ),
    };

    // Add destination marker if available
    if (_destinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon:
              _destinationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationName ?? 'Drop-off point',
          ),
        ),
      );

      // Calculate route and ETA
      if (!_isCalculatingRoute) {
        _isCalculatingRoute = true;
        await _calculateRouteAndETA();
        _isCalculatingRoute = false;
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _calculateRouteAndETA() async {
    if (_travelerLocation == null || _destinationLocation == null) return;

    try {
      // Get distance and duration
      final distanceResult = await _distanceService.calculateDistance(
        originLat: _travelerLocation!.latitude,
        originLng: _travelerLocation!.longitude,
        destLat: _destinationLocation!.latitude,
        destLng: _destinationLocation!.longitude,
      );

      if (distanceResult.success) {
        setState(() {
          _distanceKm = distanceResult.distanceInKm;
          _durationMinutes = distanceResult.durationInMinutes;
        });
      }

      // Get route polyline
      final routePoints = await _distanceService.getRoutePolyline(
        originLat: _travelerLocation!.latitude,
        originLng: _travelerLocation!.longitude,
        destLat: _destinationLocation!.latitude,
        destLng: _destinationLocation!.longitude,
      );

      if (mounted && routePoints.isNotEmpty) {
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: AppConstants.primaryColor,
              width: 5,
              patterns: [], // Solid line
            ),
          };
        });
      }
    } catch (e) {
      print('Error calculating route: $e');
    }
  }

  void _fitMapToBounds() {
    if (_mapController == null) return;

    if (_travelerLocation != null && _destinationLocation != null) {
      // Create bounds that include both points
      final bounds = LatLngBounds(
        southwest: LatLng(
          _travelerLocation!.latitude < _destinationLocation!.latitude
              ? _travelerLocation!.latitude
              : _destinationLocation!.latitude,
          _travelerLocation!.longitude < _destinationLocation!.longitude
              ? _travelerLocation!.longitude
              : _destinationLocation!.longitude,
        ),
        northeast: LatLng(
          _travelerLocation!.latitude > _destinationLocation!.latitude
              ? _travelerLocation!.latitude
              : _destinationLocation!.latitude,
          _travelerLocation!.longitude > _destinationLocation!.longitude
              ? _travelerLocation!.longitude
              : _destinationLocation!.longitude,
        ),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else if (_travelerLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_travelerLocation!, 15),
      );
    }
  }

  String _formatETA() {
    if (_durationMinutes < 1) {
      return 'Arriving now';
    } else if (_durationMinutes < 60) {
      return '${_durationMinutes.round()} min';
    } else {
      final hours = _durationMinutes ~/ 60;
      final mins = (_durationMinutes % 60).round();
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Google Map
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16 * scaleFactor,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = '';
                        });
                        _loadDestinationAndLocation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GoogleMap(
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              initialCameraPosition: CameraPosition(
                target: _travelerLocation ?? const LatLng(10.7202, 122.5621),
                zoom: 14,
              ),
              markers: _markers,
              polylines: _polylines,
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              padding: EdgeInsets.only(bottom: 200 * scaleFactor),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _fitMapToBounds();
              },
            ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ETA Card at top
          if (_durationMinutes > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 70,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scaleFactor,
                  vertical: 12 * scaleFactor,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12 * scaleFactor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8 * scaleFactor),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8 * scaleFactor),
                      ),
                      child: Icon(
                        Icons.access_time_filled,
                        color: Colors.green[700],
                        size: 20 * scaleFactor,
                      ),
                    ),
                    SizedBox(width: 12 * scaleFactor),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatETA(),
                            style: TextStyle(
                              fontSize: 18 * scaleFactor,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '${_distanceKm.toStringAsFixed(1)} km away',
                            style: TextStyle(
                              fontSize: 12 * scaleFactor,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Recenter button
          Positioned(
            bottom: 220 * scaleFactor,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.my_location, color: AppConstants.primaryColor),
                onPressed: _fitMapToBounds,
              ),
            ),
          ),

          // Status card at bottom (Uber-style)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24 * scaleFactor),
                  topRight: Radius.circular(24 * scaleFactor),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: EdgeInsets.only(top: 12 * scaleFactor),
                    width: 40 * scaleFactor,
                    height: 4 * scaleFactor,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2 * scaleFactor),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(20 * scaleFactor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status header with ETA
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _durationMinutes > 0
                                        ? 'Arriving in ${_formatETA()}'
                                        : 'On the way',
                                    style: TextStyle(
                                      fontSize: 20 * scaleFactor,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4 * scaleFactor),
                                  Text(
                                    _destinationName != null
                                        ? 'Heading to $_destinationName'
                                        : 'Traveler is on the way',
                                    style: TextStyle(
                                      fontSize: 14 * scaleFactor,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (_durationMinutes > 0)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16 * scaleFactor,
                                  vertical: 8 * scaleFactor,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor,
                                  borderRadius: BorderRadius.circular(
                                    20 * scaleFactor,
                                  ),
                                ),
                                child: Text(
                                  _formatETA(),
                                  style: TextStyle(
                                    fontSize: 16 * scaleFactor,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: 20 * scaleFactor),

                        // Traveler info card
                        Container(
                          padding: EdgeInsets.all(16 * scaleFactor),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(
                              16 * scaleFactor,
                            ),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              // Traveler avatar
                              Container(
                                width: 50 * scaleFactor,
                                height: 50 * scaleFactor,
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    12 * scaleFactor,
                                  ),
                                ),
                                child: Icon(
                                  Icons.local_shipping,
                                  color: AppConstants.primaryColor,
                                  size: 28 * scaleFactor,
                                ),
                              ),
                              SizedBox(width: 14 * scaleFactor),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.travelerName,
                                      style: TextStyle(
                                        fontSize: 16 * scaleFactor,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4 * scaleFactor),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8 * scaleFactor,
                                          height: 8 * scaleFactor,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 6 * scaleFactor),
                                        Text(
                                          widget.status,
                                          style: TextStyle(
                                            fontSize: 13 * scaleFactor,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Service type badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10 * scaleFactor,
                                  vertical: 6 * scaleFactor,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.serviceType == 'Pabakal'
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    8 * scaleFactor,
                                  ),
                                ),
                                child: Text(
                                  widget.serviceType,
                                  style: TextStyle(
                                    fontSize: 12 * scaleFactor,
                                    fontWeight: FontWeight.w600,
                                    color: widget.serviceType == 'Pabakal'
                                        ? Colors.blue[700]
                                        : Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16 * scaleFactor),

                        // Info banner
                        Container(
                          padding: EdgeInsets.all(12 * scaleFactor),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18 * scaleFactor,
                                color: Colors.blue[700],
                              ),
                              SizedBox(width: 10 * scaleFactor),
                              Expanded(
                                child: Text(
                                  'Location updates in real-time',
                                  style: TextStyle(
                                    fontSize: 13 * scaleFactor,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
