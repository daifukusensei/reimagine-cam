import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageProcessor {
  static Future<File> resizeImage(String imagePath, int targetSize) async {
    return await compute(
        _resizeImageIsolate, _ResizeImageParams(imagePath, targetSize));
  }

  static Future<File> _resizeImageIsolate(_ResizeImageParams params) async {
    final image = File(params.imagePath);
    final rawImage = img.decodeImage(await image.readAsBytes());

    img.Image resizedImage;
    if (rawImage!.width > rawImage.height) {
      resizedImage = img.copyResize(rawImage, width: params.targetSize);
    } else {
      resizedImage = img.copyResize(rawImage, height: params.targetSize);
    }

    File resizedImageFile = File(params.imagePath);
    await resizedImageFile.writeAsBytes(img.encodeJpg(resizedImage));

    return resizedImageFile;
  }

  static Future<File> convertJpgToPng(String jpgImagePath) async {
    return await compute(_convertJpgToPngIsolate, jpgImagePath);
  }

  static Future<File> _convertJpgToPngIsolate(String jpgImagePath) async {
    // Read the JPG image
    List<int> imageBytes = await File(jpgImagePath).readAsBytes();

    // Decode the JPG image
    img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));

    // Encode the image as PNG
    List<int> pngBytes = img.encodePng(image!);

    // Write the PNG image to a new file
    File pngImage = File(jpgImagePath.replaceAll(RegExp(r'\.jpg$'), '.png'));
    await pngImage.writeAsBytes(pngBytes);

    return pngImage;
  }

  static Future<List<FileSystemEntity>> listAllTempFiles() async {
    try {
      // Get the app's cache directory
      final directory = await getApplicationCacheDirectory();

      // List all files in directory
      final files = directory.listSync();

      // Print file names to console
      for (var file in files) {
        debugPrint(file.path);
      }

      return files;
    } catch (e) {
      debugPrint("Error accessing cache directory: $e");
      return [];
    }
  }

  static Future<void> deleteAllTempFiles() async {
    try {
      // Get the app's cache directory
      final directory = await getApplicationCacheDirectory();

      // List all files in directory
      final files = directory.listSync();

      // Iterate and delete each file
      for (var file in files) {
        try {
          if (file is File) {
            await file.delete();
          } else if (file is Directory) {
            await file.delete(recursive: true);
          }
        } catch (e) {
          debugPrint("Error deleting file: $e");
        }
      }
      debugPrint("All cached files deleted successfully.");
    } catch (e) {
      debugPrint("Error accessing cache directory: $e");
    }
  }
}

class _ResizeImageParams {
  final String imagePath;
  final int targetSize;

  _ResizeImageParams(this.imagePath, this.targetSize);
}
