import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

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

  static Future<File> convertPngToJpg(String pngImagePath) async {
    return await compute(_convertPngToJpgIsolate, pngImagePath);
  }

  static Future<File> _convertPngToJpgIsolate(String pngImagePath) async {
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

class _ResizeImageParams {
  final String imagePath;
  final int targetSize;

  _ResizeImageParams(this.imagePath, this.targetSize);
}
