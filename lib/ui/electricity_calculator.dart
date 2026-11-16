import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/electricity.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String elecRoomLabel(AppLocalizations pText, ElecRoomKind pKind) => switch (pKind) {
  ElecRoomKind.living => pText.elecLiving,
  ElecRoomKind.bedroom => pText.elecBedroom,
  ElecRoomKind.kitchen => pText.elecKitchen,
  ElecRoomKind.bathroom => pText.elecBathroom,
  ElecRoomKind.hallway => pText.elecHallway,
  ElecRoomKind.toilet => pText.elecToilet,
};

IconData elecRoomIcon(ElecRoomKind pKind) => switch (pKind) {
  ElecRoomKind.living => Icons.weekend_outlined,
  ElecRoomKind.bedroom => Icons.bed_outlined,
  ElecRoomKind.kitchen => Icons.kitchen_outlined,
  ElecRoomKind.bathroom => Icons.bathtub_outlined,
  ElecRoomKind.hallway => Icons.door_front_door_outlined,
  ElecRoomKind.toilet => Icons.wc_outlined,
};

/// Électricité : pièces ajoutées une à une, repères de quantités et mise en garde.
class ElectricityCalculator extends StatefulWidget {
  const ElectricityCalculator({super.key});

  @override
  State<ElectricityCalculator> createState() => _ElectricityCalculatorState();
}

class _ElectricityCalculatorState extends State<ElectricityCalculator> {
  final _rooms = <ElecRoom>[];
  var _run = 10;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNeeds = elecNeeds(_rooms, pRunMetres: _run);

    return Scaffold(
      appBar: AppBar(title: Text(vText.elecTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            margin: EdgeInsets.zero,
            color: vTheme.colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.bolt, color: vTheme.colorScheme.onErrorContainer),
              title: Text(vText.tipWarning),
              subtitle: Text(vText.elecWarning),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigFigure(vText.elecSockets(vNeeds.sockets)),
                  IconLine(Icons.lightbulb_outline, vText.elecLights(vNeeds.lights, vNeeds.switches)),
                  IconLine(Icons.check_box_outline_blank, vText.elecBoxes(vNeeds.boxes)),
                  if (vNeeds.dedicated > 0) IconLine(Icons.electrical_services, vText.elecDedicated(vNeeds.dedicated)),
                  IconLine(Icons.cable, vText.elecConduit(vNeeds.conduitMetres, vNeeds.wireMetres)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(vText.elecRoomsTitle, style: vTheme.textTheme.titleMedium),
          for (var vIndex = 0; vIndex < _rooms.length; vIndex++)
            Card(
              child: ListTile(
                leading: Icon(elecRoomIcon(_rooms[vIndex].kind), color: vTheme.colorScheme.primary),
                title: Text(elecRoomLabel(vText, _rooms[vIndex].kind)),
                subtitle: Text(vText.elecRoomLine(minSockets(_rooms[vIndex]), formatDecimal(_rooms[vIndex].areaM2))),
                trailing: IconButton(
                  tooltip: vText.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _rooms.removeAt(vIndex)),
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            children: [
              for (final vKind in ElecRoomKind.values)
                ActionChip(
                  avatar: Icon(elecRoomIcon(vKind), size: 18),
                  label: Text(elecRoomLabel(vText, vKind)),
                  onPressed: () => setState(() => _rooms.add(ElecRoom(kind: vKind))),
                ),
            ],
          ),
          if (_rooms.any((pRoom) => pRoom.kind == ElecRoomKind.living))
            NumberField<double>(
              label: vText.elecLivingArea,
              initial: '12',
              parse: parseDecimal,
              onValue: (pValue) => setState(() {
                for (var vIndex = 0; vIndex < _rooms.length; vIndex++) {
                  if (_rooms[vIndex].kind == ElecRoomKind.living) {
                    _rooms[vIndex] = ElecRoom(kind: ElecRoomKind.living, areaM2: pValue);
                  }
                }
              }),
            ),
          NumberField(
            label: vText.elecRun,
            initial: '$_run',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _run = pValue),
          ),
        ],
      ),
    );
  }
}
