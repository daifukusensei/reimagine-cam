import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  late List<CameraDescription> _cameras;
  CameraController? _controller;

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    // Initialize the camera with the first camera in the list
    await selectCamera(_cameras.first);
  }

  Future<void> selectCamera(CameraDescription cameraDescription) async {
    final previousCameraController = _controller;

    // Instantiate the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Initialize controller
    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      debugPrint('Error initializing camera: $e');
    }
    // Dispose the previous controller
    await previousCameraController?.dispose();

    _controller = cameraController;
  }

  Future<XFile?> capturePhoto() async {
    if (_controller!.value.isTakingPicture) {
      return null;
    }
    try {
      await _controller?.setFlashMode(FlashMode.auto);
      final XFile picture = await _controller!.takePicture();
      await _controller?.setFlashMode(FlashMode.off);
      return picture;
    } on CameraException catch (e) {
      debugPrint('Error occurred while taking picture: $e');
      return null;
    }
  }

  void disposeCamera() {
    _controller?.dispose();
  }

  CameraController? get controller => _controller;
}
