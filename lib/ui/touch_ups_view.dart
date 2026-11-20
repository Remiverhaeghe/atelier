
import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/room.dart';
import '../logic/touch_up.dart';
import '../logic/work_templates.dart';
import '../storage/photo_store.dart';
import 'photo_annotator.dart';
import 'photos.dart';
import 'room_plan.dart';
import 'theme.dart';
import 'templates_texts.dart';
import 'thermal_dialog.dart';
import 'touch_up_dialog.dart';

/// Reprises de la pièce : liste à cocher passage par passage, repères sur le plan et photos.
class TouchUpsView extends StatefulWidget {
  const TouchUpsView({super.key, required this.room, required this.onChanged, this.photos});

  final Room room;
  final ValueChanged<Room> onChanged;

  /// Prise de photo ; remplaçable dans les tests.
  final PhotoTaker? photos;

  @override
  State<TouchUpsView> createState() => _TouchUpsViewState();
}

class _TouchUpsViewState extends State<TouchUpsView> {
  /// Reprise en attente d'un appui sur le plan.
  String? _placing;

  Room get _room => widget.room;

  void _replace(TouchUp pTouchUp) => widget.onChanged(
    _room.copyWith(
      touchUps: [
        for (final vTouchUp in _room.touchUps) vTouchUp.id == pTouchUp.id ? pTouchUp : vTouchUp,
      ],
    ),
  );

  /// Saisie à la suite : « Reprise suivante » enregistre et rouvre la saisie.
  /// Étapes d'un modèle ajoutées d'un coup, sans doubler celles déjà notées.
  Future<void> _addTemplate() async {
    final vText = AppLocalizations.of(context);
    final vTemplate = await showDialog<WorkTemplate>(
      context: context,
      builder: (pDialog) => SimpleDialog(
        title: Text(vText.templateTitle),
        children: [
          for (final vTemplate in WorkTemplate.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(pDialog, vTemplate),
              child: ListTile(
                title: Text(templateLabel(vText, vTemplate)),
                subtitle: Text(
                  vTemplate.steps.map((pStep) => templateStepLabel(vText, pStep.$1)).join(', '),
                ),
              ),
            ),
        ],
      ),
    );
    if (vTemplate == null) {
      return;
    }
    final vStamp = DateTime.now().microsecondsSinceEpoch;
    final vSteps = missingSteps(vTemplate, {
      for (final vTouchUp in _room.touchUps) vTouchUp.label,
    }, (pStep) => templateStepLabel(vText, pStep));
    widget.onChanged(
      _room.copyWith(
        touchUps: [
          ..._room.touchUps,
          for (final (vIndex, (vStep, vPasses)) in vSteps.indexed)
            TouchUp(id: '$vStamp-$vIndex', label: templateStepLabel(vText, vStep), passes: vPasses),
        ],
      ),
    );
  }

  Future<void> _add() async {
    var vRoom = _room;
    while (mounted) {
      final vEntry = await editTouchUp(context);
      if (vEntry == null) {
        return;
      }
      vRoom = vRoom.copyWith(touchUps: [...vRoom.touchUps, vEntry.touchUp]);
      widget.onChanged(vRoom);
      if (!vEntry.next) {
        return;
      }
    }
  }

  /// Contrôle de finition : photo, cercles autour de ce qui ne va pas, reprise créée.
  Future<void> _addFromPhoto() async {
    final vText = AppLocalizations.of(context);
    final vId = DateTime.now().microsecondsSinceEpoch.toString();
    final vPath = await (widget.photos ?? takePhoto)(vId);
    if (vPath == null || !mounted) {
      return;
    }
    final vMarks = await annotatePhoto(context, vPath, const []);
    if (vMarks == null) {
      return;
    }
    widget.onChanged(
      _room.copyWith(
        touchUps: [
          ..._room.touchUps,
          TouchUp(id: vId, label: vText.finishCheckLabel, photoPath: vPath, photoMarks: vMarks),
        ],
      ),
    );
  }

  /// Relevé de caméra thermique ajouté comme reprise, à placer ensuite sur le plan.
  Future<void> _addThermal() async {
    final vTouchUp = await addThermalTouchUp(context, pImages: widget.photos, pRoom: _room);
    if (vTouchUp != null) {
      widget.onChanged(_room.copyWith(touchUps: [..._room.touchUps, vTouchUp]));
    }
  }

  Future<void> _edit(TouchUp pTouchUp) async {
    final vEntry = await editTouchUp(context, pTouchUp: pTouchUp);
    if (vEntry != null) {
      _replace(vEntry.touchUp);
    }
  }

  Future<void> _photo(TouchUp pTouchUp) async {
    final vPath = await (widget.photos ?? takePhoto)(pTouchUp.id);
    if (vPath != null) {
      _replace(pTouchUp.copyWith(photoPath: vPath));
    }
  }

  void _place(int pXMm, int pYMm) {
    final vId = _placing;
    if (vId == null) {
      return;
    }
    final vTouchUp = _room.touchUps.firstWhere((pTouchUp) => pTouchUp.id == vId);
    setState(() => _placing = null);
    _replace(vTouchUp.copyWith(markerXMm: pXMm, markerYMm: pYMm));
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPasses = touchUpPasses(_room.touchUps);
    final vMarkers = <PlanMarker>[
      for (var vIndex = 0; vIndex < _room.touchUps.length; vIndex++)
        if (_room.touchUps[vIndex].hasMarker)
          (
            number: vIndex + 1,
            xMm: _room.touchUps[vIndex].markerXMm!,
            yMm: _room.touchUps[vIndex].markerYMm!,
            done: _room.touchUps[vIndex].done,
          ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (_room.touchUps.isNotEmpty) ...[
          ListTile(
            title: Text(
              vText.touchUpsProgress(vPasses.done, vPasses.total),
              style: vTheme.textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LinearProgressIndicator(
              value: vPasses.total == 0 ? 0 : vPasses.done / vPasses.total,
            ),
          ),
        ],
        if (_room.walls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: RoomPlan(room: _room, markers: vMarkers, onTapPlan: _place, wallNumbers: false),
          ),
        if (_placing != null)
          Card(
            color: vTheme.colorScheme.tertiaryContainer,
            child: ListTile(
              leading: const Icon(Icons.touch_app_outlined),
              title: Text(vText.placeHint),
              trailing: TextButton(
                onPressed: () => setState(() => _placing = null),
                child: Text(vText.cancel),
              ),
            ),
          ),
        if (_room.touchUps.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text(vText.touchUpsEmpty, style: vTheme.textTheme.bodyLarge),
          ),
        for (var vIndex = 0; vIndex < _room.touchUps.length; vIndex++)
          _TouchUpCard(
            number: vIndex + 1,
            touchUp: _room.touchUps[vIndex],
            canPlace: _room.walls.isNotEmpty,
            onChanged: _replace,
            onEdit: () => _edit(_room.touchUps[vIndex]),
            onPlace: () => setState(() => _placing = _room.touchUps[vIndex].id),
            onPhoto: () => _photo(_room.touchUps[vIndex]),
            onDelete: () =>
                widget.onChanged(_room.copyWith(touchUps: [..._room.touchUps]..removeAt(vIndex))),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _addFromPhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(vText.finishCheck),
              ),
              FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: Text(vText.addTouchUp),
              ),
              OutlinedButton.icon(
                onPressed: _addTemplate,
                icon: const Icon(Icons.playlist_add),
                label: Text(vText.templateTitle),
              ),
              OutlinedButton.icon(
                onPressed: _addThermal,
                icon: const Icon(Icons.thermostat_outlined),
                label: Text(vText.thermalTitle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TouchUpCard extends StatelessWidget {
  const _TouchUpCard({
    required this.number,
    required this.touchUp,
    required this.canPlace,
    required this.onChanged,
    required this.onEdit,
    required this.onPlace,
    required this.onPhoto,
    required this.onDelete,
  });

  final int number;
  final TouchUp touchUp;
  final bool canPlace;
  final ValueChanged<TouchUp> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onPlace;
  final VoidCallback onPhoto;
  final VoidCallback onDelete;

  Future<void> _annotate(BuildContext pContext) async {
    final vMarks = await annotatePhoto(pContext, touchUp.photoPath!, touchUp.photoMarks);
    if (vMarks != null) {
      onChanged(touchUp.copyWith(photoMarks: vMarks));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vColors = vTheme.colorScheme;
    final vPhoto = touchUp.photoPath;

    return Card(
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: touchUp.done ? vColors.primary : vColors.surfaceContainerHigh,
                foregroundColor: touchUp.done ? vColors.onPrimary : vColors.onSurface,
                child: touchUp.done
                    ? const Icon(Icons.check, size: 16)
                    : Text('$number', style: const TextStyle(fontFamily: titleFont)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      touchUp.label,
                      style: vTheme.textTheme.titleMedium!.copyWith(
                        decoration: touchUp.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (touchUp.note.isNotEmpty) Text(touchUp.note),
                    if (touchUp.photoMarks.isNotEmpty)
                      Text(
                        vText.photoMarksCount(touchUp.photoMarks.length),
                        style: TextStyle(color: vColors.error),
                      ),
                    if (touchUp.toBuy.isNotEmpty)
                      IconLine(Icons.shopping_cart_outlined, touchUp.toBuy),
                    Wrap(
                      children: [
                        for (var vPass = 0; vPass < touchUp.passes; vPass++)
                          Tooltip(
                            message: vText.passLabel(vPass + 1),
                            child: Checkbox(
                              visualDensity: VisualDensity.compact,
                              value: vPass < touchUp.donePasses,
                              onChanged: (_) => onChanged(touchUp.togglePass(vPass)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (vPhoto != null)
                GestureDetector(
                  onTap: () => showPhoto(context, vPhoto),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image(image: photoProvider(vPhoto),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (pAction) {
                  switch (pAction) {
                    case 'edit':
                      onEdit();
                    case 'place':
                      onPlace();
                    case 'unplace':
                      onChanged(touchUp.copyWith(clearMarker: true));
                    case 'photo':
                      onPhoto();
                    case 'unphoto':
                      onChanged(touchUp.copyWith(clearPhoto: true));
                    case 'annotate':
                      _annotate(context);
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(vText.edit)),
                  if (canPlace) PopupMenuItem(value: 'place', child: Text(vText.placeOnPlan)),
                  if (touchUp.hasMarker)
                    PopupMenuItem(value: 'unplace', child: Text(vText.removeMarker)),
                  PopupMenuItem(value: 'photo', child: Text(vText.takePhoto)),
                  if (vPhoto != null)
                    PopupMenuItem(value: 'annotate', child: Text(vText.annotateTitle)),
                  if (vPhoto != null)
                    PopupMenuItem(value: 'unphoto', child: Text(vText.removePhoto)),
                  PopupMenuItem(value: 'delete', child: Text(vText.delete)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
