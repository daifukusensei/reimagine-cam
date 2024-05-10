import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'image_processor.dart';
import 'settings_manager.dart';

import 'package:reimagine_cam/util/custom_alert_dialog.dart';

class Dalle2Service {
  static Future<String?> upload(BuildContext? context, String imagePath) async {
    // URL of DALL·E 2's Variation API
    String apiUrl = 'https://api.openai.com/v1/images/variations';

    try {
      // Resize the image to fit within a 1024x1024 bounding box while preserving aspect ratio
      final File downsizedImage =
          await ImageProcessor.resizeImage(imagePath, 1024);

      // Convert to PNG, required by DALL·E 2
      final File pngImage =
          await ImageProcessor.convertJpgToPng(downsizedImage.path);

      // Create a multipart request
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add the API key header
      request.headers['Authorization'] =
          'Bearer ${SettingsManager().getString('dalle2_api_key')}';

      // Add the downsized image file
      request.files
          .add(await http.MultipartFile.fromPath('image', pngImage.path));

      // Send the request
      var response = await request.send();

      // debugPrint("REIMAGINED RESPONSE: ${response.statusCode}");
      // return pngImage.path;

      // Process reimagined image if the response is successful
      if (response.statusCode == 200) {
        // Parse the response body
        var responseBody = await response.stream.bytesToString();
        var responseData = jsonDecode(responseBody);

        // Extract the URL of the image from the response data
        String imageUrl = responseData['data'][0]['url'];

        // Download the image from the URL
        var imageResponse = await http.get(Uri.parse(imageUrl));

        // Check if the request to download the image was successful
        if (imageResponse.statusCode == 200) {
          // Get the temporary directory
          final Directory tempDir = await getTemporaryDirectory();

          // Generate a unique filename using the current timestamp
          String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          var outputFile = File('${tempDir.path}/output_$timestamp.png');

          // Save the downloaded image as a file in the temporary directory
          await outputFile.writeAsBytes(imageResponse.bodyBytes);

          // Convert output to JPG
          final File jpgFile =
              await ImageProcessor.convertPngToJpg(outputFile.path);

          // Return the path of the saved image
          return jpgFile.path;
        } else {
          const CustomAlertDialog()
              .show(context, 'An unexpected error occurred', 'DALL·E 2 Error');
          return null;
        }
      } else {
        // Handle different status codes
        if (response.statusCode == 401) {
          const CustomAlertDialog().show(
              context,
              'Invalid authentication, incorrect API key provided, or you must be a member of an organization to use the API',
              'DALL·E 2 Error');
        } else if (response.statusCode == 403) {
          const CustomAlertDialog().show(context,
              'Country, region, or territory not supported', 'DALL·E 2 Error');
        } else if (response.statusCode == 429) {
          const CustomAlertDialog().show(
              context,
              'You exceeded your current quota, or the rate limit was reached for requests',
              'DALL·E 2 Error');
        } else if (response.statusCode == 500) {
          const CustomAlertDialog().show(
              context,
              'The server had an error while processing your request',
              'DALL·E 2 Error');
        } else if (response.statusCode == 503) {
          const CustomAlertDialog().show(
              context,
              'The engine is currently overloaded, please try again later',
              'DALL·E 2 Error');
        } else {
          const CustomAlertDialog()
              .show(context, 'An unexpected error occurred', 'DALL·E 2 Error');
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }

    return null; // Return null if there was an error
  }
}
