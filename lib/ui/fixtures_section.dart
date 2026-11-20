import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/fixtures.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'room_plan.dart';
import 'theme.dart';

/// Icône de chaque élément du plan.
IconData fixtureIcon(FixtureKind pKind) => switch (pKind) {
  FixtureKind.socket => Icons.power_outlined,
  FixtureKind.lightSwitch => Icons.toggle_on_outlined,
  FixtureKind.stairs => Icons.stairs_outlined,
  FixtureKind.mezzanine => Icons.layers_outlined,
  FixtureKind.roofWindow => Icons.roofing_outlined,
  FixtureKind.stairwell => Icons.crop_square,
};

String fixtureLabel(AppLocalizations pText, FixtureKind pKind) => switch (pKind) {
  FixtureKind.socket => pText.fixtureSocket,
  FixtureKind.lightSwitch => pText.fixtureSwitch,
  FixtureKind.stairs => pText.fixtureStairs,
  FixtureKind.mezzanine => pText.fixtureMezzanine,
  FixtureKind.roofWindow => pText.fixtureRoofWindow,
  FixtureKind.stairwell => pText.fixtureStairwell,
};

/// Hauteur à monter proposée : plafond plus l'épaisseur d'un plancher.
/// Hauteur à monter proposée : jusqu'à la mezzanine si elle a sa hauteur, sinon le plafond plus
/// l'épaisseur d'un plancher.
int defaultRiseMm(Room pRoom) => mezzanineFloorMm(pRoom.fixtures) ?? pRoom.ceilingHeightMm + 200;

/// Prises, interrupteurs, escalier, mezzanine et fenêtres de toit de la pièce.
class FixturesSection extends StatelessWidget {
  const FixturesSection({super.key, required this.room, required this.onChanged});

  final Room room;
  final ValueChanged<Room> onChanged;

  void _replace(Fixture pFixture) => onChanged(
    room.copyWith(
      fixtures: [
        for (final vFixture in room.fixtures) vFixture.id == pFixture.id ? pFixture : vFixture,
      ],
    ),
  );

  /// Trois gestes : l'élément, sa place, puis sa taille s'il en a une.
  Future<void> _add(BuildContext pContext) async {
    final vKind = await showModalBottomSheet<FixtureKind>(
      context: pContext,
      builder: (pSheetContext) {
        final vText = AppLocalizations.of(pSheetContext);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final vKind in FixtureKind.values)
                ListTile(
                  leading: Icon(fixtureIcon(vKind)),
                  title: Text(fixtureLabel(vText, vKind)),
                  onTap: () => Navigator.pop(pSheetContext, vKind),
                ),
            ],
          ),
        );
      },
    );
    if (vKind == null || !pContext.mounted) {
      return;
    }
    final vPoint = await pickPlanPoint(pContext, room);
    if (vPoint == null || !pContext.mounted) {
      return;
    }
    final vSize = defaultFixtureSize(vKind);
    var vFixture = Fixture(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      kind: vKind,
      xMm: vPoint.xMm,
      yMm: vPoint.yMm,
      widthMm: vSize.widthMm,
      depthMm: vSize.depthMm,
      riseMm: vKind == FixtureKind.stairs ? defaultRiseMm(room) : null,
    );
    if (hasArea(vKind)) {
      final vEdited = await editFixture(pContext, vFixture);
      if (vEdited == null) {
        return;
      }
      vFixture = vEdited;
    }
    onChanged(room.copyWith(fixtures: [...room.fixtures, vFixture]));
  }

  Future<void> _edit(BuildContext pContext, Fixture pFixture) async {
    final vEdited = await editFixture(pContext, pFixture);
    if (vEdited != null) {
      _replace(vEdited);
    }
  }

  Future<void> _move(BuildContext pContext, Fixture pFixture) async {
    final vPoint = await pickPlanPoint(pContext, room);
    if (vPoint != null) {
      _replace(pFixture.copyWith(xMm: vPoint.xMm, yMm: vPoint.yMm));
    }
  }

  String? _summary(AppLocalizations pText, Fixture pFixture) => switch (pFixture.kind) {
    FixtureKind.socket ||
    FixtureKind.lightSwitch => pFixture.count > 1 ? pText.fixtureBlock(pFixture.count) : null,
    FixtureKind.stairs => _stairs(pText, stairPlan(pFixture.riseMm ?? defaultRiseMm(room))),
    FixtureKind.mezzanine =>
      pFixture.riseMm == null
          ? pText.mezzanineSummary(formatSquareMetres(pFixture.areaM2))
          : pText.mezzanineFloorSummary(
              formatSquareMetres(pFixture.areaM2),
              formatCentimetres(pFixture.riseMm!),
            ),
    FixtureKind.roofWindow =>
      pFixture.plexi
          ? pText.plexiSummary(
              formatCentimetres(pFixture.widthMm),
              formatCentimetres(pFixture.depthMm),
            )
          : pText.roofWindowSummary(
              formatCentimetres(pFixture.widthMm),
              formatCentimetres(pFixture.depthMm),
            ),
    FixtureKind.stairwell => pText.stairwellSummary(
      formatCentimetres(pFixture.widthMm),
      formatCentimetres(pFixture.depthMm),
    ),
  };

  String _stairs(AppLocalizations pText, StairPlan pPlan) => pText.stairSummary(
    pPlan.risers,
    formatCentimetres(pPlan.riserMm),
    formatCentimetres(pPlan.goingMm),
    formatCentimetres(pPlan.runMm),
  );

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vSockets = fixtureCount(room.fixtures, FixtureKind.socket);
    final vSwitches = fixtureCount(room.fixtures, FixtureKind.lightSwitch);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(vText.fixturesTitle, style: vTheme.textTheme.titleMedium),
          subtitle: vSockets + vSwitches == 0
              ? null
              : Text('${vText.socketCount(vSockets)}, ${vText.switchCount(vSwitches)}'),
        ),
        if (room.fixtures.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(vText.fixturesEmpty),
          ),
        for (final vFixture in room.fixtures)
          ListTile(
            leading: Icon(fixtureIcon(vFixture.kind)),
            title: Text(fixtureLabel(vText, vFixture.kind)),
            subtitle: switch (_summary(vText, vFixture)) {
              final String vSummary => Text(vSummary),
              null => null,
            },
            onTap: () => _edit(context, vFixture),
            trailing: PopupMenuButton<String>(
              onSelected: (pAction) {
                switch (pAction) {
                  case 'move':
                    _move(context, vFixture);
                  case 'delete':
                    onChanged(
                      room.copyWith(
                        fixtures: [
                          for (final vOther in room.fixtures)
                            if (vOther.id != vFixture.id) vOther,
                        ],
                      ),
                    );
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'move', child: Text(vText.fixtureMove)),
                PopupMenuItem(value: 'delete', child: Text(vText.delete)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: room.walls.isEmpty ? null : () => _add(context),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(vText.addFixture),
          ),
        ),
      ],
    );
  }
}

/// Plan de la pièce dans une boîte de dialogue : le premier appui donne l'endroit.
Future<({int xMm, int yMm})?> pickPlanPoint(BuildContext pContext, Room pRoom) =>
    showDialog<({int xMm, int yMm})>(
      context: pContext,
      builder: (pDialogContext) {
        final vText = AppLocalizations.of(pDialogContext);

        return AlertDialog(
          title: Text(vText.fixturePlace),
          content: SizedBox(
            width: 320,
            child: RoomPlan(
              room: pRoom,
              wallNumbers: false,
              onTapPlan: (pXMm, pYMm) => Navigator.pop(pDialogContext, (xMm: pXMm, yMm: pYMm)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(pDialogContext), child: Text(vText.cancel)),
          ],
        );
      },
    );

/// Taille, hauteur d'escalier ou nombre de prises d'un élément.
Future<Fixture?> editFixture(BuildContext pContext, Fixture pFixture) => showDialog<Fixture>(
  context: pContext,
  builder: (pDialogContext) => _FixtureDialog(fixture: pFixture),
);

class _FixtureDialog extends StatefulWidget {
  const _FixtureDialog({required this.fixture});

  final Fixture fixture;

  @override
  State<_FixtureDialog> createState() => _FixtureDialogState();
}

class _FixtureDialogState extends State<_FixtureDialog> {
  late final _width = TextEditingController(text: formatCentimetres(widget.fixture.widthMm));
  late final _depth = TextEditingController(text: formatCentimetres(widget.fixture.depthMm));
  late final _rise = TextEditingController(
    text: widget.fixture.riseMm == null ? '' : formatCentimetres(widget.fixture.riseMm!),
  );
  late final _count = TextEditingController(text: '${widget.fixture.count}');
  late bool _plexi = widget.fixture.plexi;
  late bool _lShape = widget.fixture.hasNotch;
  late final _notchWidth = TextEditingController(
    text: widget.fixture.notchWidthMm == 0 ? '' : formatCentimetres(widget.fixture.notchWidthMm),
  );
  late final _notchDepth = TextEditingController(
    text: widget.fixture.notchDepthMm == 0 ? '' : formatCentimetres(widget.fixture.notchDepthMm),
  );
  late int _notchCorner = widget.fixture.notchCorner;
  String? _error;

  @override
  void dispose() {
    _width.dispose();
    _depth.dispose();
    _rise.dispose();
    _count.dispose();
    _notchWidth.dispose();
    _notchDepth.dispose();
    super.dispose();
  }

  void _submit() {
    final vText = AppLocalizations.of(context);
    final vFixture = widget.fixture;
    if (!hasArea(vFixture.kind)) {
      final vCount = parseWhole(_count.text);
      if (vCount == null || vCount < 1) {
        setState(() => _error = vText.invalidLength);
        return;
      }
      Navigator.pop(context, vFixture.copyWith(count: vCount));
      return;
    }
    final vWidth = parseCentimetres(_width.text);
    final vDepth = parseCentimetres(_depth.text);
    final vRise = switch (vFixture.kind) {
      FixtureKind.stairs => parseCentimetres(_rise.text),
      // Hauteur de plancher facultative pour une mezzanine
      FixtureKind.mezzanine => _rise.text.trim().isEmpty ? null : parseCentimetres(_rise.text),
      _ => null,
    };
    if (vWidth == null ||
        vWidth == 0 ||
        vDepth == null ||
        vDepth == 0 ||
        (vFixture.kind == FixtureKind.stairs && (vRise == null || vRise == 0)) ||
        (vFixture.kind == FixtureKind.mezzanine &&
            _rise.text.trim().isNotEmpty &&
            (vRise == null || vRise == 0))) {
      setState(() => _error = vText.invalidLength);
      return;
    }
    // Mezzanine en L : la découpe doit tenir dans le rectangle
    final vNotchWidth = _lShape ? parseCentimetres(_notchWidth.text) ?? 0 : 0;
    final vNotchDepth = _lShape ? parseCentimetres(_notchDepth.text) ?? 0 : 0;
    if (_lShape &&
        (vNotchWidth == 0 ||
            vNotchDepth == 0 ||
            vNotchWidth >= vWidth ||
            vNotchDepth >= vDepth)) {
      setState(() => _error = vText.mezzanineNotchInvalid);
      return;
    }
    Navigator.pop(
      context,
      vFixture.copyWith(
        widthMm: vWidth,
        depthMm: vDepth,
        riseMm: vRise,
        plexi: _plexi,
        notchWidthMm: vNotchWidth,
        notchDepthMm: vNotchDepth,
        notchCorner: _notchCorner,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vKind = widget.fixture.kind;
    const vNumbers = TextInputType.numberWithOptions(decimal: true);

    return AlertDialog(
      title: IconLine(fixtureIcon(vKind), fixtureLabel(vText, vKind)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasArea(vKind))
              TextField(
                controller: _count,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: vText.fixtureCount, errorText: _error),
              )
            else ...[
              TextField(
                controller: _width,
                autofocus: true,
                keyboardType: vNumbers,
                decoration: InputDecoration(
                  labelText: vText.fixtureWidth,
                  suffixText: vText.unitCm,
                  errorText: _error,
                ),
              ),
              TextField(
                controller: _depth,
                keyboardType: vNumbers,
                decoration: InputDecoration(
                  labelText: vText.fixtureDepth,
                  suffixText: vText.unitCm,
                ),
              ),
              if (vKind == FixtureKind.roofWindow)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(vText.fixturePlexi),
                  value: _plexi,
                  onChanged: (pValue) => setState(() => _plexi = pValue!),
                ),
              if (vKind == FixtureKind.stairs || vKind == FixtureKind.mezzanine)
                TextField(
                  controller: _rise,
                  keyboardType: vNumbers,
                  decoration: InputDecoration(
                    labelText: vKind == FixtureKind.stairs
                        ? vText.fixtureRise
                        : vText.mezzanineFloor,
                    suffixText: vText.unitCm,
                  ),
                ),
              if (vKind == FixtureKind.mezzanine) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(vText.mezzanineLShape),
                  value: _lShape,
                  onChanged: (pValue) => setState(() => _lShape = pValue),
                ),
                if (_lShape) ...[
                  TextField(
                    controller: _notchWidth,
                    keyboardType: vNumbers,
                    decoration: InputDecoration(
                      labelText: vText.mezzanineNotchWidth,
                      suffixText: vText.unitCm,
                    ),
                  ),
                  TextField(
                    controller: _notchDepth,
                    keyboardType: vNumbers,
                    decoration: InputDecoration(
                      labelText: vText.mezzanineNotchDepth,
                      suffixText: vText.unitCm,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(vText.mezzanineNotchCorner),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final (vCorner, vLabel) in [
                        (3, vText.cornerTopLeft),
                        (2, vText.cornerTopRight),
                        (0, vText.cornerBottomLeft),
                        (1, vText.cornerBottomRight),
                      ])
                        ChoiceChip(
                          label: Text(vLabel),
                          selected: _notchCorner == vCorner,
                          onSelected: (_) => setState(() => _notchCorner = vCorner),
                        ),
                    ],
                  ),
                ],
              ],
            ],
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
