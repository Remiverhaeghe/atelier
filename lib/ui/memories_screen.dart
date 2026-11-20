import 'dart:async';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/memories.dart';
import '../logic/worksite.dart';
import '../storage/photo_store.dart';
import 'memories_pdf.dart';
import 'notebook.dart';
import 'theme.dart';

/// Photo du téléphone, ou un cadre vide si elle a disparu.
Widget memoryPhoto(String pPath) => Image(
  image: photoProvider(pPath),
  fit: BoxFit.cover,
  errorBuilder: (_, _, _) => const ColoredBox(
    color: Colors.black12,
    child: Center(child: Icon(Icons.broken_image_outlined)),
  ),
);

/// Souvenirs du chantier : l'avant et l'après de chaque entrée du carnet, en diaporama sur
/// papier quadrillé, ou en PDF façon carnet.
class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key, required this.worksite, this.photo = memoryPhoto});

  final Worksite worksite;

  /// Affichage d'une photo ; remplaçable dans les tests.
  final Widget Function(String pPath) photo;

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final _pages = PageController();
  var _index = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _toggle(int pCount) {
    setState(() {
      if (_timer != null) {
        _timer!.cancel();
        _timer = null;
      } else {
        _timer = Timer.periodic(slideDuration, (_) {
          final vNext = nextSlide(_index, pCount);
          _pages.jumpToPage(vNext);
        });
      }
    });
  }

  String _roomName(String pRoomId) =>
      widget.worksite.rooms.where((pRoom) => pRoom.id == pRoomId).firstOrNull?.name ?? '';

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vJournal = widget.worksite.journal;
    final vSlides = memorySlides(vJournal);
    final vSpan = memorySpan(vJournal);
    final vHand = vTheme.textTheme.headlineSmall!.copyWith(fontFamily: handFont);

    return Scaffold(
      appBar: AppBar(
        title: Text(vText.memoriesTitle),
        actions: [
          if (vSlides.isNotEmpty) ...[
            IconButton(
              tooltip: _timer == null ? vText.memoriesPlay : vText.memoriesPause,
              icon: Icon(_timer == null ? Icons.slideshow : Icons.stop_circle_outlined),
              onPressed: () => _toggle(vSlides.length),
            ),
            IconButton(
              tooltip: vText.memoriesPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => Printing.layoutPdf(
                name: vText.memoriesTitle,
                onLayout: (_) => buildMemoriesPdf(vText, widget.worksite),
              ),
            ),
          ],
        ],
      ),
      body: NotebookPaper(
        child: vSlides.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(vText.memoriesEmpty, style: vHand),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (vSpan != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text(
                        '${widget.worksite.name} · ${vText.memoriesSpan(vSpan.first, vSpan.last)}',
                        style: vTheme.textTheme.titleMedium,
                      ),
                    ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: vSlides.length,
                      onPageChanged: (pIndex) => setState(() => _index = pIndex),
                      itemBuilder: (_, pIndex) {
                        final vSlide = vSlides[pIndex];

                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vSlide.before ? vText.memoriesBefore : vText.memoriesAfter,
                                style: vHand.copyWith(color: vTheme.colorScheme.primary),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: SizedBox.expand(child: widget.photo(vSlide.path)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(vSlide.entry.title, style: vHand),
                              Text(
                                '${_roomName(vSlide.entry.roomId)} · ${vSlide.entry.day}',
                                style: vTheme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${_index + 1} / ${vSlides.length}',
                      textAlign: TextAlign.center,
                      style: vTheme.textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
