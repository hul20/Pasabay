import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Custom input field with label, validation, and optional password visibility toggle
class CustomInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final double scaleFactor;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? confirmPasswordValue; // Used for confirm password validation

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.scaleFactor,
    this.isPassword = false,
    this.validator,
    this.keyboardType,
    this.confirmPasswordValue,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _obscureText = true;
  String? _errorText;

  void _validateField() {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16 * widget.scaleFactor,
            fontWeight: FontWeight.w500,
            color: AppConstants.textPrimaryColor,
          ),
        ),
        SizedBox(height: 8 * widget.scaleFactor),
        TextField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          onChanged: (_) {
            if (_errorText != null) {
              _validateField();
            }
          },
          onSubmitted: (_) => _validateField(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.inputBorderRadius,
              ),
              borderSide: BorderSide(
                color: _errorText != null
                    ? Colors.red
                    : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.inputBorderRadius,
              ),
              borderSide: BorderSide(
                color: _errorText != null
                    ? Colors.red
                    : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.inputBorderRadius,
              ),
              borderSide: BorderSide(
                color: _errorText != null
                    ? Colors.red
                    : AppConstants.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.inputBorderRadius,
              ),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.inputBorderRadius,
              ),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16 * widget.scaleFactor,
              vertical: 12 * widget.scaleFactor,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppConstants.textSecondaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
        if (_errorText != null) ...[
          SizedBox(height: 4 * widget.scaleFactor),
          Text(
            _errorText!,
            style: TextStyle(
              fontSize: 12 * widget.scaleFactor,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}
