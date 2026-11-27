import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/climate_dispatch.dart';
import '../state/worksites_controller.dart';
import 'theme.dart';

/// Un fichier de capteur choisi : son nom et son texte.
typedef SensorFile = ({String name, String text});

/// Choix d'un fichier de relevés ; null si l'utilisateur renonce.
typedef SensorFilePicker = Future<SensorFile?> Function();

Future<SensorFile?> pickSensorFile() async {
  final vFile = await FilePicker.pickFile();
  final rFile = vFile == null
      ? null
      : (name: vFile.name, text: utf8.decode(await vFile.readAsBytes(), allowMalformed: true));

  return rFile;
}

/// Relevés de tous les capteurs du chantier : chaque fichier va dans la pièce qui porte son nom,
/// et ce que le nom ne désigne pas se range à la main.
class ClimateSensorsScreen extends StatefulWidget {
  const ClimateSensorsScreen({
    super.key,
    required this.controller,
    required this.worksiteId,
    this.pickFile = pickSensorFile,
  });

  final WorksitesController controller;
  final String worksiteId;
  final SensorFilePicker pickFile;

  @override
  State<ClimateSensorsScreen> createState() => _ClimateSensorsScreenState();
}

class _ClimateSensorsScreenState extends State<ClimateSensorsScreen> {
  final List<RoutedSensor> _routed = [];
  final List<SensorReadings> _waiting = [];
  bool _unreadable = false;

  Future<void> _add() async {
    final vFile = await widget.pickFile();
    final vWorksite = widget.controller.worksite(widget.worksiteId);
    if (vFile == null || vWorksite == null) {
      return;
    }
    final vSensors = readSensorFile(vFile.name, vFile.text);
    setState(() => _unreadable = vSensors.isEmpty);
    if (vSensors.isNotEmpty) {
      await _route(vSensors, const {});
    }
  }

  Future<void> _route(List<SensorReadings> pSensors, Map<String, String> pAssigned) async {
    final vWorksite = widget.controller.worksite(widget.worksiteId);
    if (vWorksite == null) {
      return;
    }
    final vResult = routeClimate(vWorksite, pSensors, pAssigned: pAssigned);
    await widget.controller.updateWorksite(vResult.worksite);
    if (!mounted) {
      return;
    }
    setState(() {
      _routed.addAll(vResult.routed);
      _waiting
        ..removeWhere((pWaiting) => pSensors.any((pSensor) => pSensor.name == pWaiting.name))
        ..addAll(pSensors.where((pSensor) => vResult.unmatched.contains(pSensor.name)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vRooms = widget.controller.worksite(widget.worksiteId)?.rooms ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(vText.sensorsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(vText.sensorsHelp),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.upload_file),
            label: Text(vText.sensorsAdd),
          ),
          if (_unreadable) ...[
            const SizedBox(height: 12),
            Text(
              vText.sensorsUnreadable,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          for (final vRouted in _routed)
            IconLine(
              Icons.check_circle_outline,
              vText.sensorsRouted(vRouted.sensor, vRouted.room, vRouted.days),
            ),
          for (final vSensor in _waiting)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(vText.sensorsNoRoom(vSensor.name)),
              trailing: PopupMenuButton<String>(
                tooltip: vText.sensorsPickRoom,
                icon: const Icon(Icons.meeting_room_outlined),
                onSelected: (pRoomId) => _route([vSensor], {vSensor.name: pRoomId}),
                itemBuilder: (_) => [
                  for (final vRoom in vRooms)
                    PopupMenuItem(value: vRoom.id, child: Text(vRoom.name)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
