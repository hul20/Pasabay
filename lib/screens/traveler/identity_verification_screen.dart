import 'package:flutter/material.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/supabase_service.dart';
import 'gov_id_upload_screen.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  bool _isLoading = true;
  String? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _fetchVerificationStatus();
  }

  Future<void> _fetchVerificationStatus() async {
    setState(() {
      _isLoading = true;
    });
    final supabaseService = SupabaseService();
    final result = await supabaseService.getVerificationStatus();
    setState(() {
      _verificationStatus = result != null ? result['status'] as String? : null;
      _isLoading = false;
    });
    if (_verificationStatus == 'Approved') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verification Complete'),
            content: const Text('Your identity has been verified!'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/traveler_home'),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_verificationStatus == 'Approved') {
            // Show confirmation screen
            return ResponsiveWrapper(
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified,
                        color: Colors.green,
                        size: 80 * scaleFactor,
                      ),
                      SizedBox(height: 24 * scaleFactor),
                      Text(
                        'You are verified!',
                        style: TextStyle(
                          fontSize: 28 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 16 * scaleFactor),
                      Text(
                        'Thank you for verifying your identity.',
                        style: TextStyle(fontSize: 16 * scaleFactor),
                      ),
                      SizedBox(height: 32 * scaleFactor),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          '/traveler_home',
                        ),
                        child: const Text('Continue to Home'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (_verificationStatus == 'Pending' ||
              _verificationStatus == 'Under Review') {
            // Show Pending/In Progress screen
            return ResponsiveWrapper(
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(24 * scaleFactor),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24 * scaleFactor),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.hourglass_top_rounded,
                          color: Colors.blue,
                          size: 64 * scaleFactor,
                        ),
                      ),
                      SizedBox(height: 32 * scaleFactor),
                      Text(
                        'Verification in Progress',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      SizedBox(height: 16 * scaleFactor),
                      Text(
                        'Your identity verification request has been submitted and is currently under review.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16 * scaleFactor,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 8 * scaleFactor),
                      Text(
                        'Please wait for approval.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16 * scaleFactor,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 40 * scaleFactor),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          '/traveler_home',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppConstants.primaryColor,
                          side: BorderSide(color: AppConstants.primaryColor),
                          minimumSize: Size(double.infinity, 50 * scaleFactor),
                        ),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Not verified: show normal verification flow
          return ResponsiveWrapper(
            child: SafeArea(
              child: Column(
                children: [
                  // Header with back button and logo
                  _buildHeader(context, scaleFactor),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28 * scaleFactor,
                        vertical: 20 * scaleFactor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          _buildTitle(scaleFactor),
                          SizedBox(height: 24 * scaleFactor),

                          // Required Documents Label
                          Text(
                            'Required Documents:',
                            style: TextStyle(
                              fontSize: 14 * scaleFactor,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF101828),
                            ),
                          ),
                          SizedBox(height: 16 * scaleFactor),

                          // Government ID Card
                          _buildDocumentCard(
                            icon: Icons.badge_outlined,
                            title: 'Government-issued Valid ID',
                            description:
                                "Passport, National ID, Driver's\nLicense, UMID, etc.",
                            scaleFactor: scaleFactor,
                          ),
                          SizedBox(height: 16 * scaleFactor),

                          // Selfie Photo Card
                          _buildDocumentCard(
                            icon: Icons.photo_camera_outlined,
                            title: 'Selfie Photo',
                            description: 'For face match against ID',
                            scaleFactor: scaleFactor,
                          ),
                          SizedBox(height: 16 * scaleFactor),

                          // Security Notice
                          _buildSecurityNotice(scaleFactor),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Actions
                  _buildBottomActions(context, scaleFactor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double scaleFactor) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 28 * scaleFactor,
        vertical: 16 * scaleFactor,
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppConstants.primaryColor,
              size: 20 * scaleFactor,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: 12 * scaleFactor),
          // Logo
          Container(
            width: 46 * scaleFactor,
            height: 46 * scaleFactor,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8 * scaleFactor),
              image: const DecorationImage(
                image: AssetImage(AppConstants.logoPath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 8 * scaleFactor),
          Text(
            'Pasabay',
            style: TextStyle(
              fontSize: 16 * scaleFactor,
              fontWeight: FontWeight.w600,
              color: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(double scaleFactor) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 40 * scaleFactor,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
          height: 1.2,
        ),
        children: const [
          TextSpan(text: 'Verify Your\n'),
          TextSpan(text: 'Identity'),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required IconData icon,
    required String title,
    required String description,
    required double scaleFactor,
  }) {
    return Container(
      padding: EdgeInsets.all(16 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48 * scaleFactor,
            height: 48 * scaleFactor,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8 * scaleFactor),
            ),
            child: Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 24 * scaleFactor,
            ),
          ),
          SizedBox(width: 12 * scaleFactor),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF101828),
                  ),
                ),
                SizedBox(height: 4 * scaleFactor),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13 * scaleFactor,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice(double scaleFactor) {
    return Container(
      padding: EdgeInsets.all(16 * scaleFactor),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12 * scaleFactor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Notice',
            style: TextStyle(
              fontSize: 15 * scaleFactor,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF101828),
            ),
          ),
          SizedBox(height: 8 * scaleFactor),
          Text(
            'Your documents are encrypted and stored securely. We only use them for verification purposes to maintain platform safety.',
            style: TextStyle(
              fontSize: 13 * scaleFactor,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, double scaleFactor) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        28 * scaleFactor,
        20 * scaleFactor,
        28 * scaleFactor,
        28 * scaleFactor,
      ),
      child: Column(
        children: [
          // Start Verification Button
          CustomButton(
            text: 'Start Verification',
            scaleFactor: scaleFactor,
            onPressed: () {
              // Navigate to Step 1: Government ID Upload
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GovIdUploadScreen(),
                ),
              );
            },
          ),

          SizedBox(height: 16 * scaleFactor),

          // Verify Later Button
          GestureDetector(
            onTap: () {
              // Navigate to traveler home page (skip verification)
              Navigator.pushReplacementNamed(context, '/traveler_home');
            },
            child: Container(
              width: double.infinity,
              height: 52 * scaleFactor,
              alignment: Alignment.center,
              child: Text(
                'Verify Later',
                style: TextStyle(
                  fontSize: 16 * scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
