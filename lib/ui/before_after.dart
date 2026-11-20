
import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../storage/photo_store.dart';

/// Avant / après : les deux photos superposées, la séparation suit le doigt.
Future<void> showBeforeAfter(BuildContext pContext, String pBefore, String pAfter) =>
    Navigator.push(
      pContext,
      MaterialPageRoute<void>(
        builder: (_) => BeforeAfterScreen(before: pBefore, after: pAfter),
      ),
    );

class BeforeAfterScreen extends StatefulWidget {
  const BeforeAfterScreen({super.key, required this.before, required this.after});

  final String before;
  final String after;

  @override
  State<BeforeAfterScreen> createState() => _BeforeAfterScreenState();
}

class _BeforeAfterScreenState extends State<BeforeAfterScreen> {
  /// Part de l'image montrée « avant », depuis la gauche.
  double _split = 0.5;

  Widget _image(String pPath) => Image(image: photoProvider(pPath),
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => const ColoredBox(
      color: Colors.black12,
      child: Center(child: Icon(Icons.broken_image_outlined)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.beforeAfterTitle)),
      body: LayoutBuilder(
        builder: (pContext, pConstraints) {
          final vWidth = pConstraints.maxWidth;

          return GestureDetector(
            onHorizontalDragUpdate: (pDetails) =>
                setState(() => _split = (pDetails.localPosition.dx / vWidth).clamp(0.0, 1.0)),
            onTapDown: (pDetails) =>
                setState(() => _split = (pDetails.localPosition.dx / vWidth).clamp(0.0, 1.0)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _image(widget.after),
                ClipRect(clipper: _LeftClipper(_split), child: _image(widget.before)),
                Positioned(
                  left: vWidth * _split - 1.5,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 3, color: vTheme.colorScheme.secondary),
                ),
                Positioned(left: 12, top: 12, child: Chip(label: Text(vText.beforeLabel))),
                Positioned(right: 12, top: 12, child: Chip(label: Text(vText.afterLabel))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.share);

  final double share;

  @override
  Rect getClip(Size pSize) => Rect.fromLTWH(0, 0, pSize.width * share, pSize.height);

  @override
  bool shouldReclip(_LeftClipper pOld) => pOld.share != share;
}
