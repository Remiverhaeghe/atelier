/// Où vivent les photos : fichiers sur le téléphone, base du navigateur pour la version web.
///
/// Les deux versions offrent la même chose : garder une photo, la relire tout de suite (les PDF
/// la lisent sans attendre) et la donner à afficher.
library;

export 'photo_store_io.dart' if (dart.library.js_interop) 'photo_store_web.dart';
