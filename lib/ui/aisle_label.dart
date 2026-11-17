import '../l10n/gen/app_localizations.dart';
import '../logic/aisles.dart';

String aisleLabel(AppLocalizations pText, Aisle pAisle) => switch (pAisle) {
  Aisle.timber => pText.aisleTimber,
  Aisle.flooring => pText.aisleFlooring,
  Aisle.paint => pText.aislePaint,
  Aisle.adhesives => pText.aisleAdhesives,
  Aisle.building => pText.aisleBuilding,
  Aisle.hardware => pText.aisleHardware,
  Aisle.other => pText.aisleOther,
};
