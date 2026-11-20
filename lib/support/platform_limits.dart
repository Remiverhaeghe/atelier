import 'package:flutter/foundation.dart';

/// Vrai dans la version web : pas de Bluetooth ni de notification programmée dans Safari.
///
/// Variable plutôt que constante, pour que les tests vérifient aussi ce que voit l'iPhone.
bool aOnWeb = kIsWeb;
