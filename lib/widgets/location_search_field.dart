import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

/// Location search field with autocomplete suggestions
class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Color prefixIconColor;
  final Function(double lat, double lng)? onLocationSelected;

  const LocationSearchField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.prefixIcon = Icons.location_on_outlined,
    this.prefixIconColor = Colors.grey,
    this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  List<Location> _searchResults = [];
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.controller.text.length > 2) {
      _searchLocation(widget.controller.text);
    } else {
      _removeOverlay();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Delay to allow tap on suggestion
      Future.delayed(Duration(milliseconds: 200), () {
        _removeOverlay();
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      // Use geocoding to search for locations
      final locations = await locationFromAddress(query);
      
      if (mounted) {
        setState(() {
          _searchResults = locations.take(5).toList();
          _isSearching = false;
        });
        
        if (_searchResults.isNotEmpty) {
          _showOverlay();
        }
      }
    } catch (e) {
      print('Error searching location: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getTextFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final location = _searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on,
                      color: widget.prefixIconColor,
                      size: 20,
                    ),
                    title: Text(
                      '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      widget.controller.text,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      widget.onLocationSelected?.call(
                        location.latitude,
                        location.longitude,
                      );
                      _removeOverlay();
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getTextFieldWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            widget.prefixIcon,
            color: widget.prefixIconColor,
          ),
          suffixIcon: _isSearching
              ? Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.prefixIconColor,
                      ),
                    ),
                  ),
                )
              : widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 20),
                      onPressed: () {
                        widget.controller.clear();
                        _removeOverlay();
                      },
                    )
                  : null,
        ),
      ),
    );
  }
}

