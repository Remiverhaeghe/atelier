import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/fixings.dart';
import '../logic/hidden_networks.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'fixings_calculator.dart';
import 'theme.dart';

/// Couleurs habituelles des réseaux : jaune électricité, bleu eau, rouge gaz.
Color networkColor(NetworkKind pKind) => switch (pKind) {
  NetworkKind.electric => const Color(0xFFE0A21B),
  NetworkKind.water => const Color(0xFF2B7BB9),
  NetworkKind.drain => const Color(0xFF7A6A58),
  NetworkKind.gas => const Color(0xFFC8402F),
  NetworkKind.heating => const Color(0xFFE07B39),
  NetworkKind.data => const Color(0xFF6B5BA8),
};

String networkLabel(AppLocalizations pText, NetworkKind pKind) => switch (pKind) {
  NetworkKind.electric => pText.netElectric,
  NetworkKind.water => pText.netWater,
  NetworkKind.drain => pText.netDrain,
  NetworkKind.gas => pText.netGas,
  NetworkKind.heating => pText.netHeating,
  NetworkKind.data => pText.netData,
};

/// Réseaux relevés dans les murs de la pièce, et contrôle « puis-je percer ici ? ».
class NetworksSection extends StatelessWidget {
  const NetworksSection({super.key, required this.room, required this.onChanged});

  final Room room;
  final ValueChanged<Room> onChanged;

  Future<void> _add(BuildContext pContext) async {
    final vRun = await showDialog<HiddenRun>(
      context: pContext,
      builder: (_) => _RunDialog(room: room),
    );
    if (vRun != null) {
      onChanged(room.copyWith(networks: [...room.networks, vRun]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    String vCm(int pMm) => formatCentimetres(pMm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(title: Text(vText.netTitle, style: vTheme.textTheme.titleMedium)),
        if (room.networks.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(vText.netEmpty)),
        for (final vRun in room.networks)
          ListTile(
            leading: Icon(Icons.cable, color: networkColor(vRun.kind)),
            title: Text(
              '${networkLabel(vText, vRun.kind)}, ${vText.wallTitle(vRun.wallIndex + 1)}',
            ),
            subtitle: Text(
              vText.netRun(
                vCm(vRun.fromAlongMm),
                vCm(vRun.fromHeightMm),
                vCm(vRun.toAlongMm),
                vCm(vRun.toHeightMm),
              ),
            ),
            trailing: IconButton(
              tooltip: vText.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onChanged(
                room.copyWith(
                  networks: [
                    for (final vOther in room.networks)
                      if (vOther.id != vRun.id) vOther,
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: room.walls.isEmpty ? null : () => _add(context),
                icon: const Icon(Icons.cable),
                label: Text(vText.netAdd),
              ),
              FilledButton.tonalIcon(
                onPressed: room.walls.isEmpty
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (_) => _DrillDialog(room: room),
                      ),
                icon: const Icon(Icons.hardware_outlined),
                label: Text(vText.netDrill),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mur et quatre cotes : début et fin du tracé, le long du mur et en hauteur.
class _RunDialog extends StatefulWidget {
  const _RunDialog({required this.room});

  final Room room;

  @override
  State<_RunDialog> createState() => _RunDialogState();
}

class _RunDialogState extends State<_RunDialog> {
  NetworkKind _kind = NetworkKind.electric;
  int _wall = 0;
  final _fields = List.generate(4, (_) => TextEditingController());
  String? _error;

  @override
  void dispose() {
    for (final vField in _fields) {
      vField.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final vValues = [for (final vField in _fields) parseCentimetres(vField.text)];
    if (vValues.any((pValue) => pValue == null)) {
      setState(() => _error = AppLocalizations.of(context).invalidLength);
      return;
    }
    Navigator.pop(
      context,
      HiddenRun(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        kind: _kind,
        wallIndex: _wall,
        fromAlongMm: vValues[0]!,
        fromHeightMm: vValues[1]!,
        toAlongMm: vValues[2]!,
        toHeightMm: vValues[3]!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vLabels = [vText.netFromAlong, vText.netFromHeight, vText.netToAlong, vText.netToHeight];

    return AlertDialog(
      title: Text(vText.netAdd),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<NetworkKind>(
              initialValue: _kind,
              items: [
                for (final vKind in NetworkKind.values)
                  DropdownMenuItem(value: vKind, child: Text(networkLabel(vText, vKind))),
              ],
              onChanged: (pKind) => setState(() => _kind = pKind!),
            ),
            _WallPicker(
              room: widget.room,
              value: _wall,
              onChanged: (pWall) => setState(() => _wall = pWall),
            ),
            for (var vIndex = 0; vIndex < 4; vIndex++)
              TextField(
                controller: _fields[vIndex],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: vLabels[vIndex],
                  suffixText: vText.unitCm,
                  errorText: vIndex == 0 ? _error : null,
                ),
              ),
            const SizedBox(height: 8),
            Text(vText.netHowTo, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(onPressed: _submit, child: Text(vText.save)),
      ],
    );
  }
}

class _WallPicker extends StatelessWidget {
  const _WallPicker({required this.room, required this.value, required this.onChanged});

  final Room room;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return DropdownButtonFormField<int>(
      initialValue: value,
      items: [
        for (var vIndex = 0; vIndex < room.walls.length; vIndex++)
          DropdownMenuItem(value: vIndex, child: Text(vText.wallTitle(vIndex + 1))),
      ],
      onChanged: (pWall) => onChanged(pWall!),
    );
  }
}

/// « Puis-je percer ici ? » : réseau le plus proche et bandes où passent souvent les conduits.
class _DrillDialog extends StatefulWidget {
  const _DrillDialog({required this.room});

  final Room room;

  @override
  State<_DrillDialog> createState() => _DrillDialogState();
}

class _DrillDialogState extends State<_DrillDialog> {
  int _wall = 0;
  int? _along;
  int? _height;
  WallSupport _support = WallSupport.drywall;
  double _weight = 0;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vAlong = _along;
    final vHeight = _height;
    final vCheck = vAlong == null || vHeight == null
        ? null
        : checkDrill(widget.room, _wall, vAlong, vHeight);

    return AlertDialog(
      title: Text(vText.netDrill),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WallPicker(
              room: widget.room,
              value: _wall,
              onChanged: (pWall) => setState(() => _wall = pWall),
            ),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: vText.netDrillAlong, suffixText: vText.unitCm),
              onChanged: (pText) => setState(() => _along = parseCentimetres(pText)),
            ),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: vText.netDrillHeight,
                suffixText: vText.unitCm,
              ),
              onChanged: (pText) => setState(() => _height = parseCentimetres(pText)),
            ),
            const SizedBox(height: 12),
            if (vCheck != null) ...[
              if (vCheck.tooClose)
                IconLine(
                  Icons.dangerous_outlined,
                  vText.netDrillNo(
                    networkLabel(vText, vCheck.nearest!.kind),
                    formatCentimetres(vCheck.distanceMm!),
                  ),
                )
              else
                IconLine(
                  Icons.check_circle_outline,
                  vCheck.nearest == null
                      ? vText.netDrillNoneKnown
                      : vText.netDrillOk(formatCentimetres(vCheck.distanceMm!)),
                ),
              if (vCheck.technicalZone) IconLine(AtelierIcons.warning, vText.netDrillZone),
              IconLine(Icons.sensors, vText.netDrillDetector),
            ],
            // Une fois l'endroit sûr, la cheville qui tient dans ce mur
            const Divider(),
            DropdownButtonFormField<WallSupport>(
              initialValue: _support,
              decoration: InputDecoration(labelText: vText.fixingsSupport),
              items: [
                for (final vSupport in WallSupport.values)
                  DropdownMenuItem(value: vSupport, child: Text(supportLabel(vText, vSupport))),
              ],
              onChanged: (pSupport) => setState(() => _support = pSupport!),
            ),
            TextField(
              key: const ValueKey('drill-weight'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: vText.drillWeight),
              onChanged: (pText) => setState(() => _weight = parseDecimal(pText) ?? 0),
            ),
            if (_weight > 0) ...[
              const SizedBox(height: 8),
              _FixingLines(support: _support, weightKg: _weight),
            ],
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.close))],
    );
  }
}

/// Cheville, perçage et vis pour un objet de [weightKg] sur ce support.
class _FixingLines extends StatelessWidget {
  const _FixingLines({required this.support, required this.weightKg});

  final WallSupport support;
  final double weightKg;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vPoints = fixingPoints(weightKg, FixingLoad.medium);
    final vAdvice = adviseFixing(support, loadFor(weightKg, vPoints));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconLine(Icons.hardware_outlined, plugLabel(vText, vAdvice.plug)),
        IconLine(Icons.circle_outlined, vText.fixingsDrill(vAdvice.drillMm)),
        IconLine(
          Icons.settings_outlined,
          vText.fixingsScrew(vAdvice.screwDiameterMm, vAdvice.screwLengthMm),
        ),
        IconLine(Icons.push_pin_outlined, vText.fixingsPoints(vPoints)),
      ],
    );
  }
}
