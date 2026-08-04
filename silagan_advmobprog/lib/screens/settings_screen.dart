import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silagan_advmobprog/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          // add switch tiles to toggle dark and light mode
          SwitchListTile(
            value: themeProvider.isDarkMode,
            onChanged: (_) => themeProvider.toggleTheme(),
            title: const Text('Dark mode'),
            subtitle: const Text('Switch between light and dark themes.'),
          ),
          const SizedBox(height: 16),
          const Text(
            'This page is intentionally minimal while the rest of the app is being refactored.',
          ),
        ],
      ),
    );
  }
}
