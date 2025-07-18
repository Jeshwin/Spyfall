import 'package:flutter/services.dart';

class ImageService {
  /// Converts location name to snake_case for image filename
  static String _locationToSnakeCase(String locationName) {
    return locationName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(
          RegExp(r'^_+|_+$'),
          '',
        ); // Remove leading/trailing underscores
  }

  /// Gets the asset path for a location image with fallback for different extensions
  static Future<String?> getLocationImagePath(String locationName) async {
    final snakeCaseName = _locationToSnakeCase(locationName);
    final extensions = ['png', 'jpg', 'jpeg'];

    for (final extension in extensions) {
      final assetPath = 'assets/images/$snakeCaseName.$extension';
      
      try {
        // Try to load the asset to check if it exists
        await rootBundle.load(assetPath);
        return assetPath;
      } catch (e) {
        // Continue to next extension if this one fails
        continue;
      }
    }

    // Return null if no image found with any extension
    return null;
  }
}
