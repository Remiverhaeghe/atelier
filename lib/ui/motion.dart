import 'package:flutter/widgets.dart';

/// Durée d'une animation, ramenée à zéro quand le téléphone demande de réduire les animations.
Duration motionDuration(BuildContext pContext, int pMilliseconds) =>
    MediaQuery.disableAnimationsOf(pContext)
    ? Duration.zero
    : Duration(milliseconds: pMilliseconds);
