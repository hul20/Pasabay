import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/supabase_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _is24HourFormat = false;
  String _selectedCurrency = 'PHP';
  bool _isLoading = true;
  final SupabaseService _supabaseService = SupabaseService();

  final List<String> _currencies = [
    'PHP',
    'USD',
    'EUR',
    'JPY',
    'GBP',
    'AUD',
    'CAD',
    'SGD',
    'CNY',
    'KRW',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final userData = await _supabaseService.getUserData();
      if (userData != null && userData['preferences'] != null) {
        final prefs = userData['preferences'];
        if (mounted) {
          setState(() {
            _is24HourFormat = prefs['time_format'] == '24h';
            _selectedCurrency = prefs['currency'] ?? 'PHP';
            _notificationsEnabled = prefs['notifications_enabled'] ?? true;
          });
        }
      }
    } catch (e) {
      print('Error loading preferences: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _supabaseService.updateUserPreferences({
        'time_format': _is24HourFormat ? '24h' : '12h',
        'currency': _selectedCurrency,
        'notifications_enabled': _notificationsEnabled,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving preferences: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final scaleFactor = mediaQuery.textScaleFactor.clamp(1.0, 1.2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20 * scaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(20 * scaleFactor),
              children: [
                _buildSectionHeader('General', scaleFactor),
                _buildSwitchTile(
                  title: 'Notifications',
                  subtitle: 'Enable push notifications',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _savePreferences();
                  },
                  scaleFactor: scaleFactor,
                ),
                SizedBox(height: 24 * scaleFactor),
                _buildSectionHeader('Preferences', scaleFactor),
                _buildSwitchTile(
                  title: 'Time Format',
                  subtitle: _is24HourFormat
                      ? '24-hour (14:00)'
                      : '12-hour (2:00 PM)',
                  value: _is24HourFormat,
                  onChanged: (value) {
                    setState(() {
                      _is24HourFormat = value;
                    });
                    _savePreferences();
                  },
                  scaleFactor: scaleFactor,
                ),
                _buildDropdownTile(
                  title: 'Currency',
                  subtitle: 'Select preferred currency',
                  value: _selectedCurrency,
                  items: _currencies,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                      _savePreferences();
                    }
                  },
                  scaleFactor: scaleFactor,
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, double scaleFactor) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * scaleFactor),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16 * scaleFactor,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required double scaleFactor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16 * scaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14 * scaleFactor, color: Colors.grey[600]),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppConstants.primaryColor,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required double scaleFactor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16 * scaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14 * scaleFactor, color: Colors.grey[600]),
        ),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            icon: Icon(Icons.arrow_drop_down, color: AppConstants.primaryColor),
            style: TextStyle(
              color: Colors.black,
              fontSize: 16 * scaleFactor,
              fontWeight: FontWeight.w500,
            ),
            onChanged: onChanged,
            items: items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          ),
        ),
      ),
    );
  }
}
