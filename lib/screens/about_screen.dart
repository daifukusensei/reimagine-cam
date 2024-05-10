import 'package:about/about.dart';
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
    showAboutPage(
      context: context,
      values: {
        'version': '1.0',
        'year': DateTime.now().year.toString(),
      },
      applicationLegalese: '{{ year }}, by daifuku',
      applicationDescription: const Text(
        'Photos from your camera, reimagined by AI',
        textAlign: TextAlign.center,
      ),
      children: const <Widget>[
        MarkdownPageListTile(
          filename: 'CONTRIBUTING.md',
          title: Text('Contributing'),
          icon: Icon(Icons.share),
        ),
        LicensesPageListTile(
          icon: Icon(Icons.favorite),
        ),
      ],
      applicationIcon: const SizedBox(
        width: 100,
        height: 100,
        child: Image(
          image: AssetImage('assets/images/reimagine_cam.png'),
        ),
      ),
    ).then((_) {
      // After the dialog is dismissed, pop the AboutScreen
      Navigator.pop(context);
    });
  }
}

  // void _showAboutDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AboutDialog(
  //         applicationName: "Reimagine Cam",
  //         applicationIcon: SizedBox(
  //           width: 70,
  //           height: 70,
  //           child: Image.asset('assets/images/reimagine_cam.png'),
  //         ),
  //         applicationVersion: "1.0",
  //         applicationLegalese: "04/2024, by daifuku",
  //       );
  //     },
  //   ).then((_) {
  //     // After the dialog is dismissed, pop the AboutScreen
  //     Navigator.pop(context);
  //   });
  // }