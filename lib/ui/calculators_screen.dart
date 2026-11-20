import 'package:flutter/material.dart';

import '../logic/room.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/layout.dart';
import 'deck_calculator.dart';
import 'conditions_calculator.dart';
import 'door_calculator.dart';
import 'drywall_calculator.dart';
import 'acoustics_calculator.dart';
import 'blown_insulation_calculator.dart';
import 'board_type_screen.dart';
import 'concrete_calculator.dart';
import 'condensation_calculator.dart';
import 'dropped_ceiling_calculator.dart';
import 'eaves_storage_calculator.dart';
import 'debris_calculator.dart';
import 'diy_calculator.dart';
import 'exterior_calculator.dart';
import 'fixings_calculator.dart';
import 'gutter_calculator.dart';
import 'kitchen_calculator.dart';
import '../logic/extra_items.dart';
import '../logic/worksite.dart';
import 'floor_capacity_calculator.dart';
import 'height_work_screen.dart';
import 'mezzanine_calculator.dart';
import 'attic_section_calculator.dart';
import 'large_room_heat_calculator.dart';
import 'lighting_calculator.dart';
import 'reverberation_calculator.dart';
import 'gestures_screen.dart';
import 'glue_screen.dart';
import 'glossary_view.dart';
import 'niche_shelf_calculator.dart';
import 'notebook.dart';
import 'roof_lining_calculator.dart';
import 'roof_window_calculator.dart';
import 'outdoor_weather_calculator.dart';
import 'photo_measure_screen.dart';
import 'floor_prep_calculator.dart';
import 'high_paint_calculator.dart';
import 'quote_compare_screen.dart';
import 'ready_projects_screen.dart';
import 'right_tool_screen.dart';
import 'sheet_flooring_calculator.dart';
import 'shower_calculator.dart';
import 'wallpaper_calculator.dart';
import 'frame_calculator.dart';
import 'electricity_calculator.dart';
import 'garden_calculator.dart';
import 'insulation_calculator.dart';
import 'level_screen.dart';
import 'panel_calculator.dart';
import 'pergola_calculator.dart';
import 'plumbing_calculator.dart';
import 'rent_buy_calculator.dart';
import 'roofing_calculator.dart';
import 'screed_calculator.dart';
import 'shelf_calculator.dart';
import 'shopping_target.dart';
import 'stair_calculator.dart';
import 'starter_tools_screen.dart';
import 'tiling_calculator.dart';
import 'wall_tiling_calculator.dart';
import 'wardrobe_calculator.dart';
import 'ventilation_calculator.dart';
import 'wall_shelf_calculator.dart';
import 'welding_calculator.dart';
import 'wood_finish_calculator.dart';
import 'wood_window_calculator.dart';
import 'project_cutting_screen.dart';
import 'wood_defects_screen.dart';
import 'sun_light_screen.dart';
import 'load_explained_screen.dart';
import 'energy_diagnosis_screen.dart';
import 'renovation_screen.dart';
import 'wall_lining_calculator.dart';
import 'quality_screen.dart';
import 'tool_safety_screen.dart';
import 'trades_screen.dart';
import '../state/settings_controller.dart';
import 'challenges_screen.dart';
import 'mistakes_screen.dart';
import 'noise_screen.dart';

/// Une entrée du menu des calculs : titre, explication, icône et écran.
/// Familles de la grille des calculs, pour ne montrer que celle qui sert.
enum CalcFamily { start, wood, attic, walls, comfort, outdoor, site }

typedef Calculator = ({
  String title,
  String help,
  CalcFamily family,
  IconData icon,
  WidgetBuilder builder,
});

/// Calculs hors des pièces, en grille de tuiles.
class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({
    super.key,
    this.rooms = const [],
    this.worksites = const [],
    this.onAddToShopping,
    this.settings,
  });

  /// Pièces de tous les chantiers, dont certains calculs reprennent les surfaces.
  final List<Room> rooms;

  /// Chantiers où un calcul peut ajouter son matériel aux courses ; vide : bouton caché.
  final List<Worksite> worksites;
  final Future<void> Function(String pWorksiteId, List<ExtraItem> pItems)? onAddToShopping;

  /// Réglages de l'appli, où le mode apprentissage garde son carnet ; absent dans les tests.
  final SettingsController? settings;

  static List<Calculator> entries(
    AppLocalizations pText, [
    List<Room> pRooms = const [],
    SettingsController? pSettings,
  ]) => [
    (
      title: pText.gesturesTitle,
      help: pText.gesturesHelp,
      family: CalcFamily.start,
      icon: Icons.handyman_outlined,
      builder: (_) => const GesturesScreen(),
    ),
    (
      title: pText.toolsTitle,
      help: pText.toolsHelp,
      family: CalcFamily.start,
      icon: Icons.home_repair_service_outlined,
      builder: (_) => const StarterToolsScreen(),
    ),
    (
      title: pText.tradesTitle,
      help: pText.tradesHelp,
      family: CalcFamily.start,
      icon: Icons.signpost_outlined,
      builder: (_) => const TradesScreen(),
    ),
    (
      title: pText.qualityTitle,
      help: pText.qualityHelp,
      family: CalcFamily.start,
      icon: Icons.fact_check_outlined,
      builder: (_) => const QualityScreen(),
    ),
    (
      title: pText.toolSafetyTitle,
      help: pText.toolSafetyHelp,
      family: CalcFamily.start,
      icon: Icons.health_and_safety_outlined,
      builder: (_) => const ToolSafetyScreen(),
    ),
    (
      title: pText.oopsTitle,
      help: pText.oopsHelp,
      family: CalcFamily.start,
      icon: Icons.healing_outlined,
      builder: (_) => const MistakesScreen(),
    ),
    (
      title: pText.noiseTitle,
      help: pText.noiseHelp,
      family: CalcFamily.site,
      icon: Icons.volume_up_outlined,
      builder: (_) => const NoiseScreen(),
    ),
    (
      title: pText.learnTitle,
      help: pText.learnHelp,
      family: CalcFamily.start,
      icon: Icons.school_outlined,
      builder: (_) => ChallengesScreen(settings: pSettings),
    ),
    (
      title: pText.shelfTitle,
      help: pText.shelfHelp,
      family: CalcFamily.wood,
      icon: Icons.shelves,
      builder: (_) => const ShelfCalculator(),
    ),
    (
      title: pText.wallShelfTitle,
      help: pText.wallShelfHelp,
      family: CalcFamily.wood,
      icon: Icons.shelves,
      builder: (_) => const WallShelfCalculator(),
    ),
    (
      title: pText.nicheTitle,
      help: pText.nicheHelp,
      family: CalcFamily.wood,
      icon: Icons.shelves,
      builder: (_) => const NicheShelfCalculator(),
    ),
    (
      title: pText.mezzanineTitle,
      help: pText.mezzanineHelp,
      family: CalcFamily.wood,
      icon: Icons.foundation,
      builder: (_) => const MezzanineCalculator(),
    ),
    (
      title: pText.pergolaTitle,
      help: pText.pergolaHelp,
      family: CalcFamily.outdoor,
      icon: Icons.deck_outlined,
      builder: (_) => const PergolaCalculator(),
    ),
    (
      title: pText.heightWorkTitle,
      help: pText.heightWorkHelp,
      family: CalcFamily.start,
      icon: Icons.engineering_outlined,
      builder: (_) => const HeightWorkScreen(),
    ),
    (
      title: pText.roofWindowTitle,
      help: pText.roofWindowHelp,
      family: CalcFamily.attic,
      icon: Icons.roofing,
      builder: (_) => const RoofWindowCalculator(),
    ),
    (
      title: pText.atticTitle,
      help: pText.atticHelp,
      family: CalcFamily.attic,
      icon: Icons.roofing_outlined,
      builder: (_) => const AtticSectionCalculator(),
    ),
    (
      title: pText.woodWindowTitle,
      help: pText.woodWindowHelp,
      family: CalcFamily.wood,
      icon: Icons.window_outlined,
      builder: (_) => const WoodWindowCalculator(),
    ),
    (
      title: pText.liningTitle,
      help: pText.liningHelp,
      family: CalcFamily.attic,
      icon: Icons.light_mode_outlined,
      builder: (_) => const RoofLiningCalculator(),
    ),
    (
      title: pText.finishTitle,
      help: pText.finishHelp,
      family: CalcFamily.wood,
      icon: Icons.brush_outlined,
      builder: (_) => const WoodFinishCalculator(),
    ),
    (
      title: pText.boardTitle,
      help: pText.boardHelp,
      family: CalcFamily.wood,
      icon: Icons.layers_outlined,
      builder: (_) => const BoardTypeScreen(),
    ),
    (
      title: pText.glueTitle,
      help: pText.glueHelp,
      family: CalcFamily.wood,
      icon: Icons.compress,
      builder: (_) => const GlueScreen(),
    ),
    (
      title: pText.dewTitle,
      help: pText.dewHelp,
      family: CalcFamily.comfort,
      icon: Icons.water_drop_outlined,
      builder: (_) => const CondensationCalculator(),
    ),
    (
      title: pText.ceilingTitle,
      help: pText.ceilingHelp,
      family: CalcFamily.walls,
      icon: Icons.vertical_align_bottom,
      builder: (_) => const DroppedCeilingCalculator(),
    ),
    (
      title: pText.eavesTitle,
      help: pText.eavesHelp,
      family: CalcFamily.attic,
      icon: Icons.shelves,
      builder: (_) => const EavesStorageCalculator(),
    ),
    (
      title: pText.largeHeatTitle,
      help: pText.largeHeatHelp,
      family: CalcFamily.comfort,
      icon: Icons.fireplace_outlined,
      builder: (_) => const LargeRoomHeatCalculator(),
    ),
    (
      title: pText.lightingTitle,
      help: pText.lightingHelp,
      family: CalcFamily.comfort,
      icon: Icons.light_outlined,
      builder: (_) => const LightingCalculator(),
    ),
    (
      title: pText.reverbTitle,
      help: pText.reverbHelp,
      family: CalcFamily.comfort,
      icon: Icons.graphic_eq,
      builder: (_) => const ReverberationCalculator(),
    ),
    (
      title: pText.floorCapacityTitle,
      help: pText.floorCapacityHelp,
      family: CalcFamily.wood,
      icon: Icons.scale_outlined,
      builder: (_) => const FloorCapacityCalculator(),
    ),
    (
      title: pText.wardrobeTitle,
      help: pText.wardrobeHelp,
      family: CalcFamily.wood,
      icon: Icons.door_sliding_outlined,
      builder: (_) => const WardrobeCalculator(),
    ),
    (
      title: pText.gardenTitle,
      help: pText.gardenHelp,
      family: CalcFamily.outdoor,
      icon: Icons.yard_outlined,
      builder: (_) => const GardenCalculator(),
    ),
    (
      title: pText.deckTitle,
      help: pText.deckHelp,
      family: CalcFamily.outdoor,
      icon: Icons.deck_outlined,
      builder: (_) => const DeckCalculator(),
    ),
    (
      title: pText.drywallTitle,
      help: pText.drywallHelp,
      family: CalcFamily.walls,
      icon: Icons.view_column_outlined,
      builder: (_) => const DrywallCalculator(),
    ),
    (
      title: pText.tilingTitle,
      help: pText.tilingHelp,
      family: CalcFamily.walls,
      icon: Icons.grid_on,
      builder: (_) => const TilingCalculator(),
    ),
    (
      title: pText.elecTitle,
      help: pText.elecHelp,
      family: CalcFamily.comfort,
      icon: Icons.electrical_services,
      builder: (_) => const ElectricityCalculator(),
    ),
    (
      title: pText.plumbingTitle,
      help: pText.plumbingHelp,
      family: CalcFamily.comfort,
      icon: Icons.plumbing,
      builder: (_) => const PlumbingCalculator(),
    ),
    (
      title: pText.weldingTitle,
      help: pText.weldingHelp,
      family: CalcFamily.outdoor,
      icon: Icons.local_fire_department_outlined,
      builder: (_) => const WeldingCalculator(),
    ),
    (
      title: pText.rentTitle,
      help: pText.rentHelp,
      family: CalcFamily.site,
      icon: Icons.handyman_outlined,
      builder: (_) => const RentBuyCalculator(),
    ),
    (
      title: pText.conditionsTitle,
      help: pText.conditionsHelp,
      family: CalcFamily.start,
      icon: Icons.thermostat_auto_outlined,
      builder: (_) => const ConditionsCalculator(),
    ),
    (
      title: pText.ventTitle,
      help: pText.ventHelp,
      family: CalcFamily.comfort,
      icon: Icons.air,
      builder: (_) => const VentilationCalculator(),
    ),
    (
      title: pText.stairTitle,
      help: pText.stairHelp,
      family: CalcFamily.wood,
      icon: Icons.stairs_outlined,
      builder: (_) => const StairCalculator(),
    ),
    (
      title: pText.doorTitle,
      help: pText.doorHelp,
      family: CalcFamily.wood,
      icon: Icons.door_front_door_outlined,
      builder: (_) => const DoorCalculator(),
    ),
    (
      title: pText.blownTitle,
      help: pText.blownHelp,
      family: CalcFamily.attic,
      icon: Icons.air,
      builder: (_) => const BlownInsulationCalculator(),
    ),
    (
      title: pText.gutterTitle,
      help: pText.gutterHelp,
      family: CalcFamily.outdoor,
      icon: Icons.water_outlined,
      builder: (_) => const GutterCalculator(),
    ),
    (
      title: pText.concreteTitle,
      help: pText.concreteHelp,
      family: CalcFamily.outdoor,
      icon: Icons.foundation,
      builder: (_) => const ConcreteCalculator(),
    ),
    (
      title: pText.photoMeasureTitle,
      help: pText.photoMeasureHelp,
      family: CalcFamily.start,
      icon: Icons.credit_card,
      builder: (_) => const PhotoMeasureScreen(),
    ),
    (
      title: pText.wallpaperTitle,
      help: pText.wallpaperHelp,
      family: CalcFamily.walls,
      icon: Icons.wallpaper,
      builder: (_) => WallpaperCalculator(rooms: pRooms),
    ),
    (
      title: pText.sheetTitle,
      help: pText.sheetHelp,
      family: CalcFamily.walls,
      icon: Icons.texture,
      builder: (_) => SheetFlooringCalculator(rooms: pRooms),
    ),
    (
      title: pText.outdoorTitle,
      help: pText.outdoorHelp,
      family: CalcFamily.outdoor,
      icon: Icons.wb_cloudy_outlined,
      builder: (_) => const OutdoorWeatherCalculator(),
    ),
    (
      title: pText.exteriorTitle,
      help: pText.exteriorHelp,
      family: CalcFamily.outdoor,
      icon: Icons.fence,
      builder: (_) => const ExteriorCalculator(),
    ),
    (
      title: pText.kitchenTitle,
      help: pText.kitchenHelp,
      family: CalcFamily.comfort,
      icon: Icons.kitchen_outlined,
      builder: (_) => KitchenCalculator(rooms: pRooms),
    ),
    (
      title: pText.showerTitle,
      help: pText.showerHelp,
      family: CalcFamily.comfort,
      icon: Icons.shower_outlined,
      builder: (_) => const ShowerCalculator(),
    ),
    (
      title: pText.soundTitle,
      help: pText.soundHelp,
      family: CalcFamily.walls,
      icon: Icons.volume_off_outlined,
      builder: (_) => const AcousticsCalculator(),
    ),
    (
      title: pText.diyTitle,
      help: pText.diyHelp,
      family: CalcFamily.site,
      icon: Icons.handyman_outlined,
      builder: (_) => const DiyCalculator(),
    ),
    (
      title: pText.debrisTitle,
      help: pText.debrisHelp,
      family: CalcFamily.site,
      icon: Icons.delete_sweep_outlined,
      builder: (_) => const DebrisCalculator(),
    ),
    (
      title: pText.fixingsTitle,
      help: pText.fixingsHelp,
      family: CalcFamily.start,
      icon: Icons.hardware_outlined,
      builder: (_) => const FixingsCalculator(),
    ),
    (
      title: pText.levelTitle,
      help: pText.levelHelp,
      family: CalcFamily.start,
      icon: Icons.screen_rotation_alt,
      builder: (_) => const LevelScreen(),
    ),
    (
      title: pText.insulTitle,
      help: pText.insulHelp,
      family: CalcFamily.attic,
      icon: Icons.texture,
      builder: (_) => InsulationCalculator(rooms: pRooms),
    ),
    (
      title: pText.roofingTitle,
      help: pText.roofingHelp,
      family: CalcFamily.attic,
      icon: Icons.roofing,
      builder: (_) => const RoofingCalculator(),
    ),
    (
      title: pText.wallTileTitle,
      help: pText.wallTileHelp,
      family: CalcFamily.walls,
      icon: Icons.view_module_outlined,
      builder: (_) => WallTilingCalculator(rooms: pRooms),
    ),
    (
      title: pText.screedTitle,
      help: pText.screedHelp,
      family: CalcFamily.walls,
      icon: Icons.format_paint_outlined,
      builder: (_) => ScreedCalculator(rooms: pRooms),
    ),
    (
      title: pText.panelTitle,
      help: pText.panelHelp,
      family: CalcFamily.wood,
      icon: Icons.dashboard_customize_outlined,
      builder: (_) => const PanelCalculator(),
    ),
    (
      title: pText.frameTitle,
      help: pText.frameHelp,
      family: CalcFamily.wood,
      icon: Icons.window_outlined,
      builder: (_) => const FrameCalculator(),
    ),
    // Lots 187 à 210 : projets, chantier et finitions
    (
      title: pText.readyTitle,
      help: pText.readyHelp,
      family: CalcFamily.start,
      icon: Icons.assignment_outlined,
      builder: (_) => const ReadyProjectsScreen(),
    (
      title: pText.cutPlanTitle,
      help: pText.cutPlanHelp,
      family: CalcFamily.wood,
      icon: Icons.content_cut,
      builder: (_) => const ProjectCuttingScreen(),
    ),
    (
      title: pText.defectTitle,
      help: pText.defectHelp,
      family: CalcFamily.wood,
      icon: Icons.search,
      builder: (_) => const WoodDefectsScreen(),
    ),
    (
      title: pText.sunTitle,
      help: pText.sunHelp,
      family: CalcFamily.attic,
      icon: Icons.wb_sunny_outlined,
      builder: (_) => const SunLightScreen(),
    ),
    (
      title: pText.loadTitle,
      help: pText.loadHelp,
      family: CalcFamily.wood,
      icon: Icons.fitness_center,
      builder: (_) => const LoadExplainedScreen(),
    ),
    (
      title: pText.energyTitle,
      help: pText.energyHelp,
      family: CalcFamily.comfort,
      icon: Icons.thermostat_outlined,
      builder: (_) => const EnergyDiagnosisScreen(),
    ),
    (
      title: pText.renovTitle,
      help: pText.renovHelp,
      family: CalcFamily.comfort,
      icon: Icons.stairs_outlined,
      builder: (_) => const RenovationScreen(),
    ),
    (
      title: pText.iwiTitle,
      help: pText.iwiHelp,
      family: CalcFamily.walls,
      icon: Icons.layers_outlined,
      builder: (_) => WallLiningCalculator(rooms: pRooms),
    ),
    (
      title: pText.rightToolTitle,
      help: pText.rightToolHelp,
      family: CalcFamily.site,
      icon: Icons.construction,
      builder: (_) => const RightToolScreen(),
    ),
    (
      title: pText.quoteCompareTitle,
      help: pText.quoteCompareHelp,
      family: CalcFamily.site,
      icon: Icons.request_quote_outlined,
      builder: (_) => const QuoteCompareScreen(),
    ),
    (
      title: pText.floorPrepTitle,
      help: pText.floorPrepHelp,
      family: CalcFamily.walls,
      icon: Icons.layers_outlined,
      builder: (_) => const FloorPrepCalculator(),
    ),
    (
      title: pText.highPaintTitle,
      help: pText.highPaintHelp,
      family: CalcFamily.walls,
      icon: Icons.format_paint_outlined,
      builder: (_) => const HighPaintCalculator(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(vText.calculatorsTitle),
        actions: [
          IconButton(
            tooltip: vText.glossaryTitle,
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const GlossaryScreen()),
            ),
          ),
        ],
      ),
      body: _CalculatorGrid(
        entries: entries(vText, rooms, settings),
        open: (pContext, pEntry) => Navigator.push(
          pContext,
          MaterialPageRoute<void>(
            builder: (pRoute) => onAddToShopping == null
                ? pEntry.builder(pRoute)
                : ShoppingTarget(
                    worksites: worksites,
                    add: onAddToShopping!,
                    child: pEntry.builder(pRoute),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Grille des calculs, avec en haut une puce par famille pour n'en garder qu'une.
class _CalculatorGrid extends StatefulWidget {
  const _CalculatorGrid({required this.entries, required this.open});

  final List<Calculator> entries;
  final void Function(BuildContext pContext, Calculator pEntry) open;

  @override
  State<_CalculatorGrid> createState() => _CalculatorGridState();
}

class _CalculatorGridState extends State<_CalculatorGrid> {
  CalcFamily? _family;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vShown = [
      for (final vEntry in widget.entries)
        if (_family == null || vEntry.family == _family) vEntry,
    ];

    return Column(
      children: [
        // Huit puces seulement : une rangée qui défile, toutes construites d'un coup
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              for (final vFamily in [null, ...CalcFamily.values])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(calcFamilyName(vText, vFamily)),
                    selected: _family == vFamily,
                    onSelected: (_) => setState(() => _family = vFamily),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: gridColumns(MediaQuery.sizeOf(context).width, 300, pMin: 2),
            padding: const EdgeInsets.all(12),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 0.85,
            children: [
              for (final vEntry in vShown)
                Card(
                  margin: const EdgeInsets.all(4),
                  child: InkWell(
                    onTap: () => widget.open(context, vEntry),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SketchIcon(vEntry.icon, size: 26),
                          const Spacer(),
                          Text(
                            vEntry.title,
                            style: vTheme.textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vEntry.help,
                            style: vTheme.textTheme.bodySmall,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Nom d'une famille de calculs ; null : toutes.
String calcFamilyName(AppLocalizations pText, CalcFamily? pFamily) => switch (pFamily) {
  null => pText.familyAll,
  CalcFamily.start => pText.familyStart,
  CalcFamily.wood => pText.familyWood,
  CalcFamily.attic => pText.familyAttic,
  CalcFamily.walls => pText.familyWalls,
  CalcFamily.comfort => pText.familyComfort,
  CalcFamily.outdoor => pText.familyOutdoor,
  CalcFamily.site => pText.familySite,
};
