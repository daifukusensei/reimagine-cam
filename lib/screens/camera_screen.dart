import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reimagine_cam/services/clipdrop_service.dart';
import 'package:reimagine_cam/services/settings_manager.dart';

import 'about_screen.dart';
import 'preview_screen.dart';
import 'settings_screen.dart';

import 'package:camera/camera.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  static const String id = 'camera_screen';

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isAboutButtonPressed = false;
  bool _isCaptureButtonPressed = false;
  bool _isSettingsButtonPressed = false;
  late final List<CameraDescription> _cameras;
  bool _processing = false;
  String _processingStatus = '';

  @override
  void initState() {
    super.initState();
    // initPreferences();
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  Future<void> initCamera() async {
    _cameras = await availableCameras();
    // Initialize the camera with the first camera in the list
    await onNewCameraSelected(_cameras.first);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<XFile?> capturePhoto() async {
    final CameraController? cameraController = _controller;
    if (cameraController!.value.isTakingPicture) {
      return null;
    }
    try {
      await _controller?.setFlashMode(FlashMode.auto);
      final XFile picture = await cameraController.takePicture();
      await _controller?.setFlashMode(FlashMode
          .off); // There appears to be a bug in which flash remains lit after taking a picutre requiring it
      return picture;
    } on CameraException catch (e) {
      debugPrint('Error occurred while taking picture: $e');
      return null;
    }
  }

  void _onTakePhotoPressed() async {
    // Display an error if there's no network connection
    List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.mobile) &&
        !connectivityResult.contains(ConnectivityResult.wifi) &&
        !connectivityResult.contains(ConnectivityResult.ethernet)) {
      _showAlert('Please check your internet connection.', 'Network Error');
      return;
    }

    if (SettingsManager().getString('api_key').isEmpty) {
      // Show a message to the user if API key is not entered
      _showAlert('Please enter a Clipdrop API key in Settings');
      return;
    }

    try {
      setState(() {
        _processing = true;
        _processingStatus = "Capturing...";
      });

      final image = await capturePhoto();
      if (image != null) {
        String formattedDateTime =
            DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        String filename = 'Reimagine_Cam_${formattedDateTime}_original.jpg';

        // Save the original image to the gallery
        await ImageGallerySaver.saveFile(image.path, name: filename);

        debugPrint("REIMAGINED KEY: ${SettingsManager().getString('api_key')}");

        // Upload and process the image with Clipdrop's API
        setState(() {
          _processingStatus = 'Reimagining...';
        });
        final reimaginedImage = await ClipdropService.uploadToClipDrop(
            mounted ? context : null, image.path);

        debugPrint("REIMAGINED: $reimaginedImage");

        if (reimaginedImage != null) {
          // Save the reimagined image to the gallery
          await ImageGallerySaver.saveFile(reimaginedImage,
              name: 'Reimagine_Cam_${formattedDateTime}_reimagined.jpg');

          // Perform a check before using the context to display the reimagined image
          if (mounted) {
            final navigator = Navigator.of(context);
            await navigator.pushNamed(PreviewScreen.id,
                arguments: reimaginedImage);
          }
        }
      }
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  void _showAlert(String message, [String? title]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title != null ? Text(title) : null,
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (_isCameraInitialized) {
          final aspectRatio = orientation == Orientation.landscape
              ? _controller!.value.aspectRatio
              : 1 / _controller!.value.aspectRatio;

          return SafeArea(
            child: Scaffold(
              body: Stack(
                children: [
                  // CameraPreview
                  Center(
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                  // Positioned widget for buttons
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // About dialog button
                        InkWell(
                          onTap: _processing
                              ? null
                              : () =>
                                  Navigator.pushNamed(context, AboutScreen.id),
                          onTapCancel: () {
                            setState(() {
                              _isAboutButtonPressed = false;
                            });
                          },
                          onTapDown: (_) {
                            setState(() {
                              _isAboutButtonPressed = !_processing;
                            });
                          },
                          onTapUp: (_) {
                            setState(() {
                              _isAboutButtonPressed = false;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isAboutButtonPressed
                                  ? Colors.grey
                                  : Colors.white,
                            ),
                            child: Icon(
                              Icons.question_mark_outlined,
                              color: _isAboutButtonPressed
                                  ? Colors.white
                                  : Colors.black,
                              size: 25,
                            ),
                          ),
                        ),
                        // Capture photo button
                        InkWell(
                          onTap: _processing ? null : _onTakePhotoPressed,
                          onTapCancel: () {
                            setState(() {
                              _isCaptureButtonPressed = false;
                            });
                          },
                          onTapDown: (_) {
                            setState(() {
                              _isCaptureButtonPressed = !_processing;
                            });
                          },
                          onTapUp: (_) {
                            setState(() {
                              _isCaptureButtonPressed = false;
                            });
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCaptureButtonPressed
                                  ? Colors.grey
                                  : Colors.white,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: _isCaptureButtonPressed
                                  ? Colors.white
                                  : Colors.black,
                              size: 40,
                            ),
                          ),
                        ),
                        // Preferences dialog button
                        InkWell(
                          onTap: _processing
                              ? null
                              : () => Navigator.pushNamed(
                                  context, SettingsScreen.id),
                          onTapCancel: () {
                            setState(() {
                              _isSettingsButtonPressed = false;
                            });
                          },
                          onTapDown: (_) {
                            setState(() {
                              _isSettingsButtonPressed = !_processing;
                            });
                          },
                          onTapUp: (_) {
                            setState(() {
                              _isSettingsButtonPressed = false;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isSettingsButtonPressed
                                  ? Colors.grey
                                  : Colors.white,
                            ),
                            child: Icon(
                              Icons.settings,
                              color: _isSettingsButtonPressed
                                  ? Colors.white
                                  : Colors.black,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_processing)
                    // Overlay to "dim" the screen during processing
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                _processingStatus,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Future<void> onNewCameraSelected(CameraDescription description) async {
    final previousCameraController = _controller;

    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      description,
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

    // Replace with the new controller
    if (mounted) {
      setState(() {
        _controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Update the Boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = _controller!.value.isInitialized;
      });
    }
  }
}
