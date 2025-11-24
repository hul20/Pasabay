import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/supabase_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleInitialController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  String? _currentProfileImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleInitialController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final supabaseService = SupabaseService();
    try {
      final userData = await supabaseService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _firstNameController.text = userData['first_name'] ?? '';
          _lastNameController.text = userData['last_name'] ?? '';
          _middleInitialController.text = userData['middle_initial'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone_number'] ?? '';
          _locationController.text = userData['location'] ?? '';
          _bioController.text = userData['bio'] ?? '';
          _currentProfileImageUrl = userData['profile_image_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

        return Container(
          padding: EdgeInsets.all(20 * scaleFactor),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18 * scaleFactor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16 * scaleFactor),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF00B4D8)),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF00B4D8)),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _chooseFromGallery();
                },
              ),
              if (_currentProfileImageUrl != null || _selectedImage != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = photo;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _chooseFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error choosing image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedImage = null;
      _currentProfileImageUrl = null;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabaseService = SupabaseService();
      String? profileImageUrl = _currentProfileImageUrl;

      // Upload new profile image if selected
      if (_selectedImage != null) {
        try {
          final userId = supabaseService.currentUser?.id;
          if (userId != null) {
            final fileName = 'profile_$userId.jpg';
            final imageBytes = await _selectedImage!.readAsBytes();
            final url = await supabaseService.uploadFile(
              'profile-images',
              fileName,
              imageBytes,
            );
            // Append timestamp to force cache refresh
            profileImageUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
          }
        } catch (uploadError) {
          print(
            'Photo upload failed, continuing with profile update: $uploadError',
          );
          // Continue with profile update even if photo upload fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Note: Profile photo could not be uploaded, but other info will be saved',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      // Update user data (profile info will update even if photo fails)
      final updateData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'middle_initial': _middleInitialController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'bio': _bioController.text.trim(),
        if (profileImageUrl != null && profileImageUrl.isNotEmpty)
          'profile_image_url': profileImageUrl,
      };

      await supabaseService.updateUserData(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(18 * scaleFactor),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 28 * scaleFactor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    width: 36 * scaleFactor,
                    height: 36 * scaleFactor,
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
                      fontSize: 18 * scaleFactor,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00B4D8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10 * scaleFactor),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20 * scaleFactor,
                        vertical: 10 * scaleFactor,
                      ),
                    ),
                    child: _isSaving
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
                        : Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 14 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24 * scaleFactor),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20 * scaleFactor),

                      // Profile Picture
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 140 * scaleFactor,
                              height: 140 * scaleFactor,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color(0xFF00B4D8),
                                  width: 3,
                                ),
                                color: Colors.grey[200],
                              ),
                              child: ClipOval(
                                child: _selectedImage != null
                                    ? (kIsWeb
                                          ? Image.network(
                                              _selectedImage!.path,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(_selectedImage!.path),
                                              fit: BoxFit.cover,
                                            ))
                                    : _currentProfileImageUrl != null
                                    ? Image.network(
                                        _currentProfileImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Icon(
                                                Icons.person,
                                                size: 60 * scaleFactor,
                                                color: Colors.grey,
                                              );
                                            },
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 60 * scaleFactor,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(8 * scaleFactor),
                                decoration: BoxDecoration(
                                  color: Color(0xFF00B4D8),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20 * scaleFactor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32 * scaleFactor),

                      // Full Name Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 8 * scaleFactor),

                      // First Name
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                        scaleFactor: scaleFactor,
                      ),

                      SizedBox(height: 12 * scaleFactor),

                      // Last Name
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                        scaleFactor: scaleFactor,
                      ),

                      SizedBox(height: 12 * scaleFactor),

                      // Middle Initial
                      _buildTextField(
                        controller: _middleInitialController,
                        label: 'Middle Initial (Optional)',
                        maxLength: 1,
                        scaleFactor: scaleFactor,
                      ),

                      SizedBox(height: 24 * scaleFactor),

                      // Email Address (Read-only)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 8 * scaleFactor),
                      Container(
                        padding: EdgeInsets.all(16 * scaleFactor),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12 * scaleFactor),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _emailController.text,
                                style: TextStyle(
                                  fontSize: 15 * scaleFactor,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Icon(
                              Icons.lock,
                              size: 20 * scaleFactor,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24 * scaleFactor),

                      // Phone Number
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 8 * scaleFactor),
                      _buildTextField(
                        controller: _phoneController,
                        label: '+63 917 123 4567',
                        keyboardType: TextInputType.phone,
                        scaleFactor: scaleFactor,
                      ),

                      SizedBox(height: 24 * scaleFactor),

                      // Location
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 8 * scaleFactor),
                      _buildTextField(
                        controller: _locationController,
                        label: 'Mandurriao, Iloilo City, Philippines',
                        scaleFactor: scaleFactor,
                      ),

                      SizedBox(height: 24 * scaleFactor),

                      // Biography
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Biography',
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 8 * scaleFactor),
                      _buildTextField(
                        controller: _bioController,
                        label:
                            '22-Year-Old Student Studying Bachelor of Science in Computer Science',
                        maxLines: 3,
                        scaleFactor: scaleFactor,
                      ),

                      SizedBox(height: 40 * scaleFactor),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    required double scaleFactor,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(fontSize: 15 * scaleFactor),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14 * scaleFactor,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12 * scaleFactor),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12 * scaleFactor),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12 * scaleFactor),
          borderSide: BorderSide(color: Color(0xFF00B4D8), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12 * scaleFactor),
          borderSide: BorderSide(color: Colors.red),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * scaleFactor,
          vertical: 16 * scaleFactor,
        ),
        counterText: '',
      ),
    );
  }
}
