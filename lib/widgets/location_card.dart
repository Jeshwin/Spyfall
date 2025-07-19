import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/image_service.dart';
import 'cross_painter.dart';

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
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFFFFFFF),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 16,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 6),
              child: Column(
                children: [
                  Stack(
                    children: [
                      // Background image
                      if (_imagePath != null && !_isLoading)
                        AspectRatio(
                          aspectRatio: 1,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Content
                  const SizedBox(height: 6),
                  Text(
                    widget.location,
                    style: GoogleFonts.getFont(
                      'Delicious Handrawn',
                      textStyle: TextStyle(fontSize: 16, height: 1.3),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            // Crossed-out location
            if (widget.isCrossedOut)
              Positioned.fill(
                child: CustomPaint(
                  painter: CrossPainter(
                    color: Colors.red.shade900.withAlpha(200),
                    strokeWidth: 4.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
