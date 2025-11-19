import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io' show Platform;
import '../../widgets/responsive_wrapper.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/supabase_service.dart';
import 'review_documents_screen.dart';

class SelfieUploadScreen extends StatefulWidget {
  final String governmentIdUrl;
  final String governmentIdFileName;

  const SelfieUploadScreen({
    super.key,
    required this.governmentIdUrl,
    required this.governmentIdFileName,
  });

  @override
  State<SelfieUploadScreen> createState() => _SelfieUploadScreenState();
}

class _SelfieUploadScreenState extends State<SelfieUploadScreen> {
  Uint8List? _selectedImageBytes;
  String? _selfieFileName;
  bool _isLoading = false;
  String? _uploadedUrl;
  final ImagePicker _picker = ImagePicker();
  final _supabaseService = SupabaseService();

  /// Check if platform supports camera
  bool get _isCameraSupported {
    if (kIsWeb) return true; // Web browsers support camera
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    } catch (e) {
      return false;
    }
  }

  /// Take photo with platform-specific handling
  Future<void> _takePhoto() async {
    try {
      setState(() {
        _isLoading = true;
      });

      XFile? photo;

      // Check if camera is supported on this platform
      if (_isCameraSupported) {
        // Use camera for supported platforms (Android, iOS, macOS, Web)
        photo = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );
      } else {
        // For Windows/Linux/unsupported platforms, use gallery instead
        // Show a message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Camera not available. Please select an image from gallery.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Open gallery/file picker instead
        photo = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );
      }

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final fileName = 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Upload to Supabase Storage
        final url = await _supabaseService.uploadSelfie(bytes, fileName);

        setState(() {
          _selectedImageBytes = bytes;
          _selfieFileName = fileName;
          _uploadedUrl = url;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // User cancelled
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        String errorMessage = 'Error taking photo: $e';

        // Provide helpful message based on error type
        if (e.toString().contains('permission') ||
            e.toString().contains('denied')) {
          errorMessage =
              'Camera permission denied. Please enable camera access in your device settings.';
        } else if (e.toString().contains('camera')) {
          errorMessage =
              'Camera not available. Please use the Upload button to select an image.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto() async {
    try {
      setState(() {
        _isLoading = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        final bytes = result.files.single.bytes;
        final fileName = result.files.single.name;

        if (bytes == null) {
          throw 'Failed to read file';
        }

        // Upload to Supabase Storage
        final url = await _supabaseService.uploadSelfie(bytes, fileName);

        setState(() {
          _selectedImageBytes = bytes;
          _selfieFileName = fileName;
          _uploadedUrl = url;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
    if (_selectedImageBytes == null || _uploadedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a selfie or upload a photo first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to Step 3 (Review & Submit)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewDocumentsScreen(
          governmentIdUrl: widget.governmentIdUrl,
          selfieUrl: _uploadedUrl!,
          governmentIdFileName: widget.governmentIdFileName,
          selfieFileName: _selfieFileName!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

            return ResponsiveWrapper(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: 60 * scaleFactor,
                ), // Increased padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gradient Header with Progress
                    _buildGradientHeader(scaleFactor),

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
            );
          },
        ),
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
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppConstants.primaryColor,
                      ),
                    ),
                    SizedBox(height: 16 * scaleFactor),
                    Text(
                      'Uploading...',
                      style: TextStyle(
                        fontSize: 16 * scaleFactor,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              )
            : _selectedImageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(19 * scaleFactor),
                child: Stack(
                  children: [
                    Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    // Success overlay
                    Positioned(
                      top: 10 * scaleFactor,
                      right: 10 * scaleFactor,
                      child: Container(
                        padding: EdgeInsets.all(8 * scaleFactor),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20 * scaleFactor,
                        ),
                      ),
                    ),
                  ],
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
                        onTap: _isLoading ? null : _takePhoto,
                        child: Container(
                          width: 147 * scaleFactor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scaleFactor,
                            vertical: 10 * scaleFactor,
                          ),
                          decoration: BoxDecoration(
                            color: _isLoading
                                ? AppConstants.primaryColor.withOpacity(0.5)
                                : AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(
                              9.5 * scaleFactor,
                            ),
                          ),
                          child: Text(
                            _isCameraSupported
                                ? 'Take A Photo'
                                : 'Select Photo',
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
                        onTap: _isLoading ? null : _uploadPhoto,
                        child: Container(
                          width: 128 * scaleFactor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scaleFactor,
                            vertical: 10 * scaleFactor,
                          ),
                          decoration: BoxDecoration(
                            color: _isLoading
                                ? Colors.grey.shade300
                                : Colors.white,
                            borderRadius: BorderRadius.circular(
                              9.5 * scaleFactor,
                            ),
                            boxShadow: _isLoading
                                ? []
                                : [
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
