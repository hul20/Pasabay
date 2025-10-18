import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'review_documents_screen.dart';

class SelfieUploadScreen extends StatefulWidget {
  final File? governmentIdFile;
  final String? governmentIdFileName;

  const SelfieUploadScreen({
    super.key,
    this.governmentIdFile,
    this.governmentIdFileName,
  });

  @override
  State<SelfieUploadScreen> createState() => _SelfieUploadScreenState();
}

class _SelfieUploadScreenState extends State<SelfieUploadScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _continue() {
    // TODO: Re-enable validation for production
    // For testing: Allow proceeding without photo capture
    /* if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a selfie or upload a photo first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    } */

    // Navigate to Step 3 (Review & Submit)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewDocumentsScreen(
          governmentIdFile: widget.governmentIdFile,
          selfieFile: _selectedImage,
          governmentIdFileName: widget.governmentIdFileName,
          selfieFileName:
              _selectedImage?.path.split('/').last ??
              _selectedImage?.path.split('\\').last,
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

                        // Camera/Upload Area
                        _buildCameraArea(scaleFactor),

                        SizedBox(height: 20 * scaleFactor),

                        // Photo Guidelines
                        _buildGuidelines(scaleFactor),

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
                  // Progress Line Background
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
                  // Progress Line Filled (Step 1 completed)
                  Positioned(
                    left: 47 * scaleFactor,
                    child: Container(
                      width: 159 * scaleFactor,
                      height: 5 * scaleFactor,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5 * scaleFactor),
                      ),
                    ),
                  ),
                  // Progress Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Step 1 - Completed
                      _buildProgressDot(
                        isActive: false,
                        isCompleted: true,
                        size: 38 * scaleFactor,
                        borderColor: const Color(0xFF01ABF3),
                        showCheckmark: true,
                      ),
                      // Step 2 - Active
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildProgressDot(
                            isActive: false,
                            isCompleted: false,
                            size: 29 * scaleFactor,
                            borderColor: const Color(0xFF358EB4),
                          ),
                          _buildProgressDot(
                            isActive: true,
                            isCompleted: false,
                            size: 38 * scaleFactor,
                            borderColor: const Color(0xFF1AB4F5),
                          ),
                        ],
                      ),
                      // Step 3
                      _buildProgressDot(
                        isActive: false,
                        isCompleted: false,
                        size: 29 * scaleFactor,
                        borderColor: const Color(0xFF43C3FA),
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
                    const TextSpan(text: 'Take a\n'),
                    TextSpan(
                      text: 'Selfie Picture',
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
    bool showCheckmark = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white
            : (isCompleted ? const Color(0xFF65AAC6) : const Color(0xFF6BCFFB)),
        border: Border.all(color: borderColor, width: 6),
        shape: BoxShape.circle,
      ),
      child: showCheckmark
          ? Icon(Icons.check, size: size * 0.5, color: Colors.white)
          : null,
    );
  }

  Widget _buildCameraArea(double scaleFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * scaleFactor),
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
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(19 * scaleFactor),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Camera Icon
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 58 * scaleFactor,
                    color: const Color(0xFF9CA3AF),
                  ),

                  SizedBox(height: 16 * scaleFactor),

                  // Instruction Text
                  Text(
                    'Position your face in the frame',
                    style: TextStyle(
                      fontSize: 17 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF464646),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 8 * scaleFactor),

                  Text(
                    'Make sure your face is clearly visible',
                    style: TextStyle(
                      fontSize: 14 * scaleFactor,
                      color: const Color(0xFF464646),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 16 * scaleFactor),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Take A Photo Button
                      GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          width: 147 * scaleFactor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scaleFactor,
                            vertical: 10 * scaleFactor,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(
                              9.5 * scaleFactor,
                            ),
                          ),
                          child: Text(
                            'Take A Photo',
                            style: TextStyle(
                              fontSize: 14 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      SizedBox(width: 10 * scaleFactor),

                      // Upload Button
                      GestureDetector(
                        onTap: _uploadPhoto,
                        child: Container(
                          width: 128 * scaleFactor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scaleFactor,
                            vertical: 10 * scaleFactor,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              9.5 * scaleFactor,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Upload',
                            style: TextStyle(
                              fontSize: 14 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF959BA0),
                            ),
                            textAlign: TextAlign.center,
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

  Widget _buildGuidelines(double scaleFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * scaleFactor),
      child: Container(
        padding: EdgeInsets.all(14 * scaleFactor),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(17 * scaleFactor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Icon
            Padding(
              padding: EdgeInsets.only(top: 2 * scaleFactor),
              child: Icon(
                Icons.info_outline,
                size: 19 * scaleFactor,
                color: AppConstants.primaryColor,
              ),
            ),
            SizedBox(width: 14 * scaleFactor),

            // Guidelines List
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photo Guidelines',
                    style: TextStyle(
                      fontSize: 17 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  SizedBox(height: 10 * scaleFactor),

                  _buildGuidelineItem(
                    '• Look directly at the camera',
                    scaleFactor,
                  ),
                  SizedBox(height: 5 * scaleFactor),

                  _buildGuidelineItem(
                    '• Ensure good lighting on your face',
                    scaleFactor,
                  ),
                  SizedBox(height: 5 * scaleFactor),

                  _buildGuidelineItem(
                    '• Remove glasses, hats, or face coverings',
                    scaleFactor,
                  ),
                  SizedBox(height: 5 * scaleFactor),

                  _buildGuidelineItem(
                    '• Use a plain background if possible',
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

  Widget _buildGuidelineItem(String text, double scaleFactor) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14 * scaleFactor,
        color: const Color(0xFF4A5565),
        height: 1.3,
      ),
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
