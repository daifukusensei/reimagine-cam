import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'image_processor.dart';
import 'settings_manager.dart';

import 'package:reimagine_cam/util/custom_alert_dialog.dart';

class ClipdropService {
  static Future<String?> uploadToClipDrop(
      BuildContext? context, String imagePath) async {
    // URL of Clipdrop's Reimagine API
    String apiUrl = 'https://clipdrop-api.co/reimagine/v1/reimagine';

    try {
      // Resize the image to fit within a 1024x1024 bounding box while preserving aspect ratio
      final File downsizedImage =
          await ImageProcessor.resizeImage(imagePath, 1024);

      // Create a multipart request
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add the API key header
      request.headers['x-api-key'] = SettingsManager().getString('api_key');

      // Add the downsized image file
      request.files.add(
          await http.MultipartFile.fromPath('image_file', downsizedImage.path));

      // Send the request
      var response = await request.send();

      // debugPrint("REIMAGINED RESPONSE: " + response.statusCode.toString());
      // return downsizedImage.path;

      // Process reimagined image if the response is successful
      if (response.statusCode == 200) {
        // Read response bytes
        List<int> bytes =
            await response.stream.expand((chunk) => chunk).toList();

        // Get the temporary directory
        final Directory tempDir = await getTemporaryDirectory();

        // Generate a unique filename using the current timestamp
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        var outputFile = File('${tempDir.path}/output_$timestamp.jpg');

        // Save the response as a file in the temporary directory
        await outputFile.writeAsBytes(bytes);

        // Return the path of the saved image
        return outputFile.path;
      } else {
        // Handle different status codes
        if (response.statusCode == 400) {
          const CustomAlertDialog().show(
              context, 'Request is malformed or incomplete', 'Clipdrop Error');
        } else if (response.statusCode == 401) {
          const CustomAlertDialog()
              .show(context, 'Missing API key', 'Clipdrop Error');
        } else if (response.statusCode == 402) {
          const CustomAlertDialog().show(context,
              'Your account has no remaining credits', 'Clipdrop Error');
        } else if (response.statusCode == 403) {
          const CustomAlertDialog()
              .show(context, 'Invalid or revoked API key', 'Clipdrop Error');
        } else if (response.statusCode == 429) {
          const CustomAlertDialog().show(
              context,
              'Too many requests, blocked by the rate limiter',
              'Clipdrop Error');
        } else if (response.statusCode == 500) {
          const CustomAlertDialog().show(context,
              'Server error, please try again later', 'Clipdrop Error');
        } else {
          const CustomAlertDialog()
              .show(context, 'An unexpected error occurred', 'Clipdrop Error');
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }

    return null; // Return null if there was an error
  }
}
