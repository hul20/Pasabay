import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/verification_service.dart';
import '../../models/verification_request.dart';
import '../../models/verification_status.dart';
import '../../utils/constants.dart';
import '../widgets/verification_card.dart';
import '../widgets/statistics_card.dart';
import 'verification_detail_screen.dart';

class VerifierDashboardScreen extends StatefulWidget {
  const VerifierDashboardScreen({super.key});

  @override
  State<VerifierDashboardScreen> createState() =>
      _VerifierDashboardScreenState();
}

class _VerifierDashboardScreenState extends State<VerifierDashboardScreen> {
  final _authService = AuthService();
  final _verificationService = VerificationService();

  VerificationStatus? _selectedStatus;
  List<VerificationRequest> _requests = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  String? _verifierName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get verifier profile
      final userId = _authService.currentUserId;
      if (userId != null) {
        final profile = await _authService.getUserProfile(userId);
        _verifierName = profile?['email'] ?? 'Verifier';
      }

      // Load requests and statistics
      final requests = await _verificationService.getAllRequests(
        status: _selectedStatus,
      );
      final stats = await _verificationService.getStatistics();

      setState(() {
        _requests = requests;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterByStatus(VerificationStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadData();
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.verified_user, color: AppConstants.primaryColor),
            SizedBox(width: 12),
            Text(
              'Verifier Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimaryColor,
              ),
            ),
          ],
        ),
        actions: [
          // Verifier name
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                _verifierName ?? 'Loading...',
                style: TextStyle(
                  color: AppConstants.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          // Sign out button
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _handleSignOut,
            tooltip: 'Sign Out',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Section
                  Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildStatistics(),
                  SizedBox(height: 32),

                  // Filter Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Verification Requests',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimaryColor,
                        ),
                      ),
                      DropdownButton<VerificationStatus?>(
                        value: _selectedStatus,
                        hint: Text('All Requests'),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All Requests'),
                          ),
                          ...VerificationStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Icon(
                                    status.icon,
                                    size: 16,
                                    color: status.color,
                                  ),
                                  SizedBox(width: 8),
                                  Text(status.displayName),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: _filterByStatus,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Requests List
                  if (_requests.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No verification requests found',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppConstants.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._requests.map((request) {
                      return VerificationCard(
                        request: request,
                        onTap: () => _navigateToDetail(request),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildStatistics() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        StatisticsCard(
          title: 'Total Requests',
          value: _statistics['total'] ?? 0,
          icon: Icons.description,
          color: Colors.blue,
        ),
        StatisticsCard(
          title: 'Pending',
          value: _statistics['pending'] ?? 0,
          icon: Icons.schedule,
          color: Colors.orange,
        ),
        StatisticsCard(
          title: 'Under Review',
          value: _statistics['under_review'] ?? 0,
          icon: Icons.visibility,
          color: Colors.blue,
        ),
        StatisticsCard(
          title: 'Approved',
          value: _statistics['approved'] ?? 0,
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        StatisticsCard(
          title: 'Rejected',
          value: _statistics['rejected'] ?? 0,
          icon: Icons.cancel,
          color: Colors.red,
        ),
      ],
    );
  }

  void _navigateToDetail(VerificationRequest request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationDetailScreen(request: request),
      ),
    );

    // Refresh if action was taken
    if (result == true) {
      _loadData();
    }
  }
}
