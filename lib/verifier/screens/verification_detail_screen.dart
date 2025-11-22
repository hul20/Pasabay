import 'package:flutter/material.dart';
import '../../models/verification_request.dart';
import '../../models/verification_status.dart';
import '../../services/verification_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class VerificationDetailScreen extends StatefulWidget {
  final VerificationRequest request;

  const VerificationDetailScreen({super.key, required this.request});

  @override
  State<VerificationDetailScreen> createState() =>
      _VerificationDetailScreenState();
}

class _VerificationDetailScreenState extends State<VerificationDetailScreen> {
  final _verificationService = VerificationService();
  final _authService = AuthService();
  final _notesController = TextEditingController();
  final _rejectionReasonController = TextEditingController();

  bool _isProcessing = false;
  late VerificationRequest _request;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    _notesController.text = _request.verifierNotes ?? '';
    _rejectionReasonController.text = _request.rejectionReason ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Approve Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to approve this verification request?'),
            SizedBox(height: 16),
            Text(
              'Traveler: ${_request.travelerName}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Email: ${_request.travelerEmail}'),
            SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add any notes about this approval...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);

      try {
        // Call the simplified approveRequest method
        final success = await _verificationService.approveRequest(
          _request.id,
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        if (mounted) {
          setState(() => _isProcessing = false);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Request approved successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); // Return to dashboard with refresh flag
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to approve request. Check Supabase logs.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 12),
            Text('Reject Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject this verification request?'),
            SizedBox(height: 16),
            Text(
              'Traveler: ${_request.travelerName}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Email: ${_request.travelerEmail}'),
            SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              decoration: InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(),
                hintText: 'Explain why this request is being rejected...',
              ),
              maxLines: 3,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add any additional notes...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_rejectionReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);

      final success = await _verificationService.rejectRequest(
        _request.id,
        _authService.currentUserId!,
        _rejectionReasonController.text.trim(),
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        setState(() => _isProcessing = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true); // Return to dashboard with refresh flag
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject request'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification Request Details'),
        actions: [
          if (_isProcessing)
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and Basic Info Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Request Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _request.status.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _request.status.color,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _request.status.icon,
                                    size: 20,
                                    color: _request.status.color,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _request.status.displayName,
                                    style: TextStyle(
                                      color: _request.status.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 32),
                        _buildInfoRow('Request ID', _request.id),
                        _buildInfoRow('Traveler Name', _request.travelerName),
                        _buildInfoRow('Email', _request.travelerEmail),
                        _buildInfoRow(
                          'Submitted',
                          '${_request.submittedAt.toString().substring(0, 16)} (${_request.timeElapsed})',
                        ),
                        if (_request.reviewedAt != null)
                          _buildInfoRow(
                            'Reviewed',
                            _request.reviewedAt!.toString().substring(0, 16),
                          ),
                        if (_request.verifierName != null)
                          _buildInfoRow('Reviewed By', _request.verifierName!),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Documents Section
                Text(
                  'Submitted Documents',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ..._request.documents.entries.map((entry) {
                  return _buildDocumentCard(entry.key, entry.value);
                }),

                // Notes Section
                if (_request.verifierNotes != null ||
                    _request.rejectionReason != null) ...[
                  SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review Notes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(height: 32),
                          if (_request.rejectionReason != null) ...[
                            Text(
                              'Rejection Reason:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(_request.rejectionReason!),
                            SizedBox(height: 16),
                          ],
                          if (_request.verifierNotes != null) ...[
                            Text(
                              'Verifier Notes:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(_request.verifierNotes!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                // Action Buttons
                if (_request.status == VerificationStatus.PENDING ||
                    _request.status == VerificationStatus.UNDER_REVIEW) ...[
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _handleReject,
                        icon: Icon(Icons.cancel),
                        label: Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _handleApprove,
                        icon: Icon(Icons.check_circle),
                        label: Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: AppConstants.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppConstants.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String docType, String url) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.image,
                color: AppConstants.primaryColor,
                size: 32,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDocumentType(docType),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Click to view document',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _viewDocument(url, docType),
              icon: Icon(Icons.visibility),
              label: Text('View'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDocumentType(String type) {
    return type
        .split('_')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  void _viewDocument(String url, String docType) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Column(
            children: [
              AppBar(
                title: Text(_formatDocumentType(docType)),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return CircularProgressIndicator();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text('Failed to load image'),
                          SizedBox(height: 8),
                          Text(
                            url,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
