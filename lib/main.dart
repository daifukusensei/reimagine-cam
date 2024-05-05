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
  //TODO: move to OpenAI
  //TODO: add GitHub link in About
  //TODO: refactor to distinct classes
  //TODO: capture sound? flash screen instead of displaying status of capturing?
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
        SettingsScreen.id: (context) => const SettingsScreen(),
      },
    );
  }
}
