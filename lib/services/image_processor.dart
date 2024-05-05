import 'dart:io';

import 'package:flutter_native_image/flutter_native_image.dart';

class ImageProcessor {
  static Future<File> resizeImage(String imagePath, int targetSize) async {
    // Read the original image file
    File imageFile = File(imagePath);

    // Get the original image's dimensions
    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(imagePath);
    int originalWidth = properties.width!;
    int originalHeight = properties.height!;

    // Calculate the aspect ratio of the original image
    double aspectRatio = originalWidth / originalHeight;

    // Calculate the target width and height based on the target size and aspect ratio
    int targetWidth = targetSize;
    int targetHeight = (targetSize / aspectRatio).round();

    // Resize the image using FlutterNativeImage
    File resizedImage = await FlutterNativeImage.compressImage(
      imageFile.path,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );

    return resizedImage;
  }
}
