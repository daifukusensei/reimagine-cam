import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';

import 'about_screen.dart';
import 'preview_screen.dart';
import 'settings_screen.dart';

import 'package:reimagine_cam/services/camera_service.dart';
import 'package:reimagine_cam/services/clipdrop_service.dart';
import 'package:reimagine_cam/services/dalle2_service.dart';
import 'package:reimagine_cam/services/image_processor.dart';
import 'package:reimagine_cam/services/settings_manager.dart';

import 'package:reimagine_cam/util/custom_alert_dialog.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  static const String id = 'camera_screen';

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late CameraService _cameraService;
  bool _isCameraInitialized = false;
  bool _isAboutButtonPressed = false;
  bool _isCaptureButtonPressed = false;
  bool _isSettingsButtonPressed = false;
  bool _processing = false;
  bool _isFlashVisible = false;
  String _processingStatus = '';
  late AnimationController _animationController;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();
    WidgetsBinding.instance.addObserver(this);
    initCamera();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> initCamera() async {
    await _cameraService.initializeCamera();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraService.disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  @override
  void dispose() {
    _cameraService.disposeCamera();
    _animationController.dispose();
    _audioPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _flashAndPlaySound() async {
    // Play shutter sound
    await _audioPlayer.play(AssetSource('sounds/shutter_sound.mp3'));

    // Flash screen
    setState(() {
      _isFlashVisible = true;
    });

    await _animationController.forward(from: 0);
    setState(() {
      _isFlashVisible = false;
    });
  }

  void _onTakePhotoPressed() async {
    // Display an error if there's no network connection
    List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.mobile) &&
        !connectivityResult.contains(ConnectivityResult.wifi) &&
        !connectivityResult.contains(ConnectivityResult.ethernet)) {
      const CustomAlertDialog().show(mounted ? context : null,
          'Please check your internet connection.', 'Network Error');
      return;
    }

    if ((SettingsManager().getString('engine') == 'clipdrop' &&
            SettingsManager().getString('clipdrop_api_key').isEmpty) ||
        (SettingsManager().getString('engine') == 'dalle2' &&
            SettingsManager().getString('dalle2_api_key').isEmpty)) {
      // Show a message to the user if no API key is specified
      const CustomAlertDialog().show(
          mounted ? context : null, 'Please enter an API key in Settings');
      return;
    }

    try {
      setState(() {
        _processing = true;
        _processingStatus = "Capturing...";
      });

      final image = await _cameraService.capturePhoto();

      if (image != null) {
        // Flash screen and play sound to indicate a photo was captured
        await _flashAndPlaySound();

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

        final reimaginedImage = SettingsManager().getString('engine') ==
                'clipdrop'
            ? await ClipdropService.upload(mounted ? context : null, image.path)
            : await Dalle2Service.upload(mounted ? context : null, image.path);

        debugPrint("REIMAGINED: $reimaginedImage");

        if (reimaginedImage != null) {
          // Save the reimagined image to the gallery
          String fileExtension =
              reimaginedImage.endsWith('.png') ? 'png' : 'jpg';
          String filename =
              'Reimagine_Cam_${formattedDateTime}_reimagined.$fileExtension';

          await ImageGallerySaver.saveFile(reimaginedImage, name: filename);

          // Perform a check before using the context to display the reimagined image
          if (mounted) {
            final navigator = Navigator.of(context);
            await navigator.pushNamed(PreviewScreen.id,
                arguments: reimaginedImage);
          }

          // Delete all cached image files not saved to Gallery
          await ImageProcessor.deleteAllTempFiles();
        }
      }
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (_isCameraInitialized) {
          final aspectRatio = orientation == Orientation.landscape
              ? _cameraService.controller!.value.aspectRatio
              : 1 / _cameraService.controller!.value.aspectRatio;

          return SafeArea(
            child: Scaffold(
              body: Stack(
                children: [
                  // CameraPreview
                  Center(
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: CameraPreview(_cameraService.controller!),
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
                  if (_isFlashVisible)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(0.8),
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
}
