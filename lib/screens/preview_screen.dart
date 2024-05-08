import 'dart:io';

import 'package:flutter/material.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});
  static const String id = 'preview_screen';

  @override
  State<PreviewScreen> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewScreen> {
  late String imagePath;

  @override
  Widget build(BuildContext context) {
    // Retrieve the passed argument in the build method
    final args = ModalRoute.of(context)!.settings.arguments;
    imagePath = args as String; // Cast the argument to the expected type

    return Scaffold(
      body: Center(
          child: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
      )),
    );
  }
}
