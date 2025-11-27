import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/request.dart';
import '../../models/conversation.dart';
import '../../services/request_service.dart';
import '../../services/messaging_service.dart';
import '../../services/haptic_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/supabase_service.dart';
import '../messages_page.dart';
import '../chat_detail_page.dart';

class RequestDetailPage extends StatefulWidget {
  final ServiceRequest request;
  final Map<String, dynamic>? requesterInfo;

  const RequestDetailPage({
    super.key,
    required this.request,
    this.requesterInfo,
  });

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  final RequestService _requestService = RequestService();
  final SupabaseService _supabaseService = SupabaseService();
  final MessagingService _messagingService = MessagingService();
  final _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;
  late ServiceRequest _request;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  String get _requesterName {
    if (widget.requesterInfo != null) {
      return '${widget.requesterInfo!['first_name']} ${widget.requesterInfo!['last_name']}';
    }
    return 'Unknown User';
  }

  String? get _requesterImage {
    return widget.requesterInfo?['profile_image_url'];
  }

  String? get _requesterPhone {
    return widget.requesterInfo?['phone_number'];
  }

  bool get _isOngoing {
    return ['Accepted', 'Order Sent'].contains(widget.request.status);
  }

  void _showRequestDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final screenWidth = MediaQuery.of(context).size.width;
          final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.all(16 * scaleFactor),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Request Details',
                    style: TextStyle(
                      fontSize: 20 * scaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20 * scaleFactor),
                  _buildRequesterCard(scaleFactor, showMessageButton: false),
                  SizedBox(height: 24 * scaleFactor),
                  if (widget.request.serviceType == 'Pabakal')
                    _buildPabakalDetails(scaleFactor)
                  else
                    _buildPasabayDetails(scaleFactor),
                  SizedBox(height: 24 * scaleFactor),
                  _buildPaymentCard(scaleFactor),
                  if (widget.request.photoUrls != null &&
                      widget.request.photoUrls!.isNotEmpty) ...[
                    SizedBox(height: 24 * scaleFactor),
                    _buildAttachments(scaleFactor),
                  ],
                  SizedBox(height: 20 * scaleFactor),
                ],
              ),
            ),
          );
        },
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
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: proofImage != null
                          ? GestureDetector(
                              onTap:
                                  () {}, // Absorb taps to prevent image disappearing
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: kIsWeb
                                        ? Image.network(
                                            proofImage!.path,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          )
                                        : Image.file(
                                            File(proofImage!.path),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: FloatingActionButton.small(
                                      backgroundColor: Colors.white,
                                      onPressed: () async {
                                        final XFile? image = await _imagePicker
                                            .pickImage(
                                              source: ImageSource.camera,
                                              imageQuality: 80,
                                            );
                                        if (image != null) {
                                          setModalState(() {
                                            proofImage = image;
                                          });
                                        }
                                      },
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: AppConstants.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GestureDetector(
                              onTap: () async {
                                final XFile? image = await _imagePicker
                                    .pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 80,
                                    );
                                if (image != null) {
                                  setModalState(() {
                                    proofImage = image;
                                  });
                                }
                              },
                              child: Column(
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
                                    .eq('id', _request.id);

                                // 4. Send automated message
                                // Get conversation ID
                                final conversationResponse = await _supabase
                                    .from('conversations')
                                    .select('id')
                                    .eq('request_id', _request.id)
                                    .maybeSingle();

                                if (conversationResponse != null) {
                                  await _messagingService.sendMessage(
                                    conversationId: conversationResponse['id'],
                                    messageText:
                                        'Order has been sent! 📦\n[IMAGE]$imageUrl',
                                  );
                                }

                                if (mounted) {
                                  Navigator.pop(context);
                                  setState(() {
                                    _request = _request.copyWith(
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

  Future<void> _acceptRequest() async {
    HapticService.modalOpen();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * scaleFactor),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 28 * scaleFactor,
              ),
              SizedBox(width: 12 * scaleFactor),
              Text(
                'Accept Request?',
                style: TextStyle(fontSize: 20 * scaleFactor),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to accept this ${widget.request.serviceType} request?',
                style: TextStyle(fontSize: 15 * scaleFactor),
              ),
              SizedBox(height: 16 * scaleFactor),
              Container(
                padding: EdgeInsets.all(12 * scaleFactor),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8 * scaleFactor),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You will earn:',
                      style: TextStyle(
                        fontSize: 13 * scaleFactor,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4 * scaleFactor),
                    Text(
                      '₱${widget.request.serviceFee.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15 * scaleFactor,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scaleFactor),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Accept',
                style: TextStyle(fontSize: 15 * scaleFactor),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      // Call accept function from Supabase
      final success = await _requestService.acceptRequest(widget.request.id);

      if (!mounted) return;

      if (success) {
        // Create conversation
        final conversationId = await _requestService.getOrCreateConversation(
          widget.request.id,
        );

        if (!mounted) return;

        if (conversationId != null) {
          // Fetch the full conversation object
          final conversationResponse = await _supabase
              .from('conversations')
              .select('*')
              .eq('id', conversationId)
              .single();

          final conversation = Conversation.fromJson(conversationResponse);

          // Load other user info
          final currentUserId = _supabase.auth.currentUser!.id;
          final otherUserId = conversation.getOtherUserId(currentUserId);

          final userResponse = await _supabase
              .from('users')
              .select('first_name, last_name, profile_image_url')
              .eq('id', otherUserId)
              .single();

          conversation.otherUserName =
              '${userResponse['first_name']} ${userResponse['last_name']}';
          conversation.otherUserImage = userResponse['profile_image_url'];

          // Load service type
          final requestResponse = await _supabase
              .from('service_requests')
              .select('service_type')
              .eq('id', widget.request.id)
              .single();

          conversation.serviceType = requestResponse['service_type'];

          // Navigate to chat detail page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(conversation: conversation),
            ),
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Request accepted! You can now message the requester.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception('Failed to create conversation');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectRequest() async {
    HapticService.modalOpen();
    final TextEditingController reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * scaleFactor),
          ),
          title: Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: Colors.red,
                size: 28 * scaleFactor,
              ),
              SizedBox(width: 12 * scaleFactor),
              Text(
                'Reject Request?',
                style: TextStyle(fontSize: 20 * scaleFactor),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide a reason for rejecting this request:',
                style: TextStyle(fontSize: 15 * scaleFactor),
              ),
              SizedBox(height: 16 * scaleFactor),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., Capacity full, Route changed, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8 * scaleFactor),
                  ),
                  contentPadding: EdgeInsets.all(12 * scaleFactor),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15 * scaleFactor,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scaleFactor),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Reject',
                style: TextStyle(fontSize: 15 * scaleFactor),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final success = await _requestService.rejectRequest(
        widget.request.id,
        reasonController.text.trim().isNotEmpty
            ? reasonController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showDetailsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) {
          final screenWidth = MediaQuery.of(context).size.width;
          final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: controller,
              padding: EdgeInsets.all(20 * scaleFactor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  _buildRequesterCard(scaleFactor),
                  SizedBox(height: 20 * scaleFactor),
                  if (_request.serviceType == 'Pabakal')
                    _buildPabakalDetails(scaleFactor)
                  else
                    _buildPasabayDetails(scaleFactor),
                  SizedBox(height: 20 * scaleFactor),
                  _buildPaymentCard(scaleFactor),
                  if (_request.photoUrls != null &&
                      _request.photoUrls!.isNotEmpty) ...[
                    SizedBox(height: 20 * scaleFactor),
                    _buildAttachments(scaleFactor),
                  ],
                  SizedBox(height: 40 * scaleFactor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    // Check if ongoing
    bool isOngoing =
        _request.status == 'Accepted' || _request.status == 'Order Sent';

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
          '${widget.request.serviceType} Request',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18 * scaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16 * scaleFactor),
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scaleFactor,
              vertical: 6 * scaleFactor,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20 * scaleFactor),
            ),
            child: Text(
              widget.request.status,
              style: TextStyle(
                fontSize: 13 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(),
              ),
            ),
          ),
        ],
      ),
      body: isOngoing
          ? Column(
              children: [
                // Status Banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 12 * scaleFactor,
                    horizontal: 16 * scaleFactor,
                  ),
                  color: _getStatusColor().withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _getStatusColor(),
                        size: 20 * scaleFactor,
                      ),
                      SizedBox(width: 8 * scaleFactor),
                      Expanded(
                        child: Text(
                          _request.status == 'Accepted'
                              ? 'Request Accepted. You can now chat.'
                              : 'Order Sent. Waiting for confirmation.',
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Chat message - tap to open full chat
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48 * scaleFactor,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 12 * scaleFactor),
                        Text(
                          'Tap "Message" to chat with requester',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14 * scaleFactor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom Actions
                Container(
                  padding: EdgeInsets.all(16 * scaleFactor),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Get conversation for this request
                            final conversationResponse = await _supabase
                                .from('conversations')
                                .select('*')
                                .eq('request_id', _request.id)
                                .maybeSingle();

                            if (conversationResponse != null && mounted) {
                              final conversation = Conversation.fromJson(
                                conversationResponse,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailPage(
                                    conversation: conversation,
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            padding: EdgeInsets.symmetric(
                              vertical: 16 * scaleFactor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                12 * scaleFactor,
                              ),
                            ),
                          ),
                          icon: Icon(Icons.chat_bubble, size: 20 * scaleFactor),
                          label: Text(
                            'Message Requester',
                            style: TextStyle(
                              fontSize: 16 * scaleFactor,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (_request.status == 'Accepted') ...[
                        SizedBox(height: 8 * scaleFactor),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleOrderSent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                vertical: 16 * scaleFactor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12 * scaleFactor,
                                ),
                              ),
                            ),
                            child: Text(
                              'Item Delivered',
                              style: TextStyle(
                                fontSize: 16 * scaleFactor,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 8 * scaleFactor),
                      TextButton(
                        onPressed: _showDetailsBottomSheet,
                        child: Text('View Request Details'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(18 * scaleFactor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Requester Info Card
                    _buildRequesterCard(scaleFactor),

                    SizedBox(height: 24 * scaleFactor),

                    // Service Details
                    Text(
                      'Service Details',
                      style: TextStyle(
                        fontSize: 18 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: 16 * scaleFactor),

                    // Show details based on service type
                    if (widget.request.serviceType == 'Pabakal')
                      _buildPabakalDetails(scaleFactor)
                    else
                      _buildPasabayDetails(scaleFactor),

                    SizedBox(height: 24 * scaleFactor),

                    // Payment Info
                    _buildPaymentCard(scaleFactor),

                    // Attachments
                    if (widget.request.photoUrls != null &&
                        widget.request.photoUrls!.isNotEmpty) ...[
                      SizedBox(height: 24 * scaleFactor),
                      _buildAttachments(scaleFactor),
                    ],

                    SizedBox(height: 32 * scaleFactor),

                    // Action Buttons (only show if pending)
                    if (widget.request.status == 'Pending')
                      _buildActionButtons(scaleFactor),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getStatusColor() {
    switch (widget.request.status) {
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

  Widget _buildRequesterCard(
    double scaleFactor, {
    bool showMessageButton = true,
  }) {
    return Container(
      padding: EdgeInsets.all(16 * scaleFactor),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 32 * scaleFactor,
            backgroundColor: Color(0xFF00B4D8),
            backgroundImage: _requesterImage != null
                ? NetworkImage(_requesterImage!)
                : null,
            child: _requesterImage == null
                ? Icon(
                    Icons.person,
                    size: 32 * scaleFactor,
                    color: Colors.white,
                  )
                : null,
          ),
          SizedBox(width: 16 * scaleFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requester',
                  style: TextStyle(
                    fontSize: 12 * scaleFactor,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4 * scaleFactor),
                Text(
                  _requesterName,
                  style: TextStyle(
                    fontSize: 18 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (_requesterPhone != null) ...[
                  SizedBox(height: 4 * scaleFactor),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14 * scaleFactor,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4 * scaleFactor),
                      Text(
                        _requesterPhone!,
                        style: TextStyle(
                          fontSize: 13 * scaleFactor,
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
      ),
    );
  }

  Widget _buildPabakalDetails(double scaleFactor) {
    return Container(
      padding: EdgeInsets.all(16 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.shopping_bag,
            'Product',
            widget.request.productName ?? 'N/A',
            scaleFactor,
          ),
          Divider(height: 24 * scaleFactor),
          _buildDetailRow(
            Icons.store,
            'Store',
            widget.request.storeName ?? 'N/A',
            scaleFactor,
          ),
          Divider(height: 24 * scaleFactor),
          _buildDetailRow(
            Icons.location_on,
            'Store Location',
            widget.request.storeLocation ?? 'N/A',
            scaleFactor,
          ),
          Divider(height: 24 * scaleFactor),
          _buildDetailRow(
            Icons.attach_money,
            'Product Cost',
            '₱${widget.request.productCost?.toStringAsFixed(2) ?? '0.00'}',
            scaleFactor,
          ),
          if (widget.request.productDescription != null &&
              widget.request.productDescription!.isNotEmpty) ...[
            Divider(height: 24 * scaleFactor),
            _buildDetailRow(
              Icons.description,
              'Description',
              widget.request.productDescription!,
              scaleFactor,
              isMultiline: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasabayDetails(double scaleFactor) {
    return Container(
      padding: EdgeInsets.all(16 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.person,
            'Recipient',
            widget.request.recipientName ?? 'N/A',
            scaleFactor,
          ),
          Divider(height: 24 * scaleFactor),
          _buildDetailRow(
            Icons.phone,
            'Phone',
            widget.request.recipientPhone ?? 'N/A',
            scaleFactor,
          ),
          if (widget.request.pickupLocation != null) ...[
            Divider(height: 24 * scaleFactor),
            _buildDetailRow(
              Icons.trip_origin,
              'Pickup',
              widget.request.pickupLocation!,
              scaleFactor,
              isMultiline: true,
            ),
          ],
          Divider(height: 24 * scaleFactor),
          _buildDetailRow(
            Icons.location_on,
            'Drop-off',
            widget.request.dropoffLocation ?? 'N/A',
            scaleFactor,
            isMultiline: true,
          ),
          if (widget.request.pickupTime != null) ...[
            Divider(height: 24 * scaleFactor),
            _buildDetailRow(
              Icons.access_time,
              'Preferred Time',
              widget.request.formattedPickupTime,
              scaleFactor,
            ),
          ],
          if (widget.request.packageDescription != null &&
              widget.request.packageDescription!.isNotEmpty) ...[
            Divider(height: 24 * scaleFactor),
            _buildDetailRow(
              Icons.inventory,
              'Package Description',
              widget.request.packageDescription!,
              scaleFactor,
              isMultiline: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    double scaleFactor, {
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20 * scaleFactor, color: Color(0xFF00B4D8)),
        SizedBox(width: 12 * scaleFactor),
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
    );
  }

  Widget _buildPaymentCard(double scaleFactor) {
    return Container(
      padding: EdgeInsets.all(16 * scaleFactor),
      decoration: BoxDecoration(
        color: Color(0xFF00B4D8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        border: Border.all(color: Color(0xFF00B4D8).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 16 * scaleFactor,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12 * scaleFactor),
          if (widget.request.serviceType == 'Pabakal' &&
              widget.request.productCost != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Product Cost',
                  style: TextStyle(
                    fontSize: 14 * scaleFactor,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '₱${widget.request.productCost!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8 * scaleFactor),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Fee (You earn)',
                style: TextStyle(
                  fontSize: 14 * scaleFactor,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '₱${widget.request.serviceFee.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14 * scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          if (widget.request.serviceType == 'Pabakal') ...[
            Divider(height: 20 * scaleFactor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '₱${widget.request.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B4D8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachments(double scaleFactor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: TextStyle(
            fontSize: 18 * scaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12 * scaleFactor),
        if (widget.request.photoUrls != null)
          Wrap(
            spacing: 8 * scaleFactor,
            runSpacing: 8 * scaleFactor,
            children: widget.request.photoUrls!.map((url) {
              return Container(
                width: 100 * scaleFactor,
                height: 100 * scaleFactor,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8 * scaleFactor),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildActionButtons(double scaleFactor) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : _rejectRequest,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12 * scaleFactor),
              ),
              padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
            ),
            icon: _isProcessing
                ? SizedBox(
                    width: 20 * scaleFactor,
                    height: 20 * scaleFactor,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.close, size: 20 * scaleFactor),
            label: Text(
              'Reject',
              style: TextStyle(
                fontSize: 16 * scaleFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 16 * scaleFactor),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _acceptRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12 * scaleFactor),
              ),
              padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
            ),
            icon: _isProcessing
                ? SizedBox(
                    width: 20 * scaleFactor,
                    height: 20 * scaleFactor,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.check, size: 20 * scaleFactor),
            label: Text(
              'Accept',
              style: TextStyle(
                fontSize: 16 * scaleFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
