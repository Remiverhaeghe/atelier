/// Où vivent les données : fichiers sur le téléphone, stockage du navigateur pour la version web.
///
/// Le bon fichier est choisi à la compilation : la version web ne peut pas lire de fichier, et
/// la version Android ne connaît pas le stockage du navigateur.
library;

export 'platform_stores_io.dart' if (dart.library.js_interop) 'platform_stores_web.dart';
