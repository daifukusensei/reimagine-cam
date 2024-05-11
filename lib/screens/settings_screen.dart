import 'package:flutter/material.dart';
import 'package:reimagine_cam/services/settings_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  static const String id = 'settings_screen';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController dalle2Controller;
  late TextEditingController clipdropController;
  late String selectedOption;

  @override
  void initState() {
    super.initState();
    selectedOption = SettingsManager().getString('engine');
    dalle2Controller = TextEditingController(
      text: SettingsManager().getString('dalle2_api_key'),
    );
    clipdropController = TextEditingController(
      text: SettingsManager().getString('clipdrop_api_key'),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                'Reimagine using DALL·E 2',
              ),
              subtitle: TextFormField(
                controller: dalle2Controller,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Please enter API key',
                ),
                enabled: selectedOption == 'dalle2',
                onChanged: (value) {
                  if (selectedOption == 'dalle2') {
                    // Save settings when text changes
                    SettingsManager().setString('engine', 'dalle2');
                    SettingsManager().setString('dalle2_api_key', value);
                  }
                },
              ),
              leading: Radio<String>(
                value: 'dalle2',
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() {
                    selectedOption = value!;
                    dalle2Controller.text =
                        SettingsManager().getString('dalle2_api_key');
                    clipdropController.text =
                        SettingsManager().getString('clipdrop_api_key');
                    SettingsManager().setString('engine', selectedOption);
                  });
                },
              ),
            ),
            ListTile(
              title: const Text(
                'Reimagine using Clipdrop',
              ),
              subtitle: TextFormField(
                controller: clipdropController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Please enter API key',
                ),
                enabled: selectedOption == 'clipdrop',
                onChanged: (value) {
                  if (selectedOption == 'clipdrop') {
                    // Save settings when text changes
                    SettingsManager().setString('engine', 'clipdrop');
                    SettingsManager().setString('clipdrop_api_key', value);
                  }
                },
              ),
              leading: Radio<String>(
                value: 'clipdrop',
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() {
                    selectedOption = value!;
                    dalle2Controller.text =
                        SettingsManager().getString('dalle2_api_key');
                    clipdropController.text =
                        SettingsManager().getString('clipdrop_api_key');
                    SettingsManager().setString('engine', selectedOption);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    dalle2Controller.dispose();
    clipdropController.dispose();
    super.dispose();
  }
}
