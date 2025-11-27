import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/request.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../services/messaging_service.dart';
import '../../services/request_service.dart';
import '../../services/traveler_stats_service.dart';
import '../../widgets/traveler_rating_dialog.dart';

class RequestStatusPage extends StatefulWidget {
  final ServiceRequest request;
  final Map<String, dynamic>? travelerInfo;

  const RequestStatusPage({
    super.key,
    required this.request,
    this.travelerInfo,
  });

  @override
  State<RequestStatusPage> createState() => _RequestStatusPageState();
}

class _RequestStatusPageState extends State<RequestStatusPage> {
  late ServiceRequest _request;
  final _supabase = Supabase.instance.client;
  final MessagingService _messagingService = MessagingService();
  final RequestService _requestService = RequestService();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  Future<void> _handleItemReceived() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Item Received',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Have you received the item/s from the traveler? This will mark the transaction as completed.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close modal
                      await _confirmItemReceived();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Confirm',
                      style: TextStyle(color: Colors.white),
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

  Future<void> _confirmItemReceived() async {
    setState(() => _isUpdating = true);

    try {
      // Update request status
      await _supabase
          .from('service_requests')
          .update({
            'status': 'Completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _request.id);

      // Complete payment - transfer money to traveler
      print('💰 Processing payment transfer...');
      final paymentResult = await _supabase.rpc(
        'complete_request_payment',
        params: {'p_request_id': _request.id},
      );

      if (paymentResult['success'] == true) {
        print('✅ Payment completed: ₱${paymentResult['amount']}');
        // System message is automatically sent by the database function
      } else {
        print('⚠️ Payment completion warning: ${paymentResult['error']}');
      }

      // Get conversation ID to send message
      final conversationResponse = await _supabase
          .from('conversations')
          .select('id')
          .eq('request_id', _request.id)
          .maybeSingle();

      if (conversationResponse != null) {
        await _messagingService.sendMessage(
          conversationId: conversationResponse['id'],
          messageText: 'Transaction completed! Item received. ✅',
        );
      }

      if (mounted) {
        setState(() {
          _request = _request.copyWith(status: 'Completed');
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Show rating dialog after a brief delay
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            _showRatingDialog();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showRatingDialog() async {
    // Check if already rated
    final statsService = TravelerStatsService();
    final hasRated = await statsService.hasRatedRequest(_request.id);

    if (hasRated) {
      print('ℹ️ Request already rated, skipping dialog');
      return;
    }

    if (!mounted) return;

    // Get traveler info
    final travelerInfo = await _requestService.getTravelerInfo(
      _request.travelerId,
    );
    final travelerName = travelerInfo != null
        ? '${travelerInfo['first_name']} ${travelerInfo['last_name']}'
        : widget.travelerInfo != null
        ? '${widget.travelerInfo!['first_name']} ${widget.travelerInfo!['last_name']}'
        : 'Traveler';

    if (!mounted) return;

    // Show rating dialog
    final rated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TravelerRatingDialog(
        travelerId: _request.travelerId,
        travelerName: travelerName,
        tripId: _request.tripId,
        requestId: _request.id,
        serviceType: _request.serviceType,
      ),
    );

    if (rated == true) {
      print('✅ Rating submitted successfully');
    } else {
      print('ℹ️ Rating skipped by user');
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
          'Request Status',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18 * scaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isUpdating
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(18 * scaleFactor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * scaleFactor,
                      vertical: 8 * scaleFactor,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20 * scaleFactor),
                    ),
                    child: Text(
                      _request.status,
                      style: TextStyle(
                        fontSize: 14 * scaleFactor,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),

                  SizedBox(height: 24 * scaleFactor),

                  // Service Type
                  Text(
                    '${_request.serviceType} Request',
                    style: TextStyle(
                      fontSize: 24 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: 8 * scaleFactor),

                  Text(
                    'Created ${_request.formattedCreatedAt}',
                    style: TextStyle(
                      fontSize: 13 * scaleFactor,
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(height: 24 * scaleFactor),

                  // Traveler Info if available
                  if (widget.travelerInfo != null) ...[
                    _buildInfoCard(
                      'Traveler',
                      '${widget.travelerInfo!['first_name']} ${widget.travelerInfo!['last_name']}',
                      Icons.person,
                      scaleFactor,
                    ),
                    SizedBox(height: 12 * scaleFactor),
                  ],

                  // Service Details
                  if (_request.serviceType == 'Pabakal') ...[
                    _buildInfoCard(
                      'Product',
                      _request.productName ?? 'N/A',
                      Icons.shopping_bag,
                      scaleFactor,
                    ),
                    SizedBox(height: 12 * scaleFactor),
                    _buildInfoCard(
                      'Store',
                      '${_request.storeName ?? 'N/A'}\n${_request.storeLocation ?? ''}',
                      Icons.store,
                      scaleFactor,
                    ),
                    SizedBox(height: 12 * scaleFactor),
                    _buildInfoCard(
                      'Cost',
                      '₱${_request.productCost?.toStringAsFixed(2) ?? '0.00'}',
                      Icons.attach_money,
                      scaleFactor,
                    ),
                  ] else ...[
                    _buildInfoCard(
                      'Recipient',
                      _request.recipientName ?? 'N/A',
                      Icons.person_outline,
                      scaleFactor,
                    ),
                    SizedBox(height: 12 * scaleFactor),
                    _buildInfoCard(
                      'Delivery Address',
                      _request.dropoffLocation ?? 'N/A',
                      Icons.location_on,
                      scaleFactor,
                    ),
                  ],

                  SizedBox(height: 12 * scaleFactor),

                  // Payment Info
                  _buildInfoCard(
                    'Service Fee',
                    '₱${_request.serviceFee.toStringAsFixed(2)}',
                    Icons.payment,
                    scaleFactor,
                  ),

                  SizedBox(height: 12 * scaleFactor),

                  _buildInfoCard(
                    'Total Amount',
                    '₱${_request.totalAmount.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    scaleFactor,
                  ),

                  // Rejection reason if rejected
                  if (_request.status == 'Rejected' &&
                      _request.rejectionReason != null) ...[
                    SizedBox(height: 24 * scaleFactor),
                    Container(
                      padding: EdgeInsets.all(16 * scaleFactor),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.red,
                                size: 20 * scaleFactor,
                              ),
                              SizedBox(width: 8 * scaleFactor),
                              Text(
                                'Rejection Reason',
                                style: TextStyle(
                                  fontSize: 15 * scaleFactor,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8 * scaleFactor),
                          Text(
                            _request.rejectionReason!,
                            style: TextStyle(
                              fontSize: 14 * scaleFactor,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Item Received Button
                  if (_request.status == 'Accepted' ||
                      _request.status == 'Order Sent') ...[
                    SizedBox(height: 32 * scaleFactor),
                    SizedBox(
                      width: double.infinity,
                      height: 50 * scaleFactor,
                      child: ElevatedButton(
                        onPressed: _handleItemReceived,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
                          ),
                        ),
                        child: Text(
                          'Item Received',
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Color _getStatusColor() {
    switch (_request.status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    double scaleFactor,
  ) {
    return Container(
      padding: EdgeInsets.all(16 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF00B4D8), size: 24 * scaleFactor),
          SizedBox(width: 16 * scaleFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13 * scaleFactor,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4 * scaleFactor),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
