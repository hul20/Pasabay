import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/request.dart';
import '../services/messaging_service.dart';
import '../services/request_service.dart';

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
  final _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  List<Message> _messages = [];
  ServiceRequest? _serviceRequest;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;
  RealtimeChannel? _messagesChannel;

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
    if (_messagesChannel != null) {
      _messagingService.unsubscribe(_messagesChannel!);
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

  Future<void> _markAsRead() async {
    await _messagingService.markMessagesAsRead(widget.conversation.id);
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

                                // 4. Send automated message
                                await _messagingService.sendMessage(
                                  conversationId: widget.conversation.id,
                                  messageText:
                                      'Order has been sent! 📦\nSee proof of delivery: $imageUrl',
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);
    final currentUserId = _supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                              Text(
                                'Tap to view details',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12 * scaleFactor,
                                ),
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
                            onPressed: _serviceRequest!.status == 'Accepted'
                                ? _handleOrderSent
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
                              'Item Delivered',
                              style: TextStyle(
                                color: Colors.white,
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
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
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
          color: isMine ? Color(0xFF00B4D8) : Colors.white,
          borderRadius: BorderRadius.circular(16 * scaleFactor),
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
            Text(
              message.messageText,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 15 * scaleFactor,
              ),
            ),
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
