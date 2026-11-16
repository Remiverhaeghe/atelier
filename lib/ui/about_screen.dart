import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../support/crash_log.dart';

/// À propos, et journal des plantages à partager si quelque chose ne va pas.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, this.crashLog});

  final CrashLog? crashLog;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vLog = crashLog?.read() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(vText.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(vText.aboutText),
          const SizedBox(height: 24),
          Text(vText.crashLogTitle, style: Theme.of(context).textTheme.titleMedium),
          Text(vText.crashLogHelp),
          const SizedBox(height: 8),
          if (vLog.isEmpty)
            Text(vText.crashLogEmpty)
          else
            FilledButton.icon(
              onPressed: () => SharePlus.instance.share(ShareParams(text: vLog)),
              icon: const Icon(Icons.share),
              label: Text(vText.crashLogShare),
            ),
        ],
      ),
    );
  }
}
