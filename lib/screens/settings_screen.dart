import 'package:flutter/material.dart';
import 'package:reimagine_cam/services/settings_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const String id = 'settings_screen';

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _showSettingsDialog(context);
    });

    return Container();
  }

  void _showSettingsDialog(BuildContext context) {
    final TextEditingController controller =
        TextEditingController(text: SettingsManager().getString('api_key'));

    showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                ListTile(
                  title: const Text(
                    'Clipdrop API Key',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  subtitle: TextField(
                    controller: controller,
                    obscureText: true,
                    onChanged: (value) {
                      // Save settings when text changes
                      SettingsManager().setString('api_key', value);
                    },
                    style: const TextStyle(fontSize: 14.0),
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text(
                    'Contact us',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  subtitle: const Text(
                    'example@example.com',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onTap: () {
                    // Handle contact action
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text(
                    'Credits',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  subtitle: const Text(
                    'example.com',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onTap: () {
                    // Handle credits action
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // After the dialog is dismissed, pop the SettingsScreen
      Navigator.pop(context);
    });
  }
}
