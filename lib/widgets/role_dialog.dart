import 'package:flutter/material.dart';

class RoleDialog extends StatelessWidget {
  final bool isSpy;
  final String? role;
  final String? location;
  final String _imagePath = 'assets/images/spy.jpg';

  const RoleDialog({
    super.key,
    required this.isSpy,
    this.role = 'Spy',
    this.location = '???',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: AspectRatio(
        aspectRatio: 8 / 10,
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: isSpy ? Colors.red[50] : Color(0xFFFFFFFF),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 16,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
            child: Column(
              children: [
                // Background image
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(
                    _imagePath,
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
                // Content
                const SizedBox(height: 10),
                Text(
                  "Location: ${isSpy ? '???' : location ?? ''}",
                  style: TextStyle(
                    fontFamily: "Delicious Handrawn",
                    fontSize: 24,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                Text(
                  "Role: ${isSpy ? 'Spy' : role ?? ''}",
                  style: TextStyle(
                    fontFamily: "Delicious Handrawn",
                    fontSize: 24,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
