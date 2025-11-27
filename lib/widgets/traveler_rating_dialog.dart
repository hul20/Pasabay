import 'package:flutter/material.dart';
import '../services/traveler_stats_service.dart';
import '../utils/constants.dart';

/// Modern rating dialog for requesters to rate travelers after delivery
class TravelerRatingDialog extends StatefulWidget {
  final String travelerId;
  final String travelerName;
  final String tripId;
  final String requestId;
  final String serviceType; // 'Pabakal' or 'Pasabay'

  const TravelerRatingDialog({
    Key? key,
    required this.travelerId,
    required this.travelerName,
    required this.tripId,
    required this.requestId,
    required this.serviceType,
  }) : super(key: key);

  @override
  State<TravelerRatingDialog> createState() => _TravelerRatingDialogState();
}

class _TravelerRatingDialogState extends State<TravelerRatingDialog>
    with SingleTickerProviderStateMixin {
  final TravelerStatsService _statsService = TravelerStatsService();
  final TextEditingController _reviewController = TextEditingController();

  double _rating = 0.0;
  bool _isFastDelivery = false;
  bool _isGoodShopper = false;
  bool _isFragileHandler = false;
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating < 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _statsService.submitRating(
        travelerId: widget.travelerId,
        tripId: widget.tripId,
        requestId: widget.requestId,
        rating: _rating,
        reviewText: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        isFastDelivery: _isFastDelivery,
        isGoodShopper: _isGoodShopper && widget.serviceType == 'Pabakal',
        isFragileHandler: _isFragileHandler,
      );

      if (success && mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thank you for your feedback! ⭐'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        throw 'Failed to submit rating';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: 650),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Success Icon
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Title
                  Text(
                    'AWESOME!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'You rated ${widget.travelerName}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 24),

                  // Star Rating
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _rating = (index + 1).toDouble();
                                });
                              },
                        child: Icon(
                          index < _rating ? Icons.star : Icons.star,
                          size: 44,
                          color: index < _rating
                              ? Colors.amber
                              : Colors.grey[400],
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    SizedBox(height: 8),
                    Text(
                      '${_rating.toInt()} star${_rating > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                  SizedBox(height: 24),

                  // Review Text Field
                  TextField(
                    controller: _reviewController,
                    enabled: !_isSubmitting,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText:
                          'Say something about ${widget.travelerName}\'s service?',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppConstants.primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Badge Feedback Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Help them earn badges',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 12),

                        // Fast Delivery Badge
                        _buildBadgeFeedback(
                          icon: '⚡',
                          label: 'On-time delivery',
                          description: 'Delivered within estimated time',
                          value: _isFastDelivery,
                          onChanged: _isSubmitting
                              ? null
                              : (value) {
                                  setState(() {
                                    _isFastDelivery = value;
                                  });
                                },
                        ),

                        // Good Shopper Badge (only for Pabakal)
                        if (widget.serviceType == 'Pabakal') ...[
                          SizedBox(height: 8),
                          _buildBadgeFeedback(
                            icon: '🛍️',
                            label: 'Great shopping skills',
                            description: 'Picked quality items correctly',
                            value: _isGoodShopper,
                            onChanged: _isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      _isGoodShopper = value;
                                    });
                                  },
                          ),
                        ],

                        // Gentle Handler Badge
                        SizedBox(height: 8),
                        _buildBadgeFeedback(
                          icon: '📦',
                          label: 'Handled with care',
                          description: 'Item arrived in perfect condition',
                          value: _isFragileHandler,
                          onChanged: _isSubmitting
                              ? null
                              : (value) {
                                  setState(() {
                                    _isFragileHandler = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Skip Button
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context, false),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeFeedback({
    required String icon,
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 4),
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: value,
                onChanged: onChanged == null
                    ? null
                    : (bool? newValue) {
                        if (newValue != null) {
                          onChanged(newValue);
                        }
                      },
                activeColor: AppConstants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
