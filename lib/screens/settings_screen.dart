import 'package:flutter/material.dart';
import 'package:reimagine_cam/services/settings_manager.dart';

class SettingsScreen extends StatelessWidget {
  static const String id = 'settings_screen';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSettingsDialog(context);
    });

    return Container();
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller =
            TextEditingController(text: SettingsManager().getString('api_key'));
        return AlertDialog(
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Clipdrop API Key',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                SettingsManager().setString('api_key', controller.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      // After the dialog is dismissed, pop the AboutScreen
      Navigator.pop(context);
    });
  }
}
