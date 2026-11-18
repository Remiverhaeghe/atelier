import 'achievements_screen.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/layout.dart';
import '../logic/progress.dart';
import '../logic/shopping.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import '../state/worksites_controller.dart';
import 'dialogs.dart';
import 'room_screen.dart';
import 'shopping_screen.dart';
import 'shopping_texts.dart';
import 'plan_thumbnail.dart';
import 'planning_card.dart';
import 'notebook.dart';
import 'theme.dart';
import 'time_screen.dart';
import 'visit_screen.dart';
import 'warranties_screen.dart';
import 'transfer.dart';
import 'elec_plan_screen.dart';
import 'goal_card.dart';
import 'heating_screen.dart';
import 'house_screen.dart';
import 'journal_screen.dart';
import 'living_area_screen.dart';
import 'loans_screen.dart';
import 'moisture_screen.dart';
import 'offcuts_screen.dart';
import 'plexi_screen.dart';
import 'quote_pdf.dart';
import 'journal_pdf.dart';
import 'reminders_card.dart';
import 'review_screen.dart';

/// Pièces d'un chantier.
class WorksiteScreen extends StatelessWidget {
  const WorksiteScreen({super.key, required this.controller, required this.worksiteId, this.today});

  final WorksitesController controller;
  final String worksiteId;

  /// Jour de l'objectif ; aujourd'hui si absent, fixé dans les tests.
  final DateTime? today;

  void _open(BuildContext pContext, String pRoomId) => Navigator.push(
    pContext,
    MaterialPageRoute<void>(
      builder: (_) => RoomScreen(controller: controller, worksiteId: worksiteId, roomId: pRoomId),
    ),
  );

  void _openShopping(BuildContext pContext) => Navigator.push(
    pContext,
    MaterialPageRoute<void>(
      builder: (_) => ShoppingScreen(controller: controller, worksiteId: worksiteId),
    ),
  );

  Future<void> _create(BuildContext pContext) async {
    final vText = AppLocalizations.of(pContext);
    final vName = await askName(pContext, pTitle: vText.newRoom, pLabel: vText.roomName);
    if (vName == null) {
      return;
    }
    final vRoom = await controller.addRoom(worksiteId, vName);
    if (pContext.mounted) {
      _open(pContext, vRoom.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (pContext, _) {
        final vWorksite = controller.worksite(worksiteId);
        if (vWorksite == null) {
          return const Scaffold();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(vWorksite.name),
            actions: [
              IconButton(
                tooltip: vText.badgesTitle,
                icon: const Icon(Icons.emoji_events_outlined),
                onPressed: () => Navigator.push(
                  pContext,
                  MaterialPageRoute<void>(builder: (_) => AchievementsScreen(worksite: vWorksite)),
                ),
              ),
              IconButton(
                tooltip: vText.shoppingTitle,
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(
                  pContext,
                  MaterialPageRoute<void>(
                    builder: (_) => ShoppingScreen(controller: controller, worksiteId: worksiteId),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (pAction) {
                  switch (pAction) {
                    case 'export':
                      exportWorksite(vWorksite);
                    case 'plan':
                      exportPlanFile(vWorksite);
                    case 'gltf':
                      exportGltfFile(vWorksite);
                    case 'dxf':
                      exportDxfFile(vWorksite);
                    case 'quote':
                      Printing.layoutPdf(
                        name: vText.quoteTitle(vWorksite.name),
                        onLayout: (_) => buildQuotePdf(
                          vText,
                          vWorksite,
                          pToday: today ?? DateTime.now(),
                          pRead: readPhotoFile,
                        ),
                      );
                    case 'homeAssistant':
                      exportHomeAssistantFile(vWorksite);
                    case 'guide':
                      controller.updateWorksite(
                        vWorksite.copyWith(showGuidance: !vWorksite.showGuidance),
                      );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'export', child: Text(vText.exportWorksite)),
                  PopupMenuItem(value: 'plan', child: Text(vText.exportPlan)),
                  PopupMenuItem(value: 'gltf', child: Text(vText.exportGltf)),
                  PopupMenuItem(value: 'dxf', child: Text(vText.exportDxf)),
                  PopupMenuItem(value: 'quote', child: Text(vText.quoteMenu)),
                  PopupMenuItem(value: 'homeAssistant', child: Text(vText.exportHomeAssistant)),
                  PopupMenuItem(
                    value: 'guide',
                    child: Text(vWorksite.showGuidance ? vText.guideHidden : vText.guideShown),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _create(pContext),
            icon: const Icon(Icons.add),
            label: Text(vText.newRoom),
          ),
          body: vWorksite.rooms.isEmpty
              ? EmptyState(icon: Icons.square_foot, text: vText.roomsEmpty)
              : ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  children: [
                    _Summary(worksite: vWorksite, onShopping: () => _openShopping(pContext)),
                    _HomeTiles(
                      onOpen: (pScreen) => Navigator.push(
                        pContext,
                        MaterialPageRoute<void>(builder: (_) => pScreen),
                      ),
                      controller: controller,
                      worksiteId: worksiteId,
                    ),
                    RemindersCard(
                      worksite: vWorksite,
                      onChanged: controller.updateWorksite,
                      now: today ?? DateTime.now(),
                    ),
                    PlanningCard(worksite: vWorksite),
                    GoalCard(
                      worksite: vWorksite,
                      today: today ?? DateTime.now(),
                      onChanged: controller.updateWorksite,
                    ),
                    for (final vRoom in vWorksite.rooms)
                      Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          leading: PlanThumbnail(room: vRoom, icon: Icons.square_foot),
                          title: Text(vRoom.name, style: Theme.of(pContext).textTheme.titleMedium),
                          subtitle: _RoomSubtitle(
                            text: [
                              vText.areaSummary(formatSquareMetres(floorAreaM2(vRoom))),
                              if (vWorksite.prices.isNotEmpty)
                                vText.roomCost(formatEuros(roomCost(vRoom, vWorksite.prices))),
                            ].join(' · '),
                            progress: roomProgress(vRoom),
                          ),
                          onTap: () => _open(pContext, vRoom.id),
                          trailing: IconButton(
                            tooltip: vText.delete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (await confirmDelete(pContext, vRoom.name)) {
                                await controller.deleteRoom(worksiteId, vRoom.id);
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// Tout ce qui concerne la maison entière, en tuiles plutôt que dans un long menu.
class _HomeTiles extends StatelessWidget {
  const _HomeTiles({required this.onOpen, required this.controller, required this.worksiteId});

  final ValueChanged<Widget> onOpen;
  final WorksitesController controller;
  final String worksiteId;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vTiles = <(IconData, String, Widget Function())>[
      (
        Icons.house_outlined,
        vText.houseTitle,
        () => HouseScreen(controller: controller, worksiteId: worksiteId),
      ),
      (
        Icons.square_foot,
        vText.livingAreaMenu,
        () => LivingAreaScreen(controller: controller, worksiteId: worksiteId),
      ),
      (
        Icons.menu_book_outlined,
        vText.journalMenu,
        () => JournalScreen(controller: controller, worksiteId: worksiteId),
      ),
      (
        Icons.electrical_services,
        vText.elecPlanTitle,
        () => ElecPlanScreen(controller: controller, worksiteId: worksiteId),
      ),
      (
        Icons.local_fire_department_outlined,
        vText.heatTitle,
        () => HeatingScreen(controller: controller, worksiteId: worksiteId),
      ),
      (
        Icons.water_drop_outlined,
        vText.moistureMenu,
        () => MoistureScreen(controller: controller, worksiteId: worksiteId),
      ),
      (
        Icons.timer_outlined,
        vText.timeTitle,
        () => TimeScreen(controller: controller, worksiteId: worksiteId),
      ),
      (
        Icons.roofing_outlined,
        vText.plexiMenu,
        () => PlexiScreen(controller: controller, worksiteId: worksiteId),
      ),
      (
        Icons.handshake_outlined,
        vText.loanMenu,
        () => LoansScreen(controller: controller, worksiteId: worksiteId),
      ),
      (
        Icons.checklist,
        vText.visitMenu,
        () => VisitScreen(controller: controller, worksiteId: worksiteId),
      ),
      (
        Icons.verified_outlined,
        vText.warrantyMenu,
        () => WarrantiesScreen(controller: controller, worksiteId: worksiteId),
      ),
      (
        Icons.recycling,
        vText.offcutsTitle,
        () => OffcutsScreen(controller: controller, worksiteId: worksiteId),
      ),
      (
        Icons.fact_check_outlined,
        vText.reviewMenu,
        () => ReviewScreen(controller: controller, worksiteId: worksiteId),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GridView.count(
        crossAxisCount: gridColumns(MediaQuery.sizeOf(context).width, 90, pMin: 4),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.95,
        children: [
          for (final (vIcon, vLabel, vScreen) in vTiles)
            Tooltip(
              message: vLabel,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onOpen(vScreen()),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SketchIcon(vIcon, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      vLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: vTheme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Résumé du chantier : surface, budget et accès direct aux courses.
class _Summary extends StatelessWidget {
  const _Summary({required this.worksite, required this.onShopping});

  final Worksite worksite;
  final VoidCallback onShopping;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vArea = worksite.rooms.fold(0.0, (pSum, pRoom) => pSum + floorAreaM2(pRoom));
    final vLines = shoppingList(worksite);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BigFigure(vText.totalArea(formatSquareMetres(vArea))),
            IconLine(Icons.door_front_door_outlined, vText.roomCount(worksite.rooms.length)),
            if (worksite.prices.isNotEmpty)
              IconLine(Icons.euro, vText.budgetTotal(formatEuros(budgetTotal(vLines)))),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onShopping,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(vText.shoppingTitle),
            ),
          ],
        ),
      ),
    );
  }
}

/// Surface, coût et barre d'avancement d'une pièce.
class _RoomSubtitle extends StatelessWidget {
  const _RoomSubtitle({required this.text, required this.progress});

  final String text;
  final RoomProgress progress;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text),
        if (progress.total > 0) ...[
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.ratio,
            semanticsLabel: vText.roomProgress(progress.done, progress.total),
          ),
        ],
      ],
    );
  }
}
