import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image/image.dart' as img;

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

  static Future<File> convertJpgToPng(String jpgImagePath) async {
    // Read the JPG image
    List<int> imageBytes = await File(jpgImagePath).readAsBytes();

    // Decode the JPG image
    img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes))!;

    // Encode the image as PNG
    List<int> pngBytes = img.encodePng(image);

    // Write the PNG image to a new file
    File pngImage = File(jpgImagePath.replaceAll(RegExp(r'\.jpg$'), '.png'));
    await pngImage.writeAsBytes(pngBytes);

    return pngImage;
  }

  static Future<File> convertPngToJpg(String pngImagePath) async {
    // Read the PNG image
    List<int> imageBytes = await File(pngImagePath).readAsBytes();

    // Decode the PNG image
    img.Image image = img.decodeImage(Uint8List.fromList(imageBytes))!;

    // Encode the image as JPG
    List<int> jpgBytes = img.encodeJpg(image);

    // Write the JPG image to a new file
    File jpgImage = File(pngImagePath.replaceAll(RegExp(r'\.png$'), '.jpg'));
    await jpgImage.writeAsBytes(jpgBytes);

    return jpgImage;
  }
}
