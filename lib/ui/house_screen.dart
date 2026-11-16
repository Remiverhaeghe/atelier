import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/house.dart';
import '../logic/room.dart';
import '../state/worksites_controller.dart';
import 'house_3d.dart';
import 'theme.dart';

/// Plan de la maison : chaque pièce se touche pour la choisir, se glisse et se tourne.
class HouseScreen extends StatefulWidget {
  const HouseScreen({super.key, required this.controller, required this.worksiteId});

  final WorksitesController controller;
  final String worksiteId;

  @override
  State<HouseScreen> createState() => _HouseScreenState();
}

class _HouseScreenState extends State<HouseScreen> {
  String? _selected;

  /// Déplacement en cours, en millimètres, pas encore enregistré.
  Offset _drag = Offset.zero;

  /// Vue en 3D plutôt que le plan à plat.
  bool _view3d = false;

  void _save(Room pRoom) => widget.controller.updateRoom(widget.worksiteId, pRoom);

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (pContext, _) {
        final vWorksite = widget.controller.worksite(widget.worksiteId);
        if (vWorksite == null) {
          return const Scaffold();
        }
        final vRooms = houseRooms(vWorksite);
        final vSelected = vRooms.where((pRoom) => pRoom.id == _selected).firstOrNull;

        return Scaffold(
          appBar: AppBar(
            title: Text(vText.houseTitle),
            actions: [
              IconButton(
                tooltip: _view3d ? vText.house2d : vText.house3d,
                icon: Icon(_view3d ? Icons.map_outlined : Icons.view_in_ar_outlined),
                onPressed: () => setState(() => _view3d = !_view3d),
              ),
              IconButton(
                tooltip: vText.houseArrange,
                icon: const Icon(Icons.auto_awesome_mosaic_outlined),
                onPressed: () {
                  for (final vRoom in arrangeUnplaced(vRooms)) {
                    _save(vRoom);
                  }
                },
              ),
            ],
          ),
          body: vRooms.isEmpty
              ? Center(
                  child: Padding(padding: const EdgeInsets.all(24), child: Text(vText.houseEmpty)),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        _view3d ? vText.house3dHelp : vText.houseHelp,
                        style: vTheme.textTheme.bodySmall,
                      ),
                    ),
                    if (_view3d) Expanded(child: House3d(rooms: vRooms)) else Expanded(
                      child: LayoutBuilder(
                        builder: (pContext, pConstraints) {
                          final vFrame = _HouseFrame(vRooms, pConstraints.biggest);
                          Room? vHit(Offset pScreen) {
                            final vPoint = vFrame.toPlan(pScreen);
                            for (final vRoom in vRooms.reversed) {
                              if (_contains(houseOutline(vRoom), vPoint)) {
                                return vRoom;
                              }
                            }
                            return null;
                          }

                          return GestureDetector(
                            onTapUp: (pDetails) =>
                                setState(() => _selected = vHit(pDetails.localPosition)?.id),
                            onPanStart: (pDetails) {
                              final vRoom = vHit(pDetails.localPosition);
                              setState(() {
                                _selected = vRoom?.id ?? _selected;
                                _drag = Offset.zero;
                              });
                            },
                            onPanUpdate: (pDetails) => setState(
                              () => _drag +=
                                  Offset(pDetails.delta.dx, -pDetails.delta.dy) / vFrame.scale,
                            ),
                            onPanEnd: (_) {
                              if (vSelected != null && _drag != Offset.zero) {
                                _save(
                                  vSelected.copyWith(
                                    houseXMm: snap(vSelected.houseXMm + _drag.dx),
                                    houseYMm: snap(vSelected.houseYMm + _drag.dy),
                                  ),
                                );
                              }
                              setState(() => _drag = Offset.zero);
                            },
                            child: CustomPaint(
                              key: const ValueKey('house-plan'),
                              size: pConstraints.biggest,
                              painter: _HousePainter(
                                rooms: vRooms,
                                frame: vFrame,
                                selected: _selected,
                                drag: _drag,
                                colors: AtelierColors.of(context),
                                highlight: vTheme.colorScheme.primary,
                                labelStyle: vTheme.textTheme.labelLarge!.copyWith(
                                  fontFamily: titleFont,
                                  color: vTheme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (vSelected != null && !_view3d)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(vSelected.name, style: vTheme.textTheme.titleMedium),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () => _save(
                                vSelected.copyWith(
                                  houseQuarterTurns: vSelected.houseQuarterTurns + 1,
                                ),
                              ),
                              icon: const Icon(Icons.rotate_90_degrees_ccw),
                              label: Text(vText.houseRotate),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// Point dans un polygone, par le nombre de côtés croisés.
bool _contains(List<PlanPoint> pPolygon, PlanPoint pPoint) {
  var rInside = false;
  for (var vI = 0, vJ = pPolygon.length - 1; vI < pPolygon.length; vJ = vI++) {
    final vA = pPolygon[vI];
    final vB = pPolygon[vJ];
    if ((vA.y > pPoint.y) != (vB.y > pPoint.y) &&
        pPoint.x < (vB.x - vA.x) * (pPoint.y - vA.y) / (vB.y - vA.y) + vA.x) {
      rInside = !rInside;
    }
  }

  return rInside;
}

/// Repère commun à toutes les pièces, cadré sur la maison entière.
class _HouseFrame {
  _HouseFrame(List<Room> pRooms, Size pSize) {
    final vPoints = [for (final vRoom in pRooms) ...houseOutline(vRoom)];
    minX = vPoints.map((pPoint) => pPoint.x).reduce(math.min) - 1000;
    minY = vPoints.map((pPoint) => pPoint.y).reduce(math.min) - 1000;
    final vWidth = vPoints.map((pPoint) => pPoint.x).reduce(math.max) + 1000 - minX;
    final vHeight = vPoints.map((pPoint) => pPoint.y).reduce(math.max) + 1000 - minY;
    scale = math.min(pSize.width / vWidth, pSize.height / vHeight);
    height = pSize.height;
  }

  late final double minX;
  late final double minY;
  late final double scale;
  late final double height;

  Offset toScreen(PlanPoint pPoint) =>
      Offset((pPoint.x - minX) * scale, height - (pPoint.y - minY) * scale);

  PlanPoint toPlan(Offset pScreen) =>
      PlanPoint(pScreen.dx / scale + minX, (height - pScreen.dy) / scale + minY);
}

class _HousePainter extends CustomPainter {
  _HousePainter({
    required this.rooms,
    required this.frame,
    required this.selected,
    required this.drag,
    required this.colors,
    required this.highlight,
    required this.labelStyle,
  });

  final List<Room> rooms;
  final _HouseFrame frame;
  final String? selected;
  final Offset drag;
  final AtelierColors colors;
  final Color highlight;
  final TextStyle labelStyle;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vGrid = Paint()..color = colors.grid;
    final vStep = 1000 * frame.scale;
    if (vStep > 6) {
      for (var vX = (-frame.minX * frame.scale) % vStep; vX < pSize.width; vX += vStep) {
        pCanvas.drawLine(Offset(vX, 0), Offset(vX, pSize.height), vGrid);
      }
      for (var vY = pSize.height - (-frame.minY * frame.scale) % vStep; vY > 0; vY -= vStep) {
        pCanvas.drawLine(Offset(0, vY), Offset(pSize.width, vY), vGrid);
      }
    }
    for (final vRoom in rooms) {
      final vIsSelected = vRoom.id == selected;
      final vShift = vIsSelected ? Offset(drag.dx, -drag.dy) * frame.scale : Offset.zero;
      final vPoints = [for (final vPoint in houseOutline(vRoom)) frame.toScreen(vPoint) + vShift];
      final vPath = Path()..addPolygon(vPoints, vRoom.closed);
      pCanvas.drawPath(
        vPath,
        Paint()..color = vIsSelected ? highlight.withValues(alpha: 0.15) : colors.wood,
      );
      pCanvas.drawPath(
        vPath,
        Paint()
          ..color = vIsSelected ? highlight : colors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = vIsSelected ? 4 : 3,
      );
      final vCenter =
          vPoints.fold(Offset.zero, (pSum, pPoint) => pSum + pPoint) / vPoints.length.toDouble();
      final vLabel = TextPainter(
        text: TextSpan(text: vRoom.name, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      vLabel.paint(pCanvas, vCenter - Offset(vLabel.width / 2, vLabel.height / 2));
    }
  }

  @override
  bool shouldRepaint(_HousePainter pOld) =>
      pOld.rooms != rooms || pOld.selected != selected || pOld.drag != drag;
}
