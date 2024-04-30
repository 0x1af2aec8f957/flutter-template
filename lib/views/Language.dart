import 'package:flutter/material.dart';

import '../lang/i18n.dart';
import '../setup/config.dart';
import '../utils/common.dart';

class Language extends StatelessWidget {
  final String title;
  Language({Key? super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [],
      ),
      body: Column(
        children: [
          for (final Locale locale in AppConfig.locales) ListTile(
            title: Text(locale.toString()),
            trailing: locale == I18n.local ? Icon(Icons.check) : null,
            onTap: () => I18n.setLanguage(locale),
          ),
        ],
      ),
    );
  }
}