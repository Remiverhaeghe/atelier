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
import 'concrete_calculator.dart';
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
import 'niche_shelf_calculator.dart';
import 'roof_window_calculator.dart';
import 'outdoor_weather_calculator.dart';
import 'photo_measure_screen.dart';
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
import 'tiling_calculator.dart';
import 'wall_tiling_calculator.dart';
import 'wardrobe_calculator.dart';
import 'ventilation_calculator.dart';
import 'wall_shelf_calculator.dart';
import 'welding_calculator.dart';

/// Une entrée du menu des calculs : titre, explication, icône et écran.
typedef Calculator = ({String title, String help, IconData icon, WidgetBuilder builder});

/// Calculs hors des pièces, en grille de tuiles.
class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({
    super.key,
    this.rooms = const [],
    this.worksites = const [],
    this.onAddToShopping,
  });

  /// Pièces de tous les chantiers, dont certains calculs reprennent les surfaces.
  final List<Room> rooms;

  /// Chantiers où un calcul peut ajouter son matériel aux courses ; vide : bouton caché.
  final List<Worksite> worksites;
  final Future<void> Function(String pWorksiteId, List<ExtraItem> pItems)? onAddToShopping;

  static List<Calculator> entries(AppLocalizations pText, [List<Room> pRooms = const []]) => [
    (
      title: pText.shelfTitle,
      help: pText.shelfHelp,
      icon: Icons.shelves,
      builder: (_) => const ShelfCalculator(),
    ),
    (
      title: pText.wallShelfTitle,
      help: pText.wallShelfHelp,
      icon: Icons.shelves,
      builder: (_) => const WallShelfCalculator(),
    ),
    (
      title: pText.nicheTitle,
      help: pText.nicheHelp,
      icon: Icons.shelves,
      builder: (_) => const NicheShelfCalculator(),
    ),
    (
      title: pText.mezzanineTitle,
      help: pText.mezzanineHelp,
      icon: Icons.foundation,
      builder: (_) => const MezzanineCalculator(),
    ),
    (
      title: pText.pergolaTitle,
      help: pText.pergolaHelp,
      icon: Icons.deck_outlined,
      builder: (_) => const PergolaCalculator(),
    ),
    (
      title: pText.heightWorkTitle,
      help: pText.heightWorkHelp,
      icon: Icons.engineering_outlined,
      builder: (_) => const HeightWorkScreen(),
    ),
    (
      title: pText.roofWindowTitle,
      help: pText.roofWindowHelp,
      icon: Icons.roofing,
      builder: (_) => const RoofWindowCalculator(),
    ),
    (
      title: pText.floorCapacityTitle,
      help: pText.floorCapacityHelp,
      icon: Icons.scale_outlined,
      builder: (_) => const FloorCapacityCalculator(),
    ),
    (
      title: pText.wardrobeTitle,
      help: pText.wardrobeHelp,
      icon: Icons.door_sliding_outlined,
      builder: (_) => const WardrobeCalculator(),
    ),
    (
      title: pText.gardenTitle,
      help: pText.gardenHelp,
      icon: Icons.yard_outlined,
      builder: (_) => const GardenCalculator(),
    ),
    (
      title: pText.deckTitle,
      help: pText.deckHelp,
      icon: Icons.deck_outlined,
      builder: (_) => const DeckCalculator(),
    ),
    (
      title: pText.drywallTitle,
      help: pText.drywallHelp,
      icon: Icons.view_column_outlined,
      builder: (_) => const DrywallCalculator(),
    ),
    (
      title: pText.tilingTitle,
      help: pText.tilingHelp,
      icon: Icons.grid_on,
      builder: (_) => const TilingCalculator(),
    ),
    (
      title: pText.elecTitle,
      help: pText.elecHelp,
      icon: Icons.electrical_services,
      builder: (_) => const ElectricityCalculator(),
    ),
    (
      title: pText.plumbingTitle,
      help: pText.plumbingHelp,
      icon: Icons.plumbing,
      builder: (_) => const PlumbingCalculator(),
    ),
    (
      title: pText.weldingTitle,
      help: pText.weldingHelp,
      icon: Icons.local_fire_department_outlined,
      builder: (_) => const WeldingCalculator(),
    ),
    (
      title: pText.rentTitle,
      help: pText.rentHelp,
      icon: Icons.handyman_outlined,
      builder: (_) => const RentBuyCalculator(),
    ),
    (
      title: pText.conditionsTitle,
      help: pText.conditionsHelp,
      icon: Icons.thermostat_auto_outlined,
      builder: (_) => const ConditionsCalculator(),
    ),
    (
      title: pText.ventTitle,
      help: pText.ventHelp,
      icon: Icons.air,
      builder: (_) => const VentilationCalculator(),
    ),
    (
      title: pText.stairTitle,
      help: pText.stairHelp,
      icon: Icons.stairs_outlined,
      builder: (_) => const StairCalculator(),
    ),
    (
      title: pText.doorTitle,
      help: pText.doorHelp,
      icon: Icons.door_front_door_outlined,
      builder: (_) => const DoorCalculator(),
    ),
    (
      title: pText.blownTitle,
      help: pText.blownHelp,
      icon: Icons.air,
      builder: (_) => const BlownInsulationCalculator(),
    ),
    (
      title: pText.gutterTitle,
      help: pText.gutterHelp,
      icon: Icons.water_outlined,
      builder: (_) => const GutterCalculator(),
    ),
    (
      title: pText.concreteTitle,
      help: pText.concreteHelp,
      icon: Icons.foundation,
      builder: (_) => const ConcreteCalculator(),
    ),
    (
      title: pText.photoMeasureTitle,
      help: pText.photoMeasureHelp,
      icon: Icons.credit_card,
      builder: (_) => const PhotoMeasureScreen(),
    ),
    (
      title: pText.wallpaperTitle,
      help: pText.wallpaperHelp,
      icon: Icons.wallpaper,
      builder: (_) => WallpaperCalculator(rooms: pRooms),
    ),
    (
      title: pText.sheetTitle,
      help: pText.sheetHelp,
      icon: Icons.texture,
      builder: (_) => SheetFlooringCalculator(rooms: pRooms),
    ),
    (
      title: pText.outdoorTitle,
      help: pText.outdoorHelp,
      icon: Icons.wb_cloudy_outlined,
      builder: (_) => const OutdoorWeatherCalculator(),
    ),
    (
      title: pText.exteriorTitle,
      help: pText.exteriorHelp,
      icon: Icons.fence,
      builder: (_) => const ExteriorCalculator(),
    ),
    (
      title: pText.kitchenTitle,
      help: pText.kitchenHelp,
      icon: Icons.kitchen_outlined,
      builder: (_) => const KitchenCalculator(),
    ),
    (
      title: pText.showerTitle,
      help: pText.showerHelp,
      icon: Icons.shower_outlined,
      builder: (_) => const ShowerCalculator(),
    ),
    (
      title: pText.soundTitle,
      help: pText.soundHelp,
      icon: Icons.volume_off_outlined,
      builder: (_) => const AcousticsCalculator(),
    ),
    (
      title: pText.diyTitle,
      help: pText.diyHelp,
      icon: Icons.handyman_outlined,
      builder: (_) => const DiyCalculator(),
    ),
    (
      title: pText.debrisTitle,
      help: pText.debrisHelp,
      icon: Icons.delete_sweep_outlined,
      builder: (_) => const DebrisCalculator(),
    ),
    (
      title: pText.fixingsTitle,
      help: pText.fixingsHelp,
      icon: Icons.hardware_outlined,
      builder: (_) => const FixingsCalculator(),
    ),
    (
      title: pText.levelTitle,
      help: pText.levelHelp,
      icon: Icons.screen_rotation_alt,
      builder: (_) => const LevelScreen(),
    ),
    (
      title: pText.insulTitle,
      help: pText.insulHelp,
      icon: Icons.texture,
      builder: (_) => InsulationCalculator(rooms: pRooms),
    ),
    (
      title: pText.roofingTitle,
      help: pText.roofingHelp,
      icon: Icons.roofing,
      builder: (_) => const RoofingCalculator(),
    ),
    (
      title: pText.wallTileTitle,
      help: pText.wallTileHelp,
      icon: Icons.view_module_outlined,
      builder: (_) => WallTilingCalculator(rooms: pRooms),
    ),
    (
      title: pText.screedTitle,
      help: pText.screedHelp,
      icon: Icons.format_paint_outlined,
      builder: (_) => ScreedCalculator(rooms: pRooms),
    ),
    (
      title: pText.panelTitle,
      help: pText.panelHelp,
      icon: Icons.dashboard_customize_outlined,
      builder: (_) => const PanelCalculator(),
    ),
    (
      title: pText.frameTitle,
      help: pText.frameHelp,
      icon: Icons.window_outlined,
      builder: (_) => const FrameCalculator(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.calculatorsTitle)),
      body: GridView.count(
        crossAxisCount: gridColumns(MediaQuery.sizeOf(context).width, 300, pMin: 2),
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.85,
        children: [
          for (final vEntry in entries(vText, rooms))
            Card(
              margin: const EdgeInsets.all(4),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (pContext) => onAddToShopping == null
                        ? vEntry.builder(pContext)
                        : ShoppingTarget(
                            worksites: worksites,
                            add: onAddToShopping!,
                            child: vEntry.builder(pContext),
                          ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: vTheme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          vEntry.icon,
                          size: 30,
                          color: vTheme.colorScheme.onPrimaryContainer,
                        ),
                      ),
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
    );
  }
}
