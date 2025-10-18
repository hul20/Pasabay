import 'package:flutter/material.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'gov_id_upload_screen.dart';

class IdentityVerificationScreen extends StatelessWidget {
  const IdentityVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

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
                image: NetworkImage(AppConstants.logoUrl),
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
