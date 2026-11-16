import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/goals.dart';
import '../logic/loans.dart';
import '../state/worksites_controller.dart';
import 'theme.dart';

/// Outils prêtés : à qui, depuis combien de jours, rendus d'un appui.
class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key, required this.controller, required this.worksiteId, this.today});

  final WorksitesController controller;
  final String worksiteId;

  /// Jour de référence ; aujourd'hui si absent, fixé dans les tests.
  final DateTime? today;

  Future<void> _add(BuildContext pContext, DateTime pToday) async {
    final vText = AppLocalizations.of(pContext);
    final vTool = TextEditingController();
    final vPerson = TextEditingController();
    final vOk = await showDialog<bool>(
      context: pContext,
      builder: (pDialog) => AlertDialog(
        title: Text(vText.loanAdd),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: vTool,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: vText.loanTool),
            ),
            TextField(
              controller: vPerson,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: vText.loanPerson),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(pDialog), child: Text(vText.cancel)),
          FilledButton(onPressed: () => Navigator.pop(pDialog, true), child: Text(vText.save)),
        ],
      ),
    );
    final vWorksite = controller.worksite(worksiteId);
    if (vOk == true && vWorksite != null && vTool.text.trim().isNotEmpty) {
      final vLoan = Loan(
        id: controller.newId(),
        tool: vTool.text.trim(),
        person: vPerson.text.trim(),
        since: goalDate(pToday),
      );
      await controller.updateWorksite(vWorksite.copyWith(loans: [...vWorksite.loans, vLoan]));
    }
    vTool.dispose();
    vPerson.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vToday = today ?? DateTime.now();

    return ListenableBuilder(
      listenable: controller,
      builder: (pContext, _) {
        final vWorksite = controller.worksite(worksiteId);
        final vLoans = sortedLoans(vWorksite?.loans ?? const []);

        return Scaffold(
          appBar: AppBar(title: Text(vText.loanTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _add(pContext, vToday),
            icon: const Icon(Icons.add),
            label: Text(vText.loanAdd),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
            children: [
              if (vLoans.isEmpty)
                Padding(padding: const EdgeInsets.all(8), child: Text(vText.loanEmpty)),
              for (final vLoan in vLoans)
                Card(
                  child: ListTile(
                    leading: Icon(
                      loanOverdue(vLoan, vToday) ? AtelierIcons.warning : Icons.handshake_outlined,
                      color: loanOverdue(vLoan, vToday) ? vTheme.colorScheme.error : null,
                    ),
                    title: Text(vLoan.tool),
                    subtitle: Text(vText.loanSince(vLoan.person, loanDays(vLoan, vToday))),
                    trailing: TextButton(
                      onPressed: () => controller.updateWorksite(
                        vWorksite!.copyWith(
                          loans: [
                            for (final vOther in vWorksite.loans)
                              if (vOther.id != vLoan.id) vOther,
                          ],
                        ),
                      ),
                      child: Text(vText.loanReturned),
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
