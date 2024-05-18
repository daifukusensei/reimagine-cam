import 'package:flutter/material.dart';

import 'package:reimagine_cam/screens/about_screen.dart';
import 'package:reimagine_cam/screens/camera_screen.dart';
import 'package:reimagine_cam/screens/preview_screen.dart';
import 'package:reimagine_cam/screens/settings_screen.dart';

import 'package:reimagine_cam/services/settings_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsManager().init();
  runApp(const ReimagineCam());
}

class ReimagineCam extends StatelessWidget {
  //TODO: ResolutionPreset.max is not working
  //TODO: add GitHub link in About
  //TODO: delete temp files from app's local directory
  //TODO: use buttons rather than InkWells to simplify code
  //TODO: move both About and Settings button to popup menu
  const ReimagineCam({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reimagine Cam',
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark(),
      initialRoute: CameraScreen.id,
      routes: {
        AboutScreen.id: (context) => const AboutScreen(),
        CameraScreen.id: (context) => const CameraScreen(),
        PreviewScreen.id: (context) => const PreviewScreen(),
        SettingsScreen.id: (context) => const SettingsScreen()
      },
    );
  }
}
