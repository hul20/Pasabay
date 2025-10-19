import 'package:flutter/material.dart';
import '../../models/verification_request.dart';
import '../../utils/constants.dart';

class VerificationCard extends StatelessWidget {
  final VerificationRequest request;
  final VoidCallback onTap;

  const VerificationCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Traveler info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.travelerName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          request.travelerEmail,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppConstants.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: request.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: request.status.color),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          request.status.icon,
                          size: 16,
                          color: request.status.color,
                        ),
                        SizedBox(width: 6),
                        Text(
                          request.status.displayName,
                          style: TextStyle(
                            color: request.status.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Documents info
              Row(
                children: [
                  Icon(
                    Icons.attachment,
                    size: 16,
                    color: AppConstants.textSecondaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${request.documents.length} document${request.documents.length != 1 ? 's' : ''} submitted',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Time info
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppConstants.textSecondaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Submitted ${request.timeElapsed}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
                ],
              ),

              // Verifier info (if assigned)
              if (request.verifierName != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: AppConstants.textSecondaryColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Reviewed by ${request.verifierName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],

              // Action button
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: Icon(Icons.arrow_forward),
                  label: Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
