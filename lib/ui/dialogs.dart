import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/room.dart';
import '../logic/units.dart';

/// Demande un nom ; null si l'utilisateur annule.
Future<String?> askName(BuildContext pContext, {required String pTitle, required String pLabel}) =>
    showDialog<String>(
      context: pContext,
      builder: (pDialogContext) => _NameDialog(title: pTitle, label: pLabel),
    );

/// Demande confirmation avant une suppression.
Future<bool> confirmDelete(BuildContext pContext, String pName) async {
  final vText = AppLocalizations.of(pContext);
  final rConfirmed = await showDialog<bool>(
    context: pContext,
    builder: (pDialogContext) => AlertDialog(
      content: Text(vText.deleteConfirm(pName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(pDialogContext, false),
          child: Text(vText.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(pDialogContext, true),
          child: Text(vText.delete),
        ),
      ],
    ),
  );

  return rConfirmed ?? false;
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit({bool pNext = false}) {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = AppLocalizations.of(context).nameRequired);
      return;
    }
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label, errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(onPressed: _submit, child: Text(vText.save)),
      ],
    );
  }
}

/// Saisie ou modification d'un mur ; null si l'utilisateur annule.
/// Mur saisi ; [next] demande d'enchaîner sur le mur suivant.
typedef WallEntry = ({Wall wall, bool next});

Future<WallEntry?> editWall(BuildContext pContext, {required int pNumber, Wall? pWall}) =>
    showDialog<WallEntry>(
      context: pContext,
      builder: (pDialogContext) => _WallDialog(number: pNumber, wall: pWall),
    );

class _WallDialog extends StatefulWidget {
  const _WallDialog({required this.number, this.wall});

  final int number;
  final Wall? wall;

  @override
  State<_WallDialog> createState() => _WallDialogState();
}

class _WallDialogState extends State<_WallDialog> {
  late final TextEditingController _length;
  late final TextEditingController _angle;
  late bool _freeEnd;
  String? _lengthError;
  String? _angleError;

  @override
  void initState() {
    super.initState();
    final vWall = widget.wall;
    _length = TextEditingController(text: vWall == null ? '' : formatCentimetres(vWall.lengthMm));
    _angle = TextEditingController(text: formatAngle(vWall?.angleToNextDeg ?? 90));
    _freeEnd = vWall?.freeEndAfter ?? false;
  }

  @override
  void dispose() {
    _length.dispose();
    _angle.dispose();
    super.dispose();
  }

  void _submit({bool pNext = false}) {
    final vText = AppLocalizations.of(context);
    final vLength = parseCentimetres(_length.text);
    final vAngle = parseDegrees(_angle.text);
    setState(() {
      _lengthError = vLength == null || vLength == 0 ? vText.invalidLength : null;
      _angleError = vAngle == null ? vText.invalidAngle : null;
    });
    if (_lengthError != null || _angleError != null) {
      return;
    }
    final vBase = widget.wall ?? Wall(lengthMm: vLength!);
    final WallEntry vEntry = (
      wall: vBase.copyWith(lengthMm: vLength, angleToNextDeg: vAngle, freeEndAfter: _freeEnd),
      next: pNext,
    );
    Navigator.pop(context, vEntry);
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    const vNumbers = TextInputType.numberWithOptions(decimal: true);

    return AlertDialog(
      title: Text(vText.wallTitle(widget.number)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _length,
              autofocus: true,
              keyboardType: vNumbers,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(pNext: widget.wall == null),
              decoration: InputDecoration(
                labelText: vText.wallLength,
                errorText: _lengthError,
                suffixText: vText.unitCm,
              ),
            ),
            TextField(
              controller: _angle,
              keyboardType: vNumbers,
              decoration: InputDecoration(
                labelText: vText.wallAngle,
                helperText: vText.wallAngleHelp,
                helperMaxLines: 2,
                errorText: _angleError,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _freeEnd,
              title: Text(vText.freeEnd),
              onChanged: (pValue) => setState(() => _freeEnd = pValue),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        if (widget.wall == null)
          OutlinedButton(onPressed: _submit, child: Text(vText.save))
        else
          FilledButton(onPressed: _submit, child: Text(vText.save)),
        if (widget.wall == null)
          FilledButton(onPressed: () => _submit(pNext: true), child: Text(vText.nextWall)),
      ],
    );
  }
}

/// Angle sans décimale inutile : 90 plutôt que 90.0.
String formatAngle(double pAngle) {
  final rText = pAngle == pAngle.roundToDouble()
      ? pAngle.round().toString()
      : pAngle.toString().replaceAll('.', ',');

  return rText;
}

/// Ajout d'une porte ou d'un passage dans un mur de longueur donnée.
Future<Opening?> addOpening(BuildContext pContext, int pWallLengthMm) => showDialog<Opening>(
  context: pContext,
  builder: (pDialogContext) => _OpeningDialog(wallLengthMm: pWallLengthMm),
);

class _OpeningDialog extends StatefulWidget {
  const _OpeningDialog({required this.wallLengthMm});

  final int wallLengthMm;

  @override
  State<_OpeningDialog> createState() => _OpeningDialogState();
}

class _OpeningDialogState extends State<_OpeningDialog> {
  final _offset = TextEditingController(text: '0');
  final _width = TextEditingController(text: '83');
  OpeningKind _kind = OpeningKind.door;
  String? _error;

  @override
  void dispose() {
    _offset.dispose();
    _width.dispose();
    super.dispose();
  }

  void _submit({bool pNext = false}) {
    final vText = AppLocalizations.of(context);
    final vOffset = parseCentimetres(_offset.text);
    final vWidth = parseCentimetres(_width.text);
    if (vOffset == null || vWidth == null || vWidth == 0) {
      setState(() => _error = vText.invalidLength);
      return;
    }
    if (vOffset + vWidth > widget.wallLengthMm) {
      setState(() => _error = vText.openingOutside);
      return;
    }
    Navigator.pop(context, Opening(kind: _kind, offsetMm: vOffset, widthMm: vWidth));
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    const vNumbers = TextInputType.numberWithOptions(decimal: true);

    return AlertDialog(
      title: Text(vText.addOpening),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<OpeningKind>(
              segments: [
                ButtonSegment(value: OpeningKind.door, label: Text(vText.openingDoor)),
                ButtonSegment(value: OpeningKind.passage, label: Text(vText.openingPassage)),
              ],
              selected: {_kind},
              onSelectionChanged: (pSelection) => setState(() => _kind = pSelection.first),
            ),
            TextField(
              controller: _offset,
              keyboardType: vNumbers,
              decoration: InputDecoration(labelText: vText.openingOffset),
            ),
            TextField(
              controller: _width,
              keyboardType: vNumbers,
              decoration: InputDecoration(labelText: vText.openingWidth, errorText: _error),
            ),
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

/// Nom affiché d'un type d'obstacle.
String obstacleLabel(AppLocalizations pText, ObstacleKind pKind) => switch (pKind) {
  ObstacleKind.radiator => pText.obstacleRadiator,
  ObstacleKind.pipe => pText.obstaclePipe,
  ObstacleKind.cupboard => pText.obstacleCupboard,
  ObstacleKind.fireplace => pText.obstacleFireplace,
  ObstacleKind.stairFoot => pText.obstacleStairFoot,
};

/// Ajout d'un obstacle le long d'un des murs de la pièce.
Future<Obstacle?> addObstacle(BuildContext pContext, Room pRoom) => showDialog<Obstacle>(
  context: pContext,
  builder: (pDialogContext) => _ObstacleDialog(room: pRoom),
);

class _ObstacleDialog extends StatefulWidget {
  const _ObstacleDialog({required this.room});

  final Room room;

  @override
  State<_ObstacleDialog> createState() => _ObstacleDialogState();
}

class _ObstacleDialogState extends State<_ObstacleDialog> {
  final _offset = TextEditingController(text: '0');
  final _width = TextEditingController();
  final _depth = TextEditingController(text: '0');
  ObstacleKind _kind = ObstacleKind.radiator;
  int _wallIndex = 0;
  String? _error;

  @override
  void dispose() {
    _offset.dispose();
    _width.dispose();
    _depth.dispose();
    super.dispose();
  }

  /// Seuls le placard et la cheminée retirent une zone au parquet.
  bool get _hasDepth => _kind == ObstacleKind.cupboard || _kind == ObstacleKind.fireplace;

  void _submit({bool pNext = false}) {
    final vText = AppLocalizations.of(context);
    final vOffset = parseCentimetres(_offset.text);
    final vWidth = parseCentimetres(_width.text);
    final vDepth = _hasDepth ? parseCentimetres(_depth.text) : 0;
    if (vOffset == null || vWidth == null || vWidth == 0 || vDepth == null) {
      setState(() => _error = vText.invalidLength);
      return;
    }
    if (vOffset + vWidth > widget.room.walls[_wallIndex].lengthMm) {
      setState(() => _error = vText.openingOutside);
      return;
    }
    Navigator.pop(
      context,
      Obstacle(
        kind: _kind,
        wallIndex: _wallIndex,
        offsetMm: vOffset,
        widthMm: vWidth,
        depthMm: vDepth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    const vNumbers = TextInputType.numberWithOptions(decimal: true);

    return AlertDialog(
      title: Text(vText.addObstacle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ObstacleKind>(
              initialValue: _kind,
              items: [
                for (final vKind in ObstacleKind.values)
                  DropdownMenuItem(value: vKind, child: Text(obstacleLabel(vText, vKind))),
              ],
              onChanged: (pKind) => setState(() => _kind = pKind ?? _kind),
            ),
            DropdownButtonFormField<int>(
              initialValue: _wallIndex,
              decoration: InputDecoration(labelText: vText.obstacleWall),
              items: [
                for (var vIndex = 0; vIndex < widget.room.walls.length; vIndex++)
                  DropdownMenuItem(value: vIndex, child: Text(vText.wallTitle(vIndex + 1))),
              ],
              onChanged: (pIndex) => setState(() => _wallIndex = pIndex ?? _wallIndex),
            ),
            TextField(
              controller: _offset,
              keyboardType: vNumbers,
              decoration: InputDecoration(labelText: vText.openingOffset),
            ),
            TextField(
              controller: _width,
              keyboardType: vNumbers,
              decoration: InputDecoration(labelText: vText.openingWidth, errorText: _error),
            ),
            if (_hasDepth)
              TextField(
                controller: _depth,
                keyboardType: vNumbers,
                decoration: InputDecoration(labelText: vText.obstacleDepth),
              ),
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
