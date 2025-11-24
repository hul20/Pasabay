import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../models/trip.dart';
import '../../services/request_service.dart';

class TravelerDetailPage extends StatefulWidget {
  final Trip trip;
  final Map<String, dynamic> travelerInfo;

  const TravelerDetailPage({
    super.key,
    required this.trip,
    required this.travelerInfo,
  });

  @override
  State<TravelerDetailPage> createState() => _TravelerDetailPageState();
}

class _TravelerDetailPageState extends State<TravelerDetailPage> {
  String? _selectedServiceType; // 'Pabakal' or 'Pasabay'
  bool _isSubmitting = false;

  // Pabakal fields
  final _productNameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeLocationController = TextEditingController();
  final _costController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Pasabay fields
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  final _claimTimeController = TextEditingController();
  final _packageDescriptionController = TextEditingController();

  // File attachments
  final ImagePicker _imagePicker = ImagePicker();
  final RequestService _requestService = RequestService();
  final _supabase = Supabase.instance.client;
  List<File> _attachedImages = [];
  List<String> _uploadedPhotoUrls = [];

  double get _serviceFee {
    // Base service fee calculation
    // Could be based on distance, product cost, etc.
    if (_selectedServiceType == 'Pabakal') {
      final productCost = double.tryParse(_costController.text) ?? 0;
      return productCost * 0.10; // 10% service fee
    } else if (_selectedServiceType == 'Pasabay') {
      return 50.0; // Flat rate for pasabay
    }
    return 0.0;
  }

  double get _totalAmount {
    final productCost = double.tryParse(_costController.text) ?? 0;
    return productCost + _serviceFee;
  }

  @override
  void initState() {
    super.initState();
    // Show service type dialog after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showServiceTypeDialog();
    });
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _storeNameController.dispose();
    _storeLocationController.dispose();
    _costController.dispose();
    _descriptionController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _claimTimeController.dispose();
    _packageDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _attachedImages.add(File(photo.path));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo added successfully'),
            backgroundColor: Colors.green,
          ),
        );
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _attachedImages.add(File(image.path));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPhotoOptions() {
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
                  _pickImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showServiceTypeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24 * scaleFactor),
              topRight: Radius.circular(24 * scaleFactor),
            ),
          ),
          padding: EdgeInsets.all(24 * scaleFactor),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, size: 28 * scaleFactor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(height: 8 * scaleFactor),
              Text(
                'Choose Service Type',
                style: TextStyle(
                  fontSize: 24 * scaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 24 * scaleFactor),

              // Pabakal Option
              GestureDetector(
                onTap: () {
                  setState(() => _selectedServiceType = 'Pabakal');
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(20 * scaleFactor),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pabakal',
                            style: TextStyle(
                              fontSize: 22 * scaleFactor,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '(Pasabuy)',
                            style: TextStyle(
                              fontSize: 14 * scaleFactor,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Icon(
                        Icons.shopping_bag,
                        color: Color(0xFF00B4D8),
                        size: 48 * scaleFactor,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16 * scaleFactor),

              // Pasabay Option
              GestureDetector(
                onTap: () {
                  setState(() => _selectedServiceType = 'Pasabay');
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(20 * scaleFactor),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Pasabay',
                        style: TextStyle(
                          fontSize: 22 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.local_shipping_outlined,
                        color: Color(0xFF00B4D8),
                        size: 48 * scaleFactor,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24 * scaleFactor),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadFiles() async {
    // Upload images
    for (var imageFile in _attachedImages) {
      try {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final filePath = 'request_photos/$fileName';

        await _supabase.storage.from('attachments').upload(filePath, imageFile);

        final publicUrl = _supabase.storage
            .from('attachments')
            .getPublicUrl(filePath);

        _uploadedPhotoUrls.add(publicUrl);
      } catch (e) {
        print('❌ Error uploading image: $e');
      }
    }
  }

  Future<void> _submitRequest() async {
    // Validate inputs
    if (_selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a service type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate based on service type
    if (_selectedServiceType == 'Pabakal') {
      if (_productNameController.text.isEmpty ||
          _storeLocationController.text.isEmpty ||
          _costController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate cost
      if (double.tryParse(_costController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid cost'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (_selectedServiceType == 'Pasabay') {
      if (_recipientNameController.text.isEmpty ||
          _recipientPhoneController.text.isEmpty ||
          _dropoffLocationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Start submission
    setState(() => _isSubmitting = true);

    try {
      // Upload files first
      if (_attachedImages.isNotEmpty) {
        await _uploadFiles();
      }

      // Create request based on service type
      bool success = false;

      if (_selectedServiceType == 'Pabakal') {
        success = await _requestService.createRequest(
          travelerId: widget.trip.travelerId,
          tripId: widget.trip.id,
          serviceType: 'Pabakal',
          productName: _productNameController.text.trim(),
          storeName: _storeNameController.text.trim(),
          storeLocation: _storeLocationController.text.trim(),
          productCost: double.parse(_costController.text),
          productDescription: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          serviceFee: _serviceFee,
          photoUrls: _uploadedPhotoUrls.isNotEmpty ? _uploadedPhotoUrls : null,
        );
      } else if (_selectedServiceType == 'Pasabay') {
        print('📮 Creating Pasabay request...');
        success = await _requestService.createRequest(
          travelerId: widget.trip.travelerId,
          tripId: widget.trip.id,
          serviceType: 'Pasabay',
          recipientName: _recipientNameController.text.trim(),
          recipientPhone: _recipientPhoneController.text.trim(),
          pickupLocation: _pickupLocationController.text.trim().isNotEmpty
              ? _pickupLocationController.text.trim()
              : null,
          dropoffLocation: _dropoffLocationController.text.trim(),
          pickupTime: _claimTimeController.text.isNotEmpty
              ? _parseTime(_claimTimeController.text)
              : null,
          packageDescription:
              _packageDescriptionController.text.trim().isNotEmpty
              ? _packageDescriptionController.text.trim()
              : null,
          serviceFee: _serviceFee,
          photoUrls: _uploadedPhotoUrls.isNotEmpty ? _uploadedPhotoUrls : null,
        );
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        print('✅ Request submitted successfully!');
        // Show success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RequestSentScreen()),
        );
      } else {
        print('❌ Request submission failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Exception during submission: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  DateTime? _parseTime(String timeString) {
    try {
      // Parse time string like "2:30 PM"
      final now = DateTime.now();
      final timeParts = timeString.split(' ');
      final hourMinute = timeParts[0].split(':');
      int hour = int.parse(hourMinute[0]);
      final minute = int.parse(hourMinute[1]);

      if (timeParts.length > 1 &&
          timeParts[1].toUpperCase() == 'PM' &&
          hour != 12) {
        hour += 12;
      } else if (timeParts.length > 1 &&
          timeParts[1].toUpperCase() == 'AM' &&
          hour == 12) {
        hour = 0;
      }

      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      print('❌ Error parsing time: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

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
                  GestureDetector(
                    onTap: _showServiceTypeDialog,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * scaleFactor,
                        vertical: 8 * scaleFactor,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF00B4D8),
                        borderRadius: BorderRadius.circular(10 * scaleFactor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedServiceType == 'Pabakal'
                                ? Icons.shopping_bag
                                : _selectedServiceType == 'Pasabay'
                                ? Icons.local_shipping_outlined
                                : Icons.shopping_bag,
                            color: Colors.white,
                            size: 20 * scaleFactor,
                          ),
                          SizedBox(width: 6 * scaleFactor),
                          Text(
                            _selectedServiceType ?? 'Select Service',
                            style: TextStyle(
                              fontSize: 14 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Traveler Info Card
                    Container(
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipOval(
                                child:
                                    widget.travelerInfo['profile_image_url'] !=
                                        null
                                    ? Image.network(
                                        widget
                                            .travelerInfo['profile_image_url'],
                                        width: 80 * scaleFactor,
                                        height: 80 * scaleFactor,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                width: 80 * scaleFactor,
                                                height: 80 * scaleFactor,
                                                color: Color(0xFF00B4D8),
                                                child: Icon(
                                                  Icons.person,
                                                  size: 40 * scaleFactor,
                                                  color: Colors.white,
                                                ),
                                              );
                                            },
                                      )
                                    : Container(
                                        width: 80 * scaleFactor,
                                        height: 80 * scaleFactor,
                                        color: Color(0xFF00B4D8),
                                        child: Icon(
                                          Icons.person,
                                          size: 40 * scaleFactor,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                              SizedBox(width: 16 * scaleFactor),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Traveler',
                                      style: TextStyle(
                                        fontSize: 12 * scaleFactor,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4 * scaleFactor),
                                    Text(
                                      '${widget.travelerInfo['first_name']} ${widget.travelerInfo['last_name']}',
                                      style: TextStyle(
                                        fontSize: 20 * scaleFactor,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4 * scaleFactor),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16 * scaleFactor,
                                        ),
                                        SizedBox(width: 4 * scaleFactor),
                                        Text(
                                          '4.8',
                                          style: TextStyle(
                                            fontSize: 13 * scaleFactor,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16 * scaleFactor),
                          Divider(height: 1, color: Colors.grey[200]),
                          SizedBox(height: 16 * scaleFactor),

                          // Trip details
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Route',
                                      style: TextStyle(
                                        fontSize: 12 * scaleFactor,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4 * scaleFactor),
                                    Text(
                                      '${widget.trip.departureLocation} → ${widget.trip.destinationLocation}',
                                      style: TextStyle(
                                        fontSize: 14 * scaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12 * scaleFactor),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: 12 * scaleFactor,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4 * scaleFactor),
                                    Text(
                                      DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(widget.trip.departureDate),
                                      style: TextStyle(
                                        fontSize: 14 * scaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time',
                                      style: TextStyle(
                                        fontSize: 12 * scaleFactor,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4 * scaleFactor),
                                    Text(
                                      widget.trip.departureTime,
                                      style: TextStyle(
                                        fontSize: 14 * scaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24 * scaleFactor),

                    // Primary Details Section
                    Text(
                      'Primary Details',
                      style: TextStyle(
                        fontSize: 16 * scaleFactor,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),

                    SizedBox(height: 16 * scaleFactor),

                    // Show different forms based on service type
                    if (_selectedServiceType == 'Pabakal') ...[
                      // PABAKAL FORM
                      _buildInputField(
                        label: 'Product Name',
                        hint: 'Enter Specific Brand Name',
                        controller: _productNameController,
                        scaleFactor: scaleFactor,
                      ),
                      SizedBox(height: 16 * scaleFactor),
                      _buildInputField(
                        label: 'Store Name',
                        hint: 'Enter Store Name (e.g., SM City Iloilo)',
                        controller: _storeNameController,
                        scaleFactor: scaleFactor,
                      ),
                      SizedBox(height: 16 * scaleFactor),
                      _buildInputField(
                        label: 'Store Location',
                        hint: 'Enter Complete Address',
                        controller: _storeLocationController,
                        scaleFactor: scaleFactor,
                      ),
                      SizedBox(height: 16 * scaleFactor),
                      _buildInputField(
                        label: 'Cost in Philippine Peso',
                        hint: 'Enter Exact Cost',
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        scaleFactor: scaleFactor,
                      ),
                      SizedBox(height: 16 * scaleFactor),
                      _buildInputField(
                        label: 'Additional Description',
                        hint: 'Enter Additional Details',
                        controller: _descriptionController,
                        maxLines: 4,
                        scaleFactor: scaleFactor,
                      ),
                    ] else if (_selectedServiceType == 'Pasabay') ...[
                      // PASABAY FORM
                      _buildInputField(
                        label: 'Recipient Name',
                        hint: 'Enter full name of recipient',
                        controller: _recipientNameController,
                        scaleFactor: scaleFactor,
                      ),
                      SizedBox(height: 16 * scaleFactor),
                      _buildInputField(
                        label: 'Recipient Phone Number',
                        hint: 'Enter phone number (e.g., 09123456789)',
                        controller: _recipientPhoneController,
                        keyboardType: TextInputType.phone,
                        scaleFactor: scaleFactor,
                      ),
                      SizedBox(height: 16 * scaleFactor),
                      _buildInputField(
                        label: 'Pickup Location (Optional)',
                        hint: 'Where will the package be picked up?',
                        controller: _pickupLocationController,
                        maxLines: 2,
                        scaleFactor: scaleFactor,
                      ),
                      SizedBox(height: 16 * scaleFactor),
                      _buildInputField(
                        label: 'Drop-off Location',
                        hint: 'Enter complete delivery address',
                        controller: _dropoffLocationController,
                        maxLines: 2,
                        scaleFactor: scaleFactor,
                      ),
                      SizedBox(height: 16 * scaleFactor),
                      GestureDetector(
                        onTap: () async {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              _claimTimeController.text = pickedTime.format(
                                context,
                              );
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: _buildInputField(
                            label: 'Preferred Delivery Time (Optional)',
                            hint: 'Select time',
                            controller: _claimTimeController,
                            scaleFactor: scaleFactor,
                            suffixIcon: Icons.access_time,
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * scaleFactor),
                      _buildInputField(
                        label: 'Package Description (Optional)',
                        hint: 'Describe the package contents',
                        controller: _packageDescriptionController,
                        maxLines: 3,
                        scaleFactor: scaleFactor,
                      ),
                    ] else ...[
                      // No service selected
                      Container(
                        padding: EdgeInsets.all(20 * scaleFactor),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12 * scaleFactor),
                        ),
                        child: Center(
                          child: Text(
                            'Please select a service type first',
                            style: TextStyle(
                              fontSize: 14 * scaleFactor,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 24 * scaleFactor),

                    // Attachments Section
                    Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 16 * scaleFactor,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),

                    SizedBox(height: 16 * scaleFactor),

                    // Attachment Buttons
                    SizedBox(
                      width: double.infinity,
                      child: _buildAttachmentButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Take A Photo',
                        onTap: _showPhotoOptions,
                        scaleFactor: scaleFactor,
                        count: _attachedImages.length,
                      ),
                    ),

                    // Show attached files
                    if (_attachedImages.isNotEmpty) ...[
                      SizedBox(height: 16 * scaleFactor),
                      Text(
                        'Attached Files (${_attachedImages.length})',
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8 * scaleFactor),
                      Wrap(
                        spacing: 8 * scaleFactor,
                        runSpacing: 8 * scaleFactor,
                        children: [
                          ..._attachedImages.map(
                            (file) => _buildFileChip(
                              file.path.split('/').last,
                              true,
                              () =>
                                  setState(() => _attachedImages.remove(file)),
                              scaleFactor,
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: 24 * scaleFactor),

                    // Total Fee and Submit Button
                    if (_selectedServiceType != null) ...[
                      Container(
                        padding: EdgeInsets.all(16 * scaleFactor),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12 * scaleFactor),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            if (_selectedServiceType == 'Pabakal') ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Product Cost',
                                    style: TextStyle(
                                      fontSize: 14 * scaleFactor,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '₱${_costController.text.isEmpty ? "0" : _costController.text}',
                                    style: TextStyle(
                                      fontSize: 14 * scaleFactor,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
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
                                  'Service Fee',
                                  style: TextStyle(
                                    fontSize: 14 * scaleFactor,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₱${_serviceFee.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14 * scaleFactor,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedServiceType == 'Pabakal') ...[
                              Divider(
                                height: 24 * scaleFactor,
                                color: Colors.grey[300],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    '₱${_totalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20 * scaleFactor,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00B4D8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 16 * scaleFactor),

                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00B4D8),
                          disabledBackgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 16 * scaleFactor,
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                height: 20 * scaleFactor,
                                width: 20 * scaleFactor,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 20 * scaleFactor,
                                  ),
                                  SizedBox(width: 8 * scaleFactor),
                                  Text(
                                    'Submit Request',
                                    style: TextStyle(
                                      fontSize: 16 * scaleFactor,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],

                    SizedBox(height: 32 * scaleFactor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? suffixIcon,
    required double scaleFactor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15 * scaleFactor,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8 * scaleFactor),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scaleFactor,
            vertical: 4 * scaleFactor,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12 * scaleFactor),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(fontSize: 15 * scaleFactor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14 * scaleFactor,
              ),
              border: InputBorder.none,
              suffixIcon: suffixIcon != null
                  ? Icon(suffixIcon, color: Colors.grey[600])
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double scaleFactor,
    int count = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20 * scaleFactor),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12 * scaleFactor),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Icon(icon, color: Color(0xFF00B4D8), size: 48 * scaleFactor),
                if (count > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.all(4 * scaleFactor),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10 * scaleFactor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12 * scaleFactor),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileChip(
    String fileName,
    bool isImage,
    VoidCallback onRemove,
    double scaleFactor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scaleFactor,
        vertical: 8 * scaleFactor,
      ),
      decoration: BoxDecoration(
        color: Color(0xFF00B4D8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20 * scaleFactor),
        border: Border.all(color: Color(0xFF00B4D8).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImage ? Icons.image : Icons.insert_drive_file,
            size: 16 * scaleFactor,
            color: Color(0xFF00B4D8),
          ),
          SizedBox(width: 6 * scaleFactor),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 150 * scaleFactor),
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12 * scaleFactor,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(width: 6 * scaleFactor),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 16 * scaleFactor, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

// Request Sent Success Screen
class RequestSentScreen extends StatelessWidget {
  const RequestSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24 * scaleFactor),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 28 * scaleFactor),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
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
                ],
              ),

              Spacer(),

              // Success Icon
              Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF00B4D8),
                size: 120 * scaleFactor,
              ),

              SizedBox(height: 32 * scaleFactor),

              // Success Message
              Text(
                'Request Sent',
                style: TextStyle(
                  fontSize: 36 * scaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B4D8),
                ),
              ),

              SizedBox(height: 16 * scaleFactor),

              Text(
                'We\'ll let you know when the traveler',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16 * scaleFactor,
                  color: Colors.black,
                ),
              ),
              Text(
                'accepted your request',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16 * scaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
