import 'package:flutter/material.dart';

import '../services/image_service.dart';

class LocationCard extends StatefulWidget {
  final String location;
  final bool isCurrentLocation;
  final bool isCrossedOut;
  final VoidCallback onTap;

  const LocationCard({
    super.key,
    required this.location,
    required this.isCurrentLocation,
    required this.isCrossedOut,
    required this.onTap,
  });

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  String? _imagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final path = await ImageService.getLocationImagePath(widget.location);
      if (mounted) {
        setState(() {
          _imagePath = path;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: widget.isCrossedOut
            ? Colors.red[100]
            : (widget.isCurrentLocation
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null),
        child: Stack(
          children: [
            // Background image
            if (_imagePath != null && !_isLoading)
              Positioned.fill(
                child: Image.asset(
                  _imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    );
                  },
                ),
              ),

            // Loading indicator
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),

            // Overlay for text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: Stack(
                  children: [
                    Text(
                      widget.location,
                      style: TextStyle(
                        fontWeight: widget.isCurrentLocation
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 14,
                        color: widget.isCrossedOut
                            ? Colors.red[800]
                            : Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    if (widget.isCrossedOut)
                      Positioned.fill(
                        child: Icon(
                          Icons.close,
                          size: 48,
                          color: Colors.red[800]!.withOpacity(0.9),
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
}
