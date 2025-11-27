import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/request.dart';
import '../services/messaging_service.dart';
import '../services/request_service.dart';
import '../services/location_tracking_service.dart';
import '../services/traveler_stats_service.dart';
import '../widgets/traveler_rating_dialog.dart';
import 'tracking_map_page.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/supabase_service.dart';

class ChatDetailPage extends StatefulWidget {
  final Conversation conversation;

  const ChatDetailPage({super.key, required this.conversation});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagingService _messagingService = MessagingService();
  final RequestService _requestService = RequestService();
  final SupabaseService _supabaseService = SupabaseService();
  final LocationTrackingService _trackingService = LocationTrackingService();
  final _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  List<Message> _messages = [];
  ServiceRequest? _serviceRequest;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _requestChannel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadRequestDetails();
    _subscribeToMessages();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _trackingService.stopTracking(); // Stop tracking when chat is closed
    if (_messagesChannel != null) {
      _messagingService.unsubscribe(_messagesChannel!);
    }
    if (_requestChannel != null) {
      _supabase.removeChannel(_requestChannel!);
    }
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _messagingService.getMessages(
        widget.conversation.id,
      );

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToMessages() {
    _messagesChannel = _messagingService.subscribeToMessages(
      widget.conversation.id,
      (newMessage) {
        if (mounted) {
          setState(() {
            _messages.add(newMessage);
          });
          _scrollToBottom();
          _markAsRead();
        }
      },
    );
  }

  void _subscribeToRequestChanges() {
    if (_serviceRequest == null) return;

    _requestChannel = _supabase
        .channel('request:${_serviceRequest!.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'service_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _serviceRequest!.id,
          ),
          callback: (payload) {
            if (mounted) {
              print('🔄 Request status changed: ${payload.newRecord}');
              _loadRequestDetails(); // Reload request details when status changes
            }
          },
        )
        .subscribe();
  }

  Future<void> _markAsRead() async {
    await _messagingService.markMessagesAsRead(widget.conversation.id);
  }

  List<String> _getProgressSteps(String serviceType) {
    if (serviceType == 'Pabakal') {
      return [
        'Order Accepted',
        'Item Bought',
        'On the Way',
        'Dropped Off',
        'Completed',
      ];
    } else {
      return [
        'Order Accepted',
        'Picked Up',
        'On the Way',
        'Dropped Off',
        'Completed',
      ];
    }
  }

  int _getCurrentStepIndex(String status, String serviceType) {
    final Map<String, int> pabakalSteps = {
      'Accepted': 0,
      'Item Bought': 1,
      'On the Way': 2,
      'Dropped Off': 3,
      'Order Sent': 3,
      'Completed': 4,
    };

    final Map<String, int> pasabaySteps = {
      'Accepted': 0,
      'Picked Up': 1,
      'On the Way': 2,
      'Dropped Off': 3,
      'Order Sent': 3,
      'Completed': 4,
    };

    if (serviceType == 'Pabakal') {
      return pabakalSteps[status] ?? 0;
    } else {
      return pasabaySteps[status] ?? 0;
    }
  }

  Widget _buildProgressBar(
    List<String> steps,
    int currentStep,
    double scaleFactor,
  ) {
    return Column(
      children: [
        // Progress dots and lines
        Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isEven) {
              // Dot
              int stepIndex = index ~/ 2;
              bool isCompleted = stepIndex <= currentStep;
              return Container(
                width: 20 * scaleFactor,
                height: 20 * scaleFactor,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Color(0xFF00B4D8) : Colors.grey[300],
                  border: Border.all(
                    color: isCompleted ? Color(0xFF00B4D8) : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        size: 12 * scaleFactor,
                        color: Colors.white,
                      )
                    : null,
              );
            } else {
              // Line
              int stepIndex = index ~/ 2;
              bool isCompleted = stepIndex < currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isCompleted ? Color(0xFF00B4D8) : Colors.grey[300],
                ),
              );
            }
          }),
        ),
        SizedBox(height: 6 * scaleFactor),
        // Step labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.asMap().entries.map((entry) {
            int stepIndex = entry.key;
            String label = entry.value;
            bool isCompleted = stepIndex <= currentStep;
            return Expanded(
              child: Text(
                label,
                textAlign: stepIndex == 0
                    ? TextAlign.start
                    : stepIndex == steps.length - 1
                    ? TextAlign.end
                    : TextAlign.center,
                style: TextStyle(
                  fontSize: 9 * scaleFactor,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                  color: isCompleted ? Color(0xFF00B4D8) : Colors.grey[600],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final success = await _messagingService.sendMessage(
        conversationId: widget.conversation.id,
        messageText: text,
      );

      if (success) {
        _messageController.clear();
        // Message will be added via real-time subscription
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _loadRequestDetails() async {
    try {
      final request = await _requestService.getRequestById(
        widget.conversation.requestId,
      );
      if (mounted) {
        setState(() {
          _serviceRequest = request;
        });

        // Subscribe to request changes after loading
        if (_requestChannel == null && request != null) {
          _subscribeToRequestChanges();
        }
      }
    } catch (e) {
      print('Error loading request details: $e');
    }
  }

  void _showRequestDetails() {
    if (_serviceRequest == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Request Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child:
                          (_serviceRequest!.photoUrls != null &&
                              _serviceRequest!.photoUrls!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _serviceRequest!.photoUrls!.first,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                        Text(
                                          'Failed to load image',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No image attached',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    _buildDetailRow(
                      'Service Type',
                      _serviceRequest!.serviceType,
                    ),
                    _buildDetailRow('Status', _serviceRequest!.status),
                    if (_serviceRequest!.serviceType == 'Pabakal') ...[
                      _buildDetailRow(
                        'Product',
                        _serviceRequest!.productName ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Store',
                        _serviceRequest!.storeName ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Cost',
                        '₱${_serviceRequest!.productCost?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                    ] else ...[
                      _buildDetailRow(
                        'Recipient',
                        _serviceRequest!.recipientName ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Description',
                        _serviceRequest!.packageDescription ?? 'N/A',
                      ),
                    ],
                    _buildDetailRow(
                      'Service Fee',
                      '₱${_serviceRequest!.serviceFee.toStringAsFixed(2)}',
                    ),
                    if (_serviceRequest!.notes != null &&
                        _serviceRequest!.notes!.isNotEmpty)
                      _buildDetailRow('Notes', _serviceRequest!.notes!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _handleOrderSent() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        XFile? proofImage;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Confirm Order Sent',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Please upload a photo proof that you have sent the item/s.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          setModalState(() {
                            proofImage = image;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: proofImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb
                                    ? Image.network(
                                        proofImage!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(proofImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Tap to take photo',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (proofImage == null || isSubmitting)
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              try {
                                // 1. Prepare file for upload
                                dynamic fileToUpload;
                                if (kIsWeb) {
                                  fileToUpload = await proofImage!
                                      .readAsBytes();
                                } else {
                                  fileToUpload = File(proofImage!.path);
                                }

                                // 2. Upload image
                                final imageUrl = await _supabaseService.uploadFile(
                                  'proof-images',
                                  'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                  fileToUpload,
                                );

                                // 3. Update request status
                                await _supabase
                                    .from('service_requests')
                                    .update({
                                      'status': 'Order Sent',
                                      'proof_image_url': imageUrl,
                                      'updated_at': DateTime.now()
                                          .toIso8601String(),
                                    })
                                    .eq('id', _serviceRequest!.id);

                                // 4. Send automated message with image marker
                                await _messagingService.sendMessage(
                                  conversationId: widget.conversation.id,
                                  messageText:
                                      'Order has been sent! 📦\n[IMAGE]$imageUrl',
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  setState(() {
                                    _serviceRequest = _serviceRequest!.copyWith(
                                      status: 'Order Sent',
                                      proofImageUrl: imageUrl,
                                    );
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Order marked as sent!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Confirm & Send',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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

  void _handleItemReceived() {
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
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      print('🔄 Updating request ${_serviceRequest!.id} to Completed');
      print('🔄 Current user: ${_supabase.auth.currentUser?.id}');
      print('🔄 Requester ID: ${_serviceRequest!.requesterId}');

      // Update request status without .single() to avoid RLS issues
      await _supabase
          .from('service_requests')
          .update({
            'status': 'Completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _serviceRequest!.id);

      print('✅ Request updated successfully');

      // Send automated message FIRST
      await _messagingService.sendMessage(
        conversationId: widget.conversation.id,
        messageText: 'Transaction completed! Item received. ✅',
      );

      // Complete payment - transfer money to traveler
      print('💰 Processing payment transfer...');
      print('💰 Request ID: ${_serviceRequest!.id}');

      try {
        final paymentResult = await _supabase.rpc(
          'complete_request_payment',
          params: {'p_request_id': _serviceRequest!.id},
        );

        print('💰 Payment result received: $paymentResult');

        if (paymentResult != null) {
          if (paymentResult['success'] == true) {
            print('✅ Payment completed: ₱${paymentResult['amount']}');
          } else {
            print('⚠️ Payment error: ${paymentResult['error']}');
            // Show payment error to user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Payment transfer issue: ${paymentResult['error']}',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
        } else {
          print('⚠️ Payment result is null');
        }
      } catch (paymentError) {
        print('❌ Payment transfer error: $paymentError');
        // Show error but don't stop the flow
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment transfer failed: $paymentError'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Update local state
        setState(() {
          _serviceRequest = _serviceRequest!.copyWith(status: 'Completed');
        });

        print('✅ Local state updated to: ${_serviceRequest!.status}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Show rating dialog after a brief delay
        Future.delayed(Duration(milliseconds: 1000), () {
          if (mounted) {
            _showRatingDialog();
          }
        });
      }
    } catch (e) {
      print('❌ Error confirming item received: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showRatingDialog() async {
    // Check if already rated
    final statsService = TravelerStatsService();
    final hasRated = await statsService.hasRatedRequest(_serviceRequest!.id);

    if (hasRated) {
      print('ℹ️ Request already rated, skipping dialog');
      return;
    }

    if (!mounted) return;

    // Get traveler info
    final travelerInfo = await _requestService.getTravelerInfo(
      _serviceRequest!.travelerId,
    );
    final travelerName = travelerInfo != null
        ? '${travelerInfo['first_name']} ${travelerInfo['last_name']}'
        : 'Traveler';

    if (!mounted) return;

    // Show rating dialog
    final rated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TravelerRatingDialog(
        travelerId: _serviceRequest!.travelerId,
        travelerName: travelerName,
        tripId: _serviceRequest!.tripId,
        requestId: _serviceRequest!.id,
        serviceType: _serviceRequest!.serviceType,
      ),
    );

    if (rated == true) {
      print('✅ Rating submitted successfully');
    } else {
      print('ℹ️ Rating skipped by user');
    }
  }

  String _getNextActionLabel() {
    if (_serviceRequest == null) return 'Update Status';

    final status = _serviceRequest!.status;
    final serviceType = _serviceRequest!.serviceType;

    if (status == 'Accepted') {
      return serviceType == 'Pabakal' ? 'Item Bought' : 'Picked Up';
    } else if (status == 'Item Bought' || status == 'Picked Up') {
      return 'On the Way';
    } else if (status == 'On the Way') {
      return 'Dropped Off';
    } else if (status == 'Dropped Off') {
      return 'Completed ✓';
    } else if (status == 'Order Sent') {
      return 'Completed ✓';
    } else {
      return 'Completed ✓';
    }
  }

  VoidCallback? _getNextActionForTraveler() {
    if (_serviceRequest == null) return null;

    final status = _serviceRequest!.status;

    if (status == 'Accepted') {
      return _handleItemBoughtOrPickedUp;
    } else if (status == 'Item Bought' || status == 'Picked Up') {
      return _handleOnTheWay;
    } else if (status == 'On the Way') {
      return _handleDroppedOff;
    } else if (status == 'Dropped Off' ||
        status == 'Order Sent' ||
        status == 'Completed') {
      return null; // Disabled
    }

    return null;
  }

  Future<void> _handleItemBoughtOrPickedUp() async {
    final serviceType = _serviceRequest!.serviceType;
    final newStatus = serviceType == 'Pabakal' ? 'Item Bought' : 'Picked Up';
    final title = serviceType == 'Pabakal'
        ? 'Confirm Item Bought'
        : 'Confirm Picked Up';
    final description = serviceType == 'Pabakal'
        ? 'Please upload a photo proof that you have bought the item.'
        : 'Please upload a photo proof that you have picked up the package.';
    final message = serviceType == 'Pabakal'
        ? 'Item has been bought! 🛍️'
        : 'Package has been picked up! 📦';

    await _showProofUploadModal(newStatus, title, description, message);
  }

  Future<void> _handleOnTheWay() async {
    await _updateTravelerStatus('On the Way', 'On the way to delivery! 🚗');

    // Start location tracking when traveler goes "On the Way"
    try {
      await _trackingService.startTracking(_serviceRequest!.id);
      print('✅ Location tracking started for request: ${_serviceRequest!.id}');

      // Send a message with tracking link
      await _messagingService.sendMessage(
        conversationId: widget.conversation.id,
        messageText:
            '📍 [TRACK_LOCATION] Tap here to track my live location in real-time!',
      );
    } on LocationPermissionException catch (e) {
      print('❌ Location permission error: $e');
      // Show dialog with option to open settings
      if (mounted) {
        _showLocationPermissionDialog(e.message, e.shouldOpenSettings);
      }
    } catch (e) {
      print('❌ Error starting location tracking: $e');
      // Show error but don't block the status update
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location tracking unavailable: $e'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showLocationPermissionDialog(String message, bool shouldOpenSettings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Location Required'),
          ],
        ),
        content: Text(
          '$message\n\nLocation tracking is essential for delivery updates. Please enable location services to continue.',
        ),
        actions: [
          if (shouldOpenSettings)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Retry permission check
              _handleOnTheWay();
            },
            child: Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDroppedOff() async {
    await _showProofUploadModal(
      'Dropped Off',
      'Confirm Drop Off',
      'Please upload a photo proof that you have dropped off the item/package.',
      'Item has been dropped off! 📍',
    );
  }

  Future<void> _showProofUploadModal(
    String newStatus,
    String title,
    String description,
    String successMessage,
  ) async {
    // Show modal to upload proof image
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        XFile? proofImage;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          setModalState(() {
                            proofImage = image;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: proofImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb
                                    ? Image.network(
                                        proofImage!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(proofImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Tap to take photo',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (proofImage == null || isSubmitting)
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              try {
                                // 1. Prepare file for upload
                                dynamic fileToUpload;
                                if (kIsWeb) {
                                  fileToUpload = await proofImage!
                                      .readAsBytes();
                                } else {
                                  fileToUpload = File(proofImage!.path);
                                }

                                // 2. Upload image
                                final imageUrl = await _supabaseService.uploadFile(
                                  'proof-images',
                                  '${newStatus.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                  fileToUpload,
                                );

                                // 3. Update request status
                                await _supabase
                                    .from('service_requests')
                                    .update({
                                      'status': newStatus,
                                      'proof_image_url': imageUrl,
                                      'updated_at': DateTime.now()
                                          .toIso8601String(),
                                    })
                                    .eq('id', _serviceRequest!.id);

                                // 4. Send automated message with image marker
                                await _messagingService.sendMessage(
                                  conversationId: widget.conversation.id,
                                  messageText:
                                      '$successMessage\n[IMAGE]$imageUrl',
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  setState(() {
                                    _serviceRequest = _serviceRequest!.copyWith(
                                      status: newStatus,
                                      proofImageUrl: imageUrl,
                                    );
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Status updated with proof!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Confirm & Upload',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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

  Future<void> _updateTravelerStatus(String newStatus, String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // Stop tracking if status is changing from "On the Way"
      if (_serviceRequest!.status == 'On the Way' &&
          newStatus != 'On the Way') {
        _trackingService.stopTracking();
        print(
          '🛑 Stopped tracking - status changed from On the Way to $newStatus',
        );
      }

      // Update request status
      await _supabase
          .from('service_requests')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _serviceRequest!.id);

      // Send automated message
      await _messagingService.sendMessage(
        conversationId: widget.conversation.id,
        messageText: message,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        setState(() {
          _serviceRequest = _serviceRequest!.copyWith(status: newStatus);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to: $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating status: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);
    final currentUserId = _supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18 * scaleFactor,
              backgroundColor: Color(0xFF00B4D8),
              backgroundImage: widget.conversation.otherUserImage != null
                  ? NetworkImage(widget.conversation.otherUserImage!)
                  : null,
              child: widget.conversation.otherUserImage == null
                  ? Icon(
                      Icons.person,
                      size: 18 * scaleFactor,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: 12 * scaleFactor),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.otherUserName ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16 * scaleFactor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.conversation.serviceType != null)
                    Text(
                      widget.conversation.serviceType!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12 * scaleFactor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Request Details Bar
          if (_serviceRequest != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scaleFactor,
                vertical: 12 * scaleFactor,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: _showRequestDetails,
                    child: Row(
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
                            _serviceRequest!.serviceType == 'Pabakal'
                                ? Icons.shopping_bag_outlined
                                : Icons.local_shipping_outlined,
                            color: Color(0xFF00B4D8),
                            size: 20 * scaleFactor,
                          ),
                        ),
                        SizedBox(width: 12 * scaleFactor),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _serviceRequest!.serviceType == 'Pabakal'
                                    ? _serviceRequest!.productName ?? 'Item'
                                    : 'Package Delivery',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14 * scaleFactor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Service Fee: ',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12 * scaleFactor,
                                    ),
                                  ),
                                  Text(
                                    '₱${_serviceRequest!.serviceFee.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12 * scaleFactor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 20 * scaleFactor,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12 * scaleFactor),
                  // Progress Bar
                  _buildProgressBar(
                    _getProgressSteps(_serviceRequest!.serviceType),
                    _getCurrentStepIndex(
                      _serviceRequest!.status,
                      _serviceRequest!.serviceType,
                    ),
                    scaleFactor,
                  ),
                  if (widget.conversation.travelerId == currentUserId) ...[
                    SizedBox(height: 12 * scaleFactor),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _showRequestDetails,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: 12 * scaleFactor,
                              ),
                              side: BorderSide(
                                color: AppConstants.primaryColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Details',
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12 * scaleFactor),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _getNextActionForTraveler(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              padding: EdgeInsets.symmetric(
                                vertical: 12 * scaleFactor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child: Text(
                              _getNextActionLabel(),
                              style: TextStyle(
                                color:
                                    _serviceRequest!.status == 'Completed' ||
                                        _serviceRequest!.status ==
                                            'Order Sent' ||
                                        _serviceRequest!.status == 'Dropped Off'
                                    ? Colors.grey[600]
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.conversation.requesterId == currentUserId) ...[
                    SizedBox(height: 12 * scaleFactor),
                    Row(
                      children: [
                        if (_serviceRequest!.status == 'On the Way') ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TrackingMapPage(
                                      requestId: _serviceRequest!.id,
                                      travelerName: 'Traveler',
                                      serviceType: _serviceRequest!.serviceType,
                                      status: _serviceRequest!.status,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.my_location,
                                size: 18 * scaleFactor,
                              ),
                              label: Text(
                                'Track',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00B4D8),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: 12 * scaleFactor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _showRequestDetails,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: 12 * scaleFactor,
                                ),
                                side: BorderSide(
                                  color: AppConstants.primaryColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Details',
                                style: TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(width: 12 * scaleFactor),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                (_serviceRequest!.status == 'Dropped Off')
                                ? _handleItemReceived
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              padding: EdgeInsets.symmetric(
                                vertical: 12 * scaleFactor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child: Text(
                              _serviceRequest!.status == 'Completed'
                                  ? 'Completed ✓'
                                  : 'Item Received',
                              style: TextStyle(
                                color: _serviceRequest!.status == 'Completed'
                                    ? Colors.grey[600]
                                    : (_serviceRequest!.status == 'Dropped Off'
                                          ? Colors.white
                                          : Colors.grey[600]),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyState(scaleFactor)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16 * scaleFactor),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final showDate =
                          index == 0 ||
                          _messages[index - 1].formattedDate !=
                              message.formattedDate;

                      return Column(
                        children: [
                          if (showDate)
                            _buildDateDivider(
                              message.formattedDate,
                              scaleFactor,
                            ),
                          _buildMessageBubble(
                            message,
                            message.isSentBy(currentUserId),
                            scaleFactor,
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Message Input
          _buildMessageInput(scaleFactor),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double scaleFactor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40 * scaleFactor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64 * scaleFactor,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16 * scaleFactor),
            Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 18 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8 * scaleFactor),
            Text(
              'Send your first message below',
              style: TextStyle(
                fontSize: 14 * scaleFactor,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(String date, double scaleFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor),
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12 * scaleFactor,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMine, double scaleFactor) {
    // Check if message contains an image
    final hasImage = message.messageText.contains('[IMAGE]');
    final hasTracking = message.messageText.contains('[TRACK_LOCATION]');
    String? imageUrl;
    String displayText = message.messageText;

    if (hasImage) {
      final parts = message.messageText.split('[IMAGE]');
      displayText = parts[0].trim();
      if (parts.length > 1) {
        imageUrl = parts[1].trim();
      }
    }

    if (hasTracking) {
      displayText = displayText.replaceAll('[TRACK_LOCATION]', '').trim();
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: hasTracking
            ? () {
                // Navigate to tracking page when tapping tracking message
                if (_serviceRequest != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackingMapPage(
                        requestId: _serviceRequest!.id,
                        travelerName: 'Traveler',
                        serviceType: _serviceRequest!.serviceType,
                        status: _serviceRequest!.status,
                      ),
                    ),
                  );
                }
              }
            : null,
        child: Container(
          margin: EdgeInsets.only(
            bottom: 8 * scaleFactor,
            left: isMine ? 60 * scaleFactor : 0,
            right: isMine ? 0 : 60 * scaleFactor,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scaleFactor,
            vertical: 10 * scaleFactor,
          ),
          decoration: BoxDecoration(
            color: hasTracking
                ? Color(0xFF00B4D8).withOpacity(0.9)
                : (isMine ? Color(0xFF00B4D8) : Colors.white),
            borderRadius: BorderRadius.circular(16 * scaleFactor),
            border: hasTracking
                ? Border.all(color: Colors.white, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (displayText.isNotEmpty) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasTracking) ...[
                      Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 18 * scaleFactor,
                      ),
                      SizedBox(width: 8 * scaleFactor),
                    ],
                    Flexible(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          color: hasTracking
                              ? Colors.white
                              : (isMine ? Colors.white : Colors.black87),
                          fontSize: 15 * scaleFactor,
                          fontWeight: hasTracking
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
                if (imageUrl != null) SizedBox(height: 8 * scaleFactor),
              ],
              if (imageUrl != null) ...[
                GestureDetector(
                  onTap: () {
                    // Show full screen image
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: Stack(
                          children: [
                            Center(
                              child: InteractiveViewer(
                                child: Image.network(
                                  imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      padding: EdgeInsets.all(20),
                                      color: Colors.white,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Failed to load image',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 40,
                              right: 20,
                              child: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 250 * scaleFactor,
                      maxHeight: 200 * scaleFactor,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8 * scaleFactor),
                      border: Border.all(
                        color: isMine
                            ? Colors.white.withOpacity(0.3)
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8 * scaleFactor),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 150 * scaleFactor,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: isMine
                                    ? Colors.white
                                    : AppConstants.primaryColor,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150 * scaleFactor,
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 40 * scaleFactor,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 8 * scaleFactor),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12 * scaleFactor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 4 * scaleFactor),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.formattedTime,
                    style: TextStyle(
                      color: isMine
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey[500],
                      fontSize: 11 * scaleFactor,
                    ),
                  ),
                  if (isMine) ...[
                    SizedBox(width: 4 * scaleFactor),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14 * scaleFactor,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(double scaleFactor) {
    return Container(
      padding: EdgeInsets.all(12 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24 * scaleFactor),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 15 * scaleFactor,
                    color: Colors.grey[500],
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 8 * scaleFactor),
          Material(
            color: Color(0xFF00B4D8),
            borderRadius: BorderRadius.circular(24 * scaleFactor),
            child: InkWell(
              onTap: _isSending ? null : _sendMessage,
              borderRadius: BorderRadius.circular(24 * scaleFactor),
              child: Container(
                padding: EdgeInsets.all(12 * scaleFactor),
                child: _isSending
                    ? SizedBox(
                        width: 20 * scaleFactor,
                        height: 20 * scaleFactor,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20 * scaleFactor,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
