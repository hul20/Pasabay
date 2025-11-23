import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/request.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class RequestStatusPage extends StatelessWidget {
  final ServiceRequest request;
  final Map<String, dynamic>? travelerInfo;

  const RequestStatusPage({
    super.key,
    required this.request,
    this.travelerInfo,
  });

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
      body: SingleChildScrollView(
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
                request.status,
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
              '${request.serviceType} Request',
              style: TextStyle(
                fontSize: 24 * scaleFactor,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            SizedBox(height: 8 * scaleFactor),
            
            Text(
              'Created ${request.formattedCreatedAt}',
              style: TextStyle(
                fontSize: 13 * scaleFactor,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 24 * scaleFactor),
            
            // Traveler Info if available
            if (travelerInfo != null) ...[
              _buildInfoCard(
                'Traveler',
                '${travelerInfo!['first_name']} ${travelerInfo!['last_name']}',
                Icons.person,
                scaleFactor,
              ),
              SizedBox(height: 12 * scaleFactor),
            ],
            
            // Service Details
            if (request.serviceType == 'Pabakal') ...[
              _buildInfoCard(
                'Product',
                request.productName ?? 'N/A',
                Icons.shopping_bag,
                scaleFactor,
              ),
              SizedBox(height: 12 * scaleFactor),
              _buildInfoCard(
                'Store',
                '${request.storeName ?? 'N/A'}\n${request.storeLocation ?? ''}',
                Icons.store,
                scaleFactor,
              ),
              SizedBox(height: 12 * scaleFactor),
              _buildInfoCard(
                'Cost',
                '₱${request.productCost?.toStringAsFixed(2) ?? '0.00'}',
                Icons.attach_money,
                scaleFactor,
              ),
            ] else ...[
              _buildInfoCard(
                'Recipient',
                request.recipientName ?? 'N/A',
                Icons.person_outline,
                scaleFactor,
              ),
              SizedBox(height: 12 * scaleFactor),
              _buildInfoCard(
                'Delivery Address',
                request.dropoffLocation ?? 'N/A',
                Icons.location_on,
                scaleFactor,
              ),
            ],
            
            SizedBox(height: 12 * scaleFactor),
            
            // Payment Info
            _buildInfoCard(
              'Service Fee',
              '₱${request.serviceFee.toStringAsFixed(2)}',
              Icons.payment,
              scaleFactor,
            ),
            
            SizedBox(height: 12 * scaleFactor),
            
            _buildInfoCard(
              'Total Amount',
              '₱${request.totalAmount.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              scaleFactor,
            ),
            
            // Rejection reason if rejected
            if (request.status == 'Rejected' && request.rejectionReason != null) ...[
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
                        Icon(Icons.info_outline, color: Colors.red, size: 20 * scaleFactor),
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
                      request.rejectionReason!,
                      style: TextStyle(
                        fontSize: 14 * scaleFactor,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (request.status) {
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

  Widget _buildInfoCard(String label, String value, IconData icon, double scaleFactor) {
    return Container(
      padding: EdgeInsets.all(16 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Color(0xFF00B4D8),
            size: 24 * scaleFactor,
          ),
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

