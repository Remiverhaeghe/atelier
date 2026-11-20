import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/units.dart';
import '../support/platform_limits.dart';
import 'laser_link.dart';
import 'theme.dart';

/// Ouvre la mesure au télémètre et renvoie la distance choisie, en millimètres.
///
/// Dans la version web, Safari ne donne pas accès au Bluetooth : un mot l'explique, et la
/// mesure se tape à la main.
Future<int?> measureWithLaser(BuildContext pContext, {LaserLink? pLink}) async {
  if (aOnWeb) {
    final vText = AppLocalizations.of(pContext);
    await showDialog<void>(
      context: pContext,
      builder: (pDialog) => AlertDialog(
        title: Text(vText.laserTitle),
        content: Text(vText.laserWebUnavailable),
        actions: [TextButton(onPressed: () => Navigator.pop(pDialog), child: Text(vText.close))],
      ),
    );
    return null;
  }

  return Navigator.push<int>(
    pContext,
    MaterialPageRoute(builder: (_) => LaserScreen(link: pLink ?? BleLaserLink())),
  );
}

/// Télémètre Bosch en Bluetooth : choisir l'appareil, mesurer avec son bouton, reprendre la
/// distance.
class LaserScreen extends StatefulWidget {
  const LaserScreen({super.key, required this.link});

  final LaserLink link;

  @override
  State<LaserScreen> createState() => _LaserScreenState();
}

class _LaserScreenState extends State<LaserScreen> {
  final _devices = <LaserDevice>[];
  StreamSubscription<LaserDevice>? _scan;
  StreamSubscription<int>? _measures;
  LaserDevice? _device;
  int? _last;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scan = widget.link.scan().listen(
      (pDevice) => setState(() => _devices.add(pDevice)),
      onError: (Object pError) => setState(() => _error = '$pError'),
    );
  }

  @override
  void dispose() {
    _scan?.cancel();
    _measures?.cancel();
    super.dispose();
  }

  void _connect(LaserDevice pDevice) {
    _scan?.cancel();
    _measures?.cancel();
    setState(() {
      _device = pDevice;
      _error = null;
    });
    _measures = widget.link
        .measures(pDevice.id)
        .listen(
          (pMm) => setState(() => _last = pMm),
          onError: (Object pError) => setState(() => _error = '$pError'),
        );
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vLast = _last;

    return Scaffold(
      appBar: AppBar(title: Text(vText.laserTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (_device == null) ...[
            IconLine(Icons.bluetooth_searching, vText.laserSearch),
            if (_devices.isEmpty) const LinearProgressIndicator(),
            for (final vDevice in _devices)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.straighten),
                  title: Text(vDevice.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _connect(vDevice),
                ),
              ),
          ] else ...[
            IconLine(Icons.bluetooth_connected, vText.laserConnected(_device!.name)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                vLast == null ? vText.laserPress : vText.laserValue(formatCentimetres(vLast)),
                style: vTheme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: vLast == null ? null : () => Navigator.pop(context, vLast),
              icon: const Icon(Icons.check),
              label: Text(vText.laserUse),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(vText.laserError, style: TextStyle(color: vTheme.colorScheme.error)),
            ),
          const SizedBox(height: 16),
          Text(vText.laserHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
