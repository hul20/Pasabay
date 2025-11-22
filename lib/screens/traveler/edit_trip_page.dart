import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';

class EditTripPage extends StatefulWidget {
  final Trip trip;

  const EditTripPage({Key? key, required this.trip}) : super(key: key);

  @override
  State<EditTripPage> createState() => _EditTripPageState();
}

class _EditTripPageState extends State<EditTripPage> {
  final TripService _tripService = TripService();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _availableCapacity = 5;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  void _loadTripData() {
    _departureController.text = widget.trip.departureLocation;
    _destinationController.text = widget.trip.destinationLocation;
    _notesController.text = widget.trip.notes ?? '';
    _selectedDate = widget.trip.departureDate;
    _availableCapacity = widget.trip.availableCapacity;
    
    // Parse time from string (HH:mm:ss)
    final timeParts = widget.trip.departureTime.split(':');
    if (timeParts.length >= 2) {
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
  }

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    // Validation
    if (_departureController.text.isEmpty) {
      _showSnackBar('Please enter departure location', Colors.orange);
      return;
    }
    
    if (_destinationController.text.isEmpty) {
      _showSnackBar('Please enter destination location', Colors.orange);
      return;
    }
    
    if (_selectedDate == null) {
      _showSnackBar('Please select departure date', Colors.orange);
      return;
    }
    
    if (_selectedTime == null) {
      _showSnackBar('Please select departure time', Colors.orange);
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // Format time
      final timeString = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';
      
      await _tripService.updateTrip(
        tripId: widget.trip.id,
        departureLocation: _departureController.text.trim(),
        destinationLocation: _destinationController.text.trim(),
        departureDate: _selectedDate!,
        departureTime: timeString,
        availableCapacity: _availableCapacity,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context, true); // Return to activity page with success
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showSnackBar('Failed to update trip: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Edit Trip'),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20 * scaleFactor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Departure Location
                Text(
                  'Departure Location',
                  style: TextStyle(
                    fontSize: 16 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8 * scaleFactor),
                TextField(
                  controller: _departureController,
                  decoration: InputDecoration(
                    hintText: 'Enter departure location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                    ),
                    prefixIcon: Icon(Icons.location_on, color: Colors.green),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                SizedBox(height: 20 * scaleFactor),

                // Destination Location
                Text(
                  'Destination Location',
                  style: TextStyle(
                    fontSize: 16 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8 * scaleFactor),
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    hintText: 'Enter destination location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                    ),
                    prefixIcon: Icon(Icons.place, color: Colors.red),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                SizedBox(height: 20 * scaleFactor),

                // Date & Time
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Departure Date',
                            style: TextStyle(
                              fontSize: 16 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8 * scaleFactor),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12 * scaleFactor),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
                            ),
                            icon: Icon(Icons.calendar_today),
                            label: Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                            ),
                            onPressed: _selectDate,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12 * scaleFactor),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: TextStyle(
                              fontSize: 16 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8 * scaleFactor),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12 * scaleFactor),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
                            ),
                            icon: Icon(Icons.access_time),
                            label: Text(
                              _selectedTime == null
                                  ? 'Select Time'
                                  : _selectedTime!.format(context),
                            ),
                            onPressed: _selectTime,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20 * scaleFactor),

                // Capacity
                Text(
                  'Available Capacity',
                  style: TextStyle(
                    fontSize: 16 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8 * scaleFactor),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (_availableCapacity > 1) {
                          setState(() {
                            _availableCapacity--;
                          });
                        }
                      },
                      color: AppConstants.primaryColor,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24 * scaleFactor,
                        vertical: 12 * scaleFactor,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                      ),
                      child: Text(
                        _availableCapacity.toString(),
                        style: TextStyle(
                          fontSize: 20 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      onPressed: () {
                        if (_availableCapacity < 10) {
                          setState(() {
                            _availableCapacity++;
                          });
                        }
                      },
                      color: AppConstants.primaryColor,
                    ),
                    Spacer(),
                    Text(
                      'requests',
                      style: TextStyle(
                        fontSize: 14 * scaleFactor,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20 * scaleFactor),

                // Notes
                Text(
                  'Notes (Optional)',
                  style: TextStyle(
                    fontSize: 16 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8 * scaleFactor),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add any additional notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                SizedBox(height: 30 * scaleFactor),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 54 * scaleFactor,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16 * scaleFactor),
                      ),
                    ),
                    onPressed: _saveChanges,
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 18 * scaleFactor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

