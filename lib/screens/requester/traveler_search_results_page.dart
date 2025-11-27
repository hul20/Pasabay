import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trip.dart';
import '../../models/traveler_statistics.dart';
import '../../services/request_service.dart';
import '../../services/traveler_stats_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'traveler_detail_page.dart';

class TravelerSearchResultsPage extends StatefulWidget {
  final List<Trip> trips;
  final String departureLocation;
  final String destinationLocation;

  const TravelerSearchResultsPage({
    super.key,
    required this.trips,
    required this.departureLocation,
    required this.destinationLocation,
  });

  @override
  State<TravelerSearchResultsPage> createState() =>
      _TravelerSearchResultsPageState();
}

class _TravelerSearchResultsPageState extends State<TravelerSearchResultsPage> {
  final RequestService _requestService = RequestService();
  final TravelerStatsService _statsService = TravelerStatsService();
  Map<String, Map<String, dynamic>> _travelersInfo = {};
  Map<String, TravelerStatistics?> _travelersStats = {};
  Map<String, List<TravelerBadge>> _travelersBadges = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTravelersInfo();
  }

  Future<void> _loadTravelersInfo() async {
    setState(() => _isLoading = true);

    try {
      for (var trip in widget.trips) {
        print('🔍 Loading traveler info for: ${trip.travelerId}');

        // Load basic traveler info
        final travelerInfo = await _requestService.getTravelerInfo(
          trip.travelerId,
        );
        if (travelerInfo != null) {
          print(
            '✅ Got traveler info: ${travelerInfo['first_name']} ${travelerInfo['last_name']}',
          );
          _travelersInfo[trip.travelerId] = travelerInfo;
        } else {
          print('❌ No traveler info found for: ${trip.travelerId}');
        }

        // Load traveler statistics
        try {
          final stats = await _statsService.getTravelerStatistics(
            trip.travelerId,
          );
          _travelersStats[trip.travelerId] = stats;
          print('✅ Got traveler stats: ${stats?.averageRating ?? 0.0}');
        } catch (e) {
          print('⚠️ No stats found for traveler: ${trip.travelerId}');
          _travelersStats[trip.travelerId] = null;
        }

        // Load traveler badges
        try {
          final badges = await _statsService.getTravelerBadges(trip.travelerId);
          _travelersBadges[trip.travelerId] = badges;
          print('✅ Got ${badges.length} badges');
        } catch (e) {
          print('⚠️ No badges found for traveler: ${trip.travelerId}');
          _travelersBadges[trip.travelerId] = [];
        }
      }
    } catch (e) {
      print('❌ Error loading travelers info: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Available Travelers',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18 * scaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : widget.trips.isEmpty
          ? _buildEmptyState(scaleFactor)
          : Column(
              children: [
                // Route summary
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16 * scaleFactor),
                  color: Color(0xFF00B4D8).withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(
                        Icons.route,
                        color: Color(0xFF00B4D8),
                        size: 24 * scaleFactor,
                      ),
                      SizedBox(width: 12 * scaleFactor),
                      Expanded(
                        child: Text(
                          '${widget.departureLocation} → ${widget.destinationLocation}',
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * scaleFactor,
                          vertical: 6 * scaleFactor,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF00B4D8),
                          borderRadius: BorderRadius.circular(20 * scaleFactor),
                        ),
                        child: Text(
                          '${widget.trips.length} found',
                          style: TextStyle(
                            fontSize: 13 * scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Results list
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16 * scaleFactor),
                    itemCount: widget.trips.length,
                    itemBuilder: (context, index) {
                      final trip = widget.trips[index];
                      final travelerInfo = _travelersInfo[trip.travelerId];
                      final travelerStats = _travelersStats[trip.travelerId];
                      final travelerBadges =
                          _travelersBadges[trip.travelerId] ?? [];

                      return _buildTripCard(
                        trip,
                        travelerInfo,
                        travelerStats,
                        travelerBadges,
                        scaleFactor,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(double scaleFactor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32 * scaleFactor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80 * scaleFactor,
              color: Colors.grey[300],
            ),
            SizedBox(height: 24 * scaleFactor),
            Text(
              'No travelers found',
              style: TextStyle(
                fontSize: 20 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8 * scaleFactor),
            Text(
              'Try different locations or check back later',
              style: TextStyle(
                fontSize: 14 * scaleFactor,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(
    Trip trip,
    Map<String, dynamic>? travelerInfo,
    TravelerStatistics? travelerStats,
    List<TravelerBadge> travelerBadges,
    double scaleFactor,
  ) {
    final travelerName = travelerInfo != null
        ? '${travelerInfo['first_name']} ${travelerInfo['last_name']}'
        : 'Unknown Traveler';

    final profileImageUrl = travelerInfo?['profile_image_url'];
    final rating = travelerStats?.averageRating ?? 0.0;
    final totalRatings = travelerStats?.totalRatings ?? 0;
    final hasVerifiedBadge = travelerBadges.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 16 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scaleFactor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Don't allow navigation if traveler info not loaded
            if (travelerInfo == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Loading traveler information...'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TravelerDetailPage(trip: trip, travelerInfo: travelerInfo),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16 * scaleFactor),
          child: Padding(
            padding: EdgeInsets.all(16 * scaleFactor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Traveler info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24 * scaleFactor,
                      backgroundColor: Color(0xFF00B4D8),
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl == null
                          ? Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28 * scaleFactor,
                            )
                          : null,
                    ),
                    SizedBox(width: 12 * scaleFactor),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            travelerName,
                            style: TextStyle(
                              fontSize: 16 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2 * scaleFactor),
                          Row(
                            children: [
                              if (rating > 0) ...[
                                Icon(
                                  Icons.star,
                                  size: 14 * scaleFactor,
                                  color: Colors.amber,
                                ),
                                SizedBox(width: 4 * scaleFactor),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 13 * scaleFactor,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (totalRatings > 0) ...[
                                  Text(
                                    ' (${totalRatings})',
                                    style: TextStyle(
                                      fontSize: 11 * scaleFactor,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                                SizedBox(width: 12 * scaleFactor),
                              ] else ...[
                                Text(
                                  'No ratings yet',
                                  style: TextStyle(
                                    fontSize: 12 * scaleFactor,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                SizedBox(width: 12 * scaleFactor),
                              ],
                              if (hasVerifiedBadge) ...[
                                Icon(
                                  Icons.verified,
                                  size: 14 * scaleFactor,
                                  color: Color(0xFF00B4D8),
                                ),
                                SizedBox(width: 4 * scaleFactor),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 13 * scaleFactor,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              // Show first badge emoji if available
                              if (travelerBadges.isNotEmpty) ...[
                                SizedBox(width: 8 * scaleFactor),
                                Text(
                                  travelerBadges.first.icon,
                                  style: TextStyle(fontSize: 14 * scaleFactor),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16 * scaleFactor,
                      color: Colors.grey[400],
                    ),
                  ],
                ),

                // Traveler statistics (if available)
                if (travelerStats != null &&
                    (travelerStats.successfulTrips > 0 ||
                        travelerStats.reliabilityRate > 0)) ...[
                  SizedBox(height: 12 * scaleFactor),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * scaleFactor,
                      vertical: 8 * scaleFactor,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8 * scaleFactor),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (travelerStats.successfulTrips > 0) ...[
                          Column(
                            children: [
                              Text(
                                '${travelerStats.successfulTrips}',
                                style: TextStyle(
                                  fontSize: 16 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                'Trips',
                                style: TextStyle(
                                  fontSize: 11 * scaleFactor,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (travelerStats.reliabilityRate > 0) ...[
                          Container(
                            height: 30 * scaleFactor,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          Column(
                            children: [
                              Text(
                                '${travelerStats.reliabilityRate.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 16 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                'Reliability',
                                style: TextStyle(
                                  fontSize: 11 * scaleFactor,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 16 * scaleFactor),
                Divider(height: 1, color: Colors.grey[200]),
                SizedBox(height: 16 * scaleFactor),

                // Trip details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        Icons.calendar_today,
                        'Date',
                        DateFormat('MMM dd').format(trip.departureDate),
                        scaleFactor,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.access_time,
                        'Time',
                        trip.departureTime,
                        scaleFactor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12 * scaleFactor),

                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        Icons.event_seat,
                        'Capacity',
                        '${trip.availableCapacity + trip.currentRequests} slots (${trip.availableCapacity} available)',
                        scaleFactor,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.info_outline,
                        'Status',
                        trip.tripStatus,
                        scaleFactor,
                      ),
                    ),
                  ],
                ),

                if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                  SizedBox(height: 12 * scaleFactor),
                  Container(
                    padding: EdgeInsets.all(12 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8 * scaleFactor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16 * scaleFactor,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8 * scaleFactor),
                        Expanded(
                          child: Text(
                            trip.notes!,
                            style: TextStyle(
                              fontSize: 13 * scaleFactor,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value,
    double scaleFactor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16 * scaleFactor, color: Color(0xFF00B4D8)),
        SizedBox(width: 8 * scaleFactor),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11 * scaleFactor,
                color: Colors.grey[500],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
