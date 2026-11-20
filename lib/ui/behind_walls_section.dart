import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/house_book.dart';
import '../logic/room.dart';
import '../logic/time_tracking.dart';
import '../logic/units.dart';
import 'photos.dart';
import 'theme.dart';

/// Nom de la surface d'une photo d'avant fermeture : un mur, le sol ou le plafond.
String surfaceLabel(AppLocalizations pText, int pWallIndex) => switch (pWallIndex) {
  floorPhotoIndex => pText.behindFloor,
  ceilingPhotoIndex => pText.behindCeiling,
  _ => pText.wallTitle(pWallIndex + 1),
};

String joistPlaceLabel(AppLocalizations pText, JoistPlace pPlace) => switch (pPlace) {
  JoistPlace.floor => pText.behindJoistFloor,
  JoistPlace.ceiling => pText.behindJoistCeiling,
};

/// Ce qui reste caché derrière le placo : solives repérées et photos prises avant de fermer.
class BehindWallsSection extends StatelessWidget {
  const BehindWallsSection({
    super.key,
    required this.room,
    required this.onChanged,
    this.photos,
    this.now = DateTime.now,
  });

  final Room room;
  final ValueChanged<Room> onChanged;

  /// Prise de photo ; remplaçable dans les tests.
  final PhotoTaker? photos;
  final DateTime Function() now;

  BehindWalls get _hidden => room.behindWalls;

  Future<void> _addJoists(BuildContext pContext) async {
    final vJoists = await showDialog<JoistSet>(
      context: pContext,
      builder: (_) => _JoistDialog(room: room),
    );
    if (vJoists != null) {
      onChanged(room.copyWith(behindWalls: _hidden.copyWith(joists: [..._hidden.joists, vJoists])));
    }
  }

  Future<void> _addPhoto(BuildContext pContext) async {
    final vChoice = await showDialog<(int, String)>(
      context: pContext,
      builder: (_) => _PhotoDialog(room: room),
    );
    if (vChoice == null) {
      return;
    }
    final vId = 'ferme-${now().microsecondsSinceEpoch}';
    final vPath = await (photos ?? takePhoto)(vId);
    if (vPath == null) {
      return;
    }
    final vPhoto = ClosingPhoto(
      id: vId,
      wallIndex: vChoice.$1,
      path: vPath,
      day: dayOf(now()),
      note: vChoice.$2,
    );
    onChanged(room.copyWith(behindWalls: _hidden.copyWith(photos: [..._hidden.photos, vPhoto])));
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    String vCm(int pMm) => formatCentimetres(pMm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(vText.behindTitle, style: vTheme.textTheme.titleMedium),
          subtitle: Text(vText.behindHelp),
        ),
        for (final vWall in wallsToPhotograph(room))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IconLine(
              Icons.photo_camera_outlined,
              vText.behindToPhotograph(vWall + 1),
              color: vTheme.colorScheme.error,
            ),
          ),
        for (final vJoists in _hidden.joists)
          ListTile(
            leading: const Icon(Icons.view_week_outlined),
            title: Text(
              vText.behindJoistLine(
                joistPlaceLabel(vText, vJoists.place),
                vJoists.wallIndex + 1,
                vCm(vJoists.spacingMm),
              ),
            ),
            subtitle: Text(
              vText.behindJoistAxes(
                vCm(vJoists.widthMm),
                vCm(vJoists.heightMm),
                joistAxes(room, vJoists).map(vCm).join(', '),
              ),
            ),
            trailing: IconButton(
              tooltip: vText.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onChanged(
                room.copyWith(
                  behindWalls: _hidden.copyWith(
                    joists: [
                      for (final vOther in _hidden.joists)
                        if (vOther.id != vJoists.id) vOther,
                    ],
                  ),
                ),
              ),
            ),
          ),
        for (final vPhoto in _hidden.photos)
          ListTile(
            leading: const Icon(Icons.photo_outlined),
            title: Text('${surfaceLabel(vText, vPhoto.wallIndex)}, ${vPhoto.day}'),
            subtitle: vPhoto.note.isEmpty ? null : Text(vPhoto.note),
            onTap: () => showPhoto(context, vPhoto.path),
            trailing: IconButton(
              tooltip: vText.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onChanged(
                room.copyWith(
                  behindWalls: _hidden.copyWith(
                    photos: [
                      for (final vOther in _hidden.photos)
                        if (vOther.id != vPhoto.id) vOther,
                    ],
                  ),
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
                onPressed: room.walls.isEmpty ? null : () => _addJoists(context),
                icon: const Icon(Icons.view_week_outlined),
                label: Text(vText.behindAddJoists),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _addPhoto(context),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(vText.behindAddPhoto),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Plancher ou plafond, mur de repère, première solive, entraxe et section.
class _JoistDialog extends StatefulWidget {
  const _JoistDialog({required this.room});

  final Room room;

  @override
  State<_JoistDialog> createState() => _JoistDialogState();
}

class _JoistDialogState extends State<_JoistDialog> {
  JoistPlace _place = JoistPlace.ceiling;
  int _wall = 0;
  int _spacing = joistSpacingsMm.last;
  final _first = TextEditingController();
  final _width = TextEditingController(text: '7,5');
  final _height = TextEditingController(text: '20');
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  void _submit() {
    final vFirst = parseCentimetres(_first.text);
    final vWidth = parseCentimetres(_width.text);
    final vHeight = parseCentimetres(_height.text);
    if (vFirst == null || vWidth == null || vHeight == null) {
      setState(() => _error = AppLocalizations.of(context).invalidLength);
      return;
    }
    Navigator.pop(
      context,
      JoistSet(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        place: _place,
        wallIndex: _wall,
        firstMm: vFirst,
        spacingMm: _spacing,
        widthMm: vWidth,
        heightMm: vHeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    TextField vField(TextEditingController pController, String pLabel, {String? pError}) =>
        TextField(
          controller: pController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: pLabel,
            suffixText: vText.unitCm,
            errorText: pError,
          ),
        );

    return AlertDialog(
      title: Text(vText.behindAddJoists),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<JoistPlace>(
              segments: [
                for (final vPlace in JoistPlace.values)
                  ButtonSegment(value: vPlace, label: Text(joistPlaceLabel(vText, vPlace))),
              ],
              selected: {_place},
              onSelectionChanged: (pPlace) => setState(() => _place = pPlace.single),
            ),
            DropdownButtonFormField<int>(
              initialValue: _wall,
              decoration: InputDecoration(labelText: vText.behindJoistWall),
              items: [
                for (var vIndex = 0; vIndex < widget.room.walls.length; vIndex++)
                  DropdownMenuItem(value: vIndex, child: Text(vText.wallTitle(vIndex + 1))),
              ],
              onChanged: (pWall) => setState(() => _wall = pWall!),
            ),
            vField(_first, vText.behindJoistFirst, pError: _error),
            DropdownButtonFormField<int>(
              initialValue: _spacing,
              decoration: InputDecoration(labelText: vText.behindJoistSpacing),
              items: [
                for (final vSpacing in joistSpacingsMm)
                  DropdownMenuItem(
                    value: vSpacing,
                    child: Text('${formatCentimetres(vSpacing)} ${vText.unitCm}'),
                  ),
              ],
              onChanged: (pSpacing) => setState(() => _spacing = pSpacing!),
            ),
            vField(_width, vText.behindJoistWidth),
            vField(_height, vText.behindJoistHeight),
            const SizedBox(height: 8),
            Text(vText.behindJoistHow, style: Theme.of(context).textTheme.bodySmall),
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

/// Surface photographiée et note, avant d'ouvrir l'appareil photo.
class _PhotoDialog extends StatefulWidget {
  const _PhotoDialog({required this.room});

  final Room room;

  @override
  State<_PhotoDialog> createState() => _PhotoDialogState();
}

class _PhotoDialogState extends State<_PhotoDialog> {
  late int _surface = widget.room.walls.isEmpty ? ceilingPhotoIndex : 0;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(vText.behindAddPhoto),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _surface,
              decoration: InputDecoration(labelText: vText.behindSurface),
              items: [
                for (final vIndex in [
                  for (var vWall = 0; vWall < widget.room.walls.length; vWall++) vWall,
                  floorPhotoIndex,
                  ceilingPhotoIndex,
                ])
                  DropdownMenuItem(value: vIndex, child: Text(surfaceLabel(vText, vIndex))),
              ],
              onChanged: (pSurface) => setState(() => _surface = pSurface!),
            ),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: vText.behindNote),
            ),
            const SizedBox(height: 8),
            Text(vText.behindPhotoHow, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_surface, _note.text.trim())),
          child: Text(vText.behindTake),
        ),
      ],
    );
  }
}
