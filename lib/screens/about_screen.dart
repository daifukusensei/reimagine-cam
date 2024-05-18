import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  static const String id = 'about_screen';

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAboutDialog(context);
    });

    return Container();
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AboutDialog(
          applicationName: "Reimagine Cam",
          applicationIcon: SizedBox(
            width: 70,
            height: 70,
            child: Image.asset('assets/images/reimagine_cam.png'),
          ),
          applicationVersion: "Your camera, reimagined by AI",
          applicationLegalese: "04/2024, by daifuku",
        );
      },
    ).then((_) {
      // After the dialog is dismissed, pop the AboutScreen
      Navigator.pop(context);
    });
  }
}