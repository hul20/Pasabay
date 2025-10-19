import 'package:flutter/material.dart';
import 'package:pasabay_app/utils/helpers.dart';
import 'package:pasabay_app/utils/supabase_service.dart';
import 'verification_successful_screen.dart';

class ReviewDocumentsScreen extends StatefulWidget {
  final String governmentIdUrl;
  final String selfieUrl;
  final String governmentIdFileName;
  final String selfieFileName;

  const ReviewDocumentsScreen({
    super.key,
    required this.governmentIdUrl,
    required this.selfieUrl,
    required this.governmentIdFileName,
    required this.selfieFileName,
  });

  @override
  State<ReviewDocumentsScreen> createState() => _ReviewDocumentsScreenState();
}

class _ReviewDocumentsScreenState extends State<ReviewDocumentsScreen> {
  bool _isSubmitting = false;
  final _supabaseService = SupabaseService();

  Future<void> _submitForVerification() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Submit verification request to Supabase database
      await _supabaseService.submitVerificationRequest(
        govIdUrl: widget.governmentIdUrl,
        selfieUrl: widget.selfieUrl,
        govIdFileName: widget.governmentIdFileName,
        selfieFileName: widget.selfieFileName,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documents submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to Verification Successful screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const VerificationSuccessfulScreen(),
        ),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting documents: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _viewDocument(String documentType) {
    // TODO: Implement document viewer
    // Show full screen image viewer for the selected document
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing $documentType'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(color: Color(0xFFF9F9F9)),
            child: Column(
              children: [
                // Header with gradient and progress indicator
                _buildHeader(scaleFactor),

                // Main content - scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(28 * scaleFactor),
                    child: Column(
                      children: [
                        // Document cards
                        _buildDocumentCard(
                          context,
                          scaleFactor,
                          title: 'Government ID',
                          fileName: widget.governmentIdFileName,
                          icon: Icons.credit_card,
                          onView: () => _viewDocument('Government ID'),
                        ),
                        SizedBox(height: 14 * scaleFactor),
                        _buildDocumentCard(
                          context,
                          scaleFactor,
                          title: 'Selfie Photo',
                          fileName: widget.selfieFileName,
                          icon: Icons.camera_alt,
                          onView: () => _viewDocument('Selfie Photo'),
                        ),

                        SizedBox(height: 40 * scaleFactor),

                        // Before You Submit info box
                        _buildInfoBox(scaleFactor),

                        SizedBox(height: 40 * scaleFactor),

                        // Action buttons
                        _buildActionButtons(scaleFactor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double scaleFactor) {
    return Container(
      height: 240 * scaleFactor,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF37BFF9), Color(0xFF00AAF3)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30 * scaleFactor),
          bottomRight: Radius.circular(30 * scaleFactor),
        ),
      ),
      child: Stack(
        children: [
          // Logo
          Positioned(
            left: 25 * scaleFactor,
            top: 19 * scaleFactor,
            child: Row(
              children: [
                // Logo image
                Container(
                  width: 46 * scaleFactor,
                  height: 46 * scaleFactor,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12 * scaleFactor),
                  ),
                  child: Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        color: const Color(0xFF00AAF3),
                        fontSize: 28 * scaleFactor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4 * scaleFactor),
                Text(
                  'Pasabay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.235 * scaleFactor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Progress indicator (3 steps)
          Positioned(
            left: 29 * scaleFactor,
            top: 78 * scaleFactor,
            right: 29 * scaleFactor,
            child: _buildProgressIndicator(scaleFactor),
          ),

          // Heading
          Positioned(
            left: 21 * scaleFactor,
            top: 125 * scaleFactor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review Your',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32 * scaleFactor,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Documents',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42 * scaleFactor,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(double scaleFactor) {
    return SizedBox(
      height: 38 * scaleFactor,
      child: Stack(
        children: [
          // Progress line (background)
          Positioned(
            left: 46 * scaleFactor,
            top: 95 * scaleFactor - 78 * scaleFactor,
            child: Container(
              width: 325 * scaleFactor,
              height: 5 * scaleFactor,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5 * scaleFactor),
              ),
            ),
          ),

          // Step 1 - Completed (with checkmark)
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 38 * scaleFactor,
              height: 38 * scaleFactor,
              decoration: BoxDecoration(
                color: const Color(0xFF65AAC6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF358EB4),
                  width: 6 * scaleFactor,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18 * scaleFactor,
                ),
              ),
            ),
          ),

          // Step 2 - Completed (with checkmark)
          Positioned(
            left: 194 * scaleFactor,
            top: 0,
            child: Container(
              width: 38 * scaleFactor,
              height: 38 * scaleFactor,
              decoration: BoxDecoration(
                color: const Color(0xFF62A7C5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2B88B0),
                  width: 6 * scaleFactor,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18 * scaleFactor,
                ),
              ),
            ),
          ),

          // Step 3 - Active (current)
          Positioned(
            left: 352 * scaleFactor,
            top: 0,
            child: Container(
              width: 38 * scaleFactor,
              height: 38 * scaleFactor,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF37BFF9),
                  width: 6 * scaleFactor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    double scaleFactor, {
    required String title,
    required String fileName,
    required IconData icon,
    required VoidCallback onView,
  }) {
    return Container(
      height: 95 * scaleFactor,
      padding: EdgeInsets.symmetric(horizontal: 14.305 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.689 * scaleFactor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52 * scaleFactor,
            height: 52 * scaleFactor,
            decoration: BoxDecoration(
              color: const Color(0xFF00AAF3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12 * scaleFactor),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00AAF3),
              size: 28 * scaleFactor,
            ),
          ),

          SizedBox(width: 14.305 * scaleFactor),

          // Document info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.689 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF101828),
                  ),
                ),
                SizedBox(height: 2 * scaleFactor),
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 14.305 * scaleFactor,
                    color: const Color(0xFF4A5565),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: 9.537 * scaleFactor),

          // Check icon and View button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24 * scaleFactor,
              ),
              SizedBox(width: 9.537 * scaleFactor),
              ElevatedButton(
                onPressed: onView,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AAF3),
                  foregroundColor: Colors.white,
                  minimumSize: Size(64 * scaleFactor, 33.379 * scaleFactor),
                  padding: EdgeInsets.symmetric(
                    horizontal: 11.126 * scaleFactor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9.537 * scaleFactor),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'View',
                  style: TextStyle(fontSize: 14.305 * scaleFactor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(double scaleFactor) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14.305 * scaleFactor,
        14.305 * scaleFactor,
        14.305 * scaleFactor,
        0,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16.689 * scaleFactor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF00AAF3),
            size: 19.073 * scaleFactor,
          ),
          SizedBox(width: 14.305 * scaleFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before You Submit',
                  style: TextStyle(
                    fontSize: 16.689 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF101828),
                  ),
                ),
                SizedBox(height: 4.768 * scaleFactor),
                Text(
                  'Please ensure all documents are clear and readable. Our verification team will review your submission within 24-48 hours.',
                  style: TextStyle(
                    fontSize: 14.305 * scaleFactor,
                    color: const Color(0xFF4A5565),
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 14.305 * scaleFactor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double scaleFactor) {
    return Column(
      children: [
        // Submit button
        SizedBox(
          width: double.infinity,
          height: 57.22 * scaleFactor,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00AAF3),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF00AAF3).withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.689 * scaleFactor),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20 * scaleFactor,
                    height: 20 * scaleFactor,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Submit For Verification',
                    style: TextStyle(
                      fontSize: 19.073 * scaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        SizedBox(height: 12 * scaleFactor),

        // Back button
        SizedBox(
          width: double.infinity,
          height: 57.22 * scaleFactor,
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF959BA0),
              side: BorderSide.none,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.689 * scaleFactor),
              ),
            ),
            child: Text(
              'Back',
              style: TextStyle(
                fontSize: 19.073 * scaleFactor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
