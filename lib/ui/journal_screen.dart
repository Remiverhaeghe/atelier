import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/house_book.dart';
import '../logic/journal.dart';
import '../logic/room.dart';
import '../logic/time_tracking.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import '../state/worksites_controller.dart';
import '../storage/photo_store.dart';
import 'before_after.dart';
import 'house_book_pdf.dart';
import 'journal_pdf.dart';
import 'memories_screen.dart';
import 'photos.dart';
import 'shopping_texts.dart';
import 'theme.dart';

/// Carnet en texte, à partager avec un acheteur ou à garder avec les papiers de la maison.
String journalText(AppLocalizations pText, Worksite pWorksite) {
  final vBuffer = StringBuffer('${pText.journalTitle} : ${pWorksite.name}\n');
  for (final vRoom in pWorksite.rooms) {
    final vEntries = journalOf(pWorksite.journal, pRoomId: vRoom.id);
    if (vEntries.isEmpty) {
      continue;
    }
    vBuffer.write('\n${vRoom.name}\n');
    for (final vEntry in vEntries) {
      vBuffer.write('- ${vEntry.day} : ${vEntry.title}');
      if (vEntry.product.isNotEmpty) {
        vBuffer.write(', ${vEntry.product}');
      }
      if (vEntry.reference.isNotEmpty) {
        vBuffer.write(' (${vEntry.reference})');
      }
      if (vEntry.cost != null) {
        vBuffer.write(', ${formatEuros(vEntry.cost!)} €');
      }
      vBuffer.write('\n');
    }
  }

  return vBuffer.toString();
}

/// Carnet de la maison : ce qui a été fait, où, avec quoi, photos et factures.
class JournalScreen extends StatefulWidget {
  const JournalScreen({
    super.key,
    required this.controller,
    required this.worksiteId,
    this.photos,
    this.now = DateTime.now,
  });

  final WorksitesController controller;
  final String worksiteId;

  /// Prise de photo ; remplaçable dans les tests.
  final PhotoTaker? photos;
  final DateTime Function() now;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String? _roomId;
  String _search = '';

  WorksitesController get _controller => widget.controller;

  void _replace(Worksite pWorksite, JournalEntry pEntry) => _controller.updateWorksite(
    pWorksite.copyWith(
      journal: [for (final vEntry in pWorksite.journal) vEntry.id == pEntry.id ? pEntry : vEntry],
    ),
  );

  Future<void> _add(Worksite pWorksite) async {
    final vEntry = await showDialog<JournalEntry>(
      context: context,
      builder: (_) => _EntryDialog(
        rooms: pWorksite.rooms,
        roomId: _roomId ?? pWorksite.rooms.first.id,
        day: dayOf(widget.now()),
      ),
    );
    if (vEntry != null) {
      _controller.updateWorksite(pWorksite.copyWith(journal: [...pWorksite.journal, vEntry]));
    }
  }

  Future<void> _attach(Worksite pWorksite, JournalEntry pEntry, String pWhat) async {
    final vPath = await (widget.photos ?? takePhoto)('${pEntry.id}-$pWhat');
    if (vPath != null) {
      _replace(pWorksite, switch (pWhat) {
        'facture' => pEntry.copyWith(invoicePath: vPath),
        'avant' => pEntry.copyWith(beforePath: vPath),
        _ => pEntry.copyWith(photoPath: vPath),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (pContext, _) {
        final vWorksite = _controller.worksite(widget.worksiteId);
        if (vWorksite == null) {
          return const Scaffold();
        }
        final vEntries = journalOf(vWorksite.journal, pRoomId: _roomId);
        final vFound = lastReference(vWorksite.journal, _search);
        String vRoomName(String pId) =>
            vWorksite.rooms.where((pRoom) => pRoom.id == pId).firstOrNull?.name ?? '';

        return Scaffold(
          appBar: AppBar(
            title: Text(vText.journalTitle),
            actions: [
              IconButton(
                tooltip: vText.memoriesTitle,
                icon: const Icon(Icons.photo_album_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => MemoriesScreen(worksite: vWorksite)),
                ),
              ),
              IconButton(
                tooltip: vText.bookTitle,
                icon: const Icon(Icons.home_work_outlined),
                onPressed: houseBook(vWorksite).isEmpty
                    ? null
                    : () => Printing.layoutPdf(
                        name: vText.bookTitle,
                        onLayout: (_) => buildHouseBookPdf(vText, vWorksite),
                      ),
              ),
              IconButton(
                tooltip: vText.journalPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: vWorksite.journal.isEmpty
                    ? null
                    : () => Printing.layoutPdf(
                        name: vText.journalTitle,
                        onLayout: (_) => buildJournalPdf(vText, vWorksite),
                      ),
              ),
              IconButton(
                tooltip: vText.shareList,
                icon: const Icon(Icons.share),
                onPressed: vWorksite.journal.isEmpty
                    ? null
                    : () => SharePlus.instance.share(
                        ShareParams(text: journalText(vText, vWorksite)),
                      ),
              ),
            ],
          ),
          floatingActionButton: vWorksite.rooms.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _add(vWorksite),
                  icon: const Icon(Icons.edit_note),
                  label: Text(vText.journalAdd),
                ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: vText.journalSearch,
                ),
                onChanged: (pText) => setState(() => _search = pText),
              ),
              if (vFound != null)
                Card(
                  color: vTheme.colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.qr_code_2),
                    title: Text(vFound.reference),
                    subtitle: Text(
                      vText.journalFound(vFound.product, vRoomName(vFound.roomId), vFound.day),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(vText.journalAll),
                    selected: _roomId == null,
                    onSelected: (_) => setState(() => _roomId = null),
                  ),
                  for (final vRoom in vWorksite.rooms)
                    ChoiceChip(
                      label: Text(vRoom.name),
                      selected: _roomId == vRoom.id,
                      onSelected: (_) => setState(() => _roomId = vRoom.id),
                    ),
                ],
              ),
              if (vEntries.isEmpty)
                Padding(padding: const EdgeInsets.all(8), child: Text(vText.journalEmpty))
              else
                IconLine(
                  Icons.euro,
                  vText.journalCost(formatEuros(journalCost(vWorksite.journal, pRoomId: _roomId))),
                ),
              for (final vEntry in vEntries)
                Card(
                  child: ListTile(
                    title: Text(vEntry.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${vEntry.day}, ${vRoomName(vEntry.roomId)}'),
                        if (vEntry.product.isNotEmpty || vEntry.reference.isNotEmpty)
                          Text(
                            [
                              vEntry.product,
                              vEntry.reference,
                            ].where((pPart) => pPart.isNotEmpty).join(', '),
                          ),
                        if (vEntry.note.isNotEmpty) Text(vEntry.note),
                        if (vEntry.cost != null) Text('${formatEuros(vEntry.cost!)} €'),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (hasBeforeAfter(vEntry))
                              ActionChip(
                                avatar: const Icon(Icons.compare, size: 18),
                                label: Text(vText.beforeAfterTitle),
                                onPressed: () =>
                                    showBeforeAfter(context, vEntry.beforePath!, vEntry.photoPath!),
                              ),
                            for (final vPath in [vEntry.photoPath, vEntry.invoicePath].nonNulls)
                              GestureDetector(
                                onTap: () => showPhoto(context, vPath),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image(
                                    image: photoProvider(vPath),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (pAction) {
                        switch (pAction) {
                          case 'photo':
                            _attach(vWorksite, vEntry, 'apres');
                          case 'invoice':
                            _attach(vWorksite, vEntry, 'facture');
                          case 'before':
                            _attach(vWorksite, vEntry, 'avant');
                          case 'delete':
                            _controller.updateWorksite(
                              vWorksite.copyWith(
                                journal: [
                                  for (final vOther in vWorksite.journal)
                                    if (vOther.id != vEntry.id) vOther,
                                ],
                              ),
                            );
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'photo', child: Text(vText.takePhoto)),
                        PopupMenuItem(value: 'before', child: Text(vText.beforePhoto)),
                        PopupMenuItem(value: 'invoice', child: Text(vText.journalInvoice)),
                        PopupMenuItem(value: 'delete', child: Text(vText.delete)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({required this.rooms, required this.roomId, required this.day});

  final List<Room> rooms;
  final String roomId;
  final String day;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  late String _roomId = widget.roomId;
  late final _day = TextEditingController(text: widget.day);
  final _title = TextEditingController();
  final _product = TextEditingController();
  final _reference = TextEditingController();
  final _cost = TextEditingController();
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final vField in [_day, _title, _product, _reference, _cost, _note]) {
      vField.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final vText = AppLocalizations.of(context);
    final vDay = _day.text.trim();
    if (_title.text.trim().isEmpty || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(vDay)) {
      setState(() => _error = vText.journalInvalid);
      return;
    }
    Navigator.pop(
      context,
      JournalEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        roomId: _roomId,
        day: vDay,
        title: _title.text.trim(),
        product: _product.text.trim(),
        reference: _reference.text.trim(),
        note: _note.text.trim(),
        cost: _cost.text.trim().isEmpty ? null : parseDecimal(_cost.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(vText.journalAdd),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _roomId,
              items: [
                for (final vRoom in widget.rooms)
                  DropdownMenuItem(value: vRoom.id, child: Text(vRoom.name)),
              ],
              onChanged: (pId) => setState(() => _roomId = pId!),
            ),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(labelText: vText.journalWhat, errorText: _error),
            ),
            TextField(
              controller: _day,
              decoration: InputDecoration(labelText: vText.journalDay),
            ),
            TextField(
              controller: _product,
              decoration: InputDecoration(labelText: vText.journalProduct),
            ),
            TextField(
              controller: _reference,
              decoration: InputDecoration(labelText: vText.journalReference),
            ),
            TextField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: vText.journalCostField, suffixText: '€'),
            ),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: vText.journalNote),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(onPressed: _submit, child: Text(vText.save)),
      ],
    );
  }
}
