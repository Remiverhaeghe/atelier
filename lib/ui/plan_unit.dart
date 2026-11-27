import 'package:flutter/widgets.dart';

import '../logic/units.dart';

/// Unité des cotes du plan choisie dans les réglages, lue par tous les plans de l'appli.
class PlanUnit extends InheritedWidget {
  const PlanUnit({super.key, required this.unit, required super.child});

  final FieldUnit unit;

  /// Le centimètre quand aucun réglage n'est au-dessus (tests, écrans seuls).
  static FieldUnit of(BuildContext pContext) =>
      pContext.dependOnInheritedWidgetOfExactType<PlanUnit>()?.unit ?? FieldUnit.cm;

  @override
  bool updateShouldNotify(PlanUnit pOld) => pOld.unit != unit;
}
