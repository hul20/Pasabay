import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'selfie_upload_screen.dart';

class GovIdUploadScreen extends StatefulWidget {
  const GovIdUploadScreen({super.key});

  @override
  State<GovIdUploadScreen> createState() => _GovIdUploadScreenState();
}

class _GovIdUploadScreenState extends State<GovIdUploadScreen> {
  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _continue() {
    // TODO: Re-enable validation for production
    // For testing: Allow proceeding without file upload
    /* if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your Government ID first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    } */

    // Navigate to Step 2: Selfie Upload
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelfieUploadScreen(
          governmentIdFile: _selectedFile,
          governmentIdFileName:
              _selectedFile?.path.split('/').last ??
              _selectedFile?.path.split('\\').last,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

          return ResponsiveWrapper(
            child: Column(
              children: [
                // Gradient Header with Progress
                _buildGradientHeader(scaleFactor),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 20 * scaleFactor),

                        // Upload Area
                        _buildUploadArea(scaleFactor),

                        SizedBox(height: 20 * scaleFactor),

                        // Document Requirements
                        _buildRequirements(scaleFactor),

                        SizedBox(height: 36 * scaleFactor),

                        // Buttons
                        _buildButtons(scaleFactor),

                        SizedBox(height: 20 * scaleFactor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradientHeader(double scaleFactor) {
    return Container(
      height: 240 * scaleFactor,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConstants.primaryColor, const Color(0xFF4EC5F8)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30 * scaleFactor),
          bottomRight: Radius.circular(30 * scaleFactor),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Padding(
              padding: EdgeInsets.fromLTRB(
                25 * scaleFactor,
                19 * scaleFactor,
                25 * scaleFactor,
                0,
              ),
              child: Row(
                children: [
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
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30 * scaleFactor),

            // Progress Indicators
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 29 * scaleFactor),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress Line
                  Positioned(
                    left: 46 * scaleFactor,
                    child: Container(
                      width: 325 * scaleFactor,
                      height: 5 * scaleFactor,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(5 * scaleFactor),
                      ),
                    ),
                  ),
                  // Progress Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Step 1 - Active
                      _buildProgressDot(
                        isActive: true,
                        isCompleted: false,
                        size: 38 * scaleFactor,
                        borderColor: const Color(0xFF01ABF3),
                      ),
                      // Step 2
                      _buildProgressDot(
                        isActive: false,
                        isCompleted: false,
                        size: 29 * scaleFactor,
                        borderColor: const Color(0xFF1BB5F6),
                      ),
                      // Step 3
                      _buildProgressDot(
                        isActive: false,
                        isCompleted: false,
                        size: 29 * scaleFactor,
                        borderColor: const Color(0xFF3FC2FA),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 17 * scaleFactor),

            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 21 * scaleFactor),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 32 * scaleFactor,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.1,
                  ),
                  children: [
                    const TextSpan(text: 'Upload Your\n'),
                    TextSpan(
                      text: 'Government ID',
                      style: TextStyle(
                        fontSize: 42 * scaleFactor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDot({
    required bool isActive,
    required bool isCompleted,
    required double size,
    required Color borderColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white
            : (isCompleted ? const Color(0xFF4EC5F8) : const Color(0xFF6ACFFB)),
        border: Border.all(color: borderColor, width: 6),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildUploadArea(double scaleFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * scaleFactor),
      child: GestureDetector(
        onTap: _pickFile,
        child: Container(
          height: 237 * scaleFactor,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(
              color: const Color(0xFFD1D5DC),
              width: 1.5,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(19 * scaleFactor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // File Icon
              Container(
                width: 58 * scaleFactor,
                height: 58 * scaleFactor,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12 * scaleFactor),
                ),
                child: Icon(
                  Icons.insert_drive_file_outlined,
                  size: 32 * scaleFactor,
                  color: AppConstants.primaryColor,
                ),
              ),

              SizedBox(height: 16 * scaleFactor),

              // Upload Text
              Text(
                _fileName ?? 'Upload Your Document',
                style: TextStyle(
                  fontSize: 17 * scaleFactor,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF101828),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8 * scaleFactor),

              if (_fileName == null)
                Text(
                  'Drag and drop your file here, or click to browse',
                  style: TextStyle(
                    fontSize: 14 * scaleFactor,
                    color: const Color(0xFF4A5565),
                  ),
                  textAlign: TextAlign.center,
                ),

              SizedBox(height: 16 * scaleFactor),

              // Choose File Button
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scaleFactor,
                  vertical: 10 * scaleFactor,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(9.5 * scaleFactor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.upload_outlined,
                      size: 20 * scaleFactor,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8 * scaleFactor),
                    Text(
                      'Choose File',
                      style: TextStyle(
                        fontSize: 14 * scaleFactor,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirements(double scaleFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * scaleFactor),
      child: Container(
        padding: EdgeInsets.all(14 * scaleFactor),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(17 * scaleFactor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Icon
            Padding(
              padding: EdgeInsets.only(top: 2 * scaleFactor),
              child: Icon(
                Icons.info_outline,
                size: 19 * scaleFactor,
                color: const Color(0xFFE17100),
              ),
            ),
            SizedBox(width: 14 * scaleFactor),

            // Requirements List
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Requirements',
                    style: TextStyle(
                      fontSize: 17 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  SizedBox(height: 10 * scaleFactor),

                  _buildRequirementItem(
                    'Document should be valid and not expired',
                    scaleFactor,
                  ),
                  SizedBox(height: 5 * scaleFactor),

                  _buildRequirementItem(
                    'All corners of the ID must be visible',
                    scaleFactor,
                  ),
                  SizedBox(height: 5 * scaleFactor),

                  _buildRequirementItem(
                    'Text should be clear and readable',
                    scaleFactor,
                  ),
                  SizedBox(height: 5 * scaleFactor),

                  _buildRequirementItem(
                    'No glare or shadows on the document',
                    scaleFactor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text, double scaleFactor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 7 * scaleFactor),
          width: 5 * scaleFactor,
          height: 5 * scaleFactor,
          decoration: const BoxDecoration(
            color: Color(0xFFE17100),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 10 * scaleFactor),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14 * scaleFactor,
              color: const Color(0xFF4A5565),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(double scaleFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * scaleFactor),
      child: Column(
        children: [
          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 57 * scaleFactor,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17 * scaleFactor),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20 * scaleFactor,
                      width: 20 * scaleFactor,
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 19 * scaleFactor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          SizedBox(height: 12 * scaleFactor),

          // Back Button
          SizedBox(
            width: double.infinity,
            height: 57 * scaleFactor,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE1E1E1), width: 1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17 * scaleFactor),
                ),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: 19 * scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF959BA0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
