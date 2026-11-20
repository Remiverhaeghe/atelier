import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/goals.dart';
import '../logic/loans.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import '../state/worksites_controller.dart';
import 'reminder_alarm.dart';
import 'theme.dart';

/// Outils prêtés (à qui, depuis combien de jours) et outils loués (retour, caution, coût),
/// rendus d'un appui.
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
  }

  /// Outil loué : retour prévu, caution et prix par jour, et rappel la veille du retour.
  Future<void> _rent(BuildContext pContext, DateTime pToday) async {
    final vText = AppLocalizations.of(pContext);
    final vTool = TextEditingController();
    final vShop = TextEditingController();
    final vDays = TextEditingController(text: '1');
    final vDeposit = TextEditingController();
    final vRate = TextEditingController();
    TextField vField(TextEditingController pController, String pLabel, {bool pNumber = false}) =>
        TextField(
          controller: pController,
          keyboardType: pNumber ? const TextInputType.numberWithOptions(decimal: true) : null,
          textCapitalization: pNumber ? TextCapitalization.none : TextCapitalization.sentences,
          decoration: InputDecoration(labelText: pLabel),
        );
    final vOk = await showDialog<bool>(
      context: pContext,
      builder: (pDialog) => AlertDialog(
        title: Text(vText.rentalAdd),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              vField(vTool, vText.loanTool),
              vField(vShop, vText.rentalShop),
              vField(vDays, vText.rentalDaysField, pNumber: true),
              vField(vDeposit, vText.rentalDeposit, pNumber: true),
              vField(vRate, vText.rentalDayRate, pNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(pDialog), child: Text(vText.cancel)),
          FilledButton(onPressed: () => Navigator.pop(pDialog, true), child: Text(vText.save)),
        ],
      ),
    );
    final vWorksite = controller.worksite(worksiteId);
    if (vOk != true || vWorksite == null || vTool.text.trim().isEmpty) {
      return;
    }
    final vDayCount = parseWhole(vDays.text) ?? 1;
    final vLoan = Loan(
      id: controller.newId(),
      tool: vTool.text.trim(),
      person: vShop.text.trim(),
      since: goalDate(pToday),
      returnBy: goalDate(pToday.add(Duration(days: vDayCount < 1 ? 1 : vDayCount))),
      depositEuros: parseDecimal(vDeposit.text) ?? 0,
      dayEuros: parseDecimal(vRate.text) ?? 0,
    );
    final vReminder = rentalReminder(vLoan)!;
    await controller.updateWorksite(
      vWorksite.copyWith(
        loans: [...vWorksite.loans, vLoan],
        reminders: [...vWorksite.reminders, vReminder],
      ),
    );
    await aReminderAlarm.schedule(
      vReminder,
      vText.reminderNotifyTitle,
      vText.rentalNotify(vLoan.tool),
    );
    if (pContext.mounted) {
      ScaffoldMessenger.of(pContext).showSnackBar(SnackBar(content: Text(vText.rentalReminderSet)));
    }
  }

  /// Outil rendu : il sort de la liste, et le rappel de retour avec lui.
  Future<void> _returned(Worksite pWorksite, Loan pLoan) async {
    final vReminderId = rentalReminderId(pLoan);
    for (final vReminder in pWorksite.reminders.where((pItem) => pItem.id == vReminderId)) {
      await aReminderAlarm.cancel(vReminder);
    }
    await controller.updateWorksite(
      pWorksite.copyWith(
        loans: [
          for (final vOther in pWorksite.loans)
            if (vOther.id != pLoan.id) vOther,
        ],
        reminders: [
          for (final vReminder in pWorksite.reminders)
            if (vReminder.id != vReminderId) vReminder,
        ],
      ),
    );
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
        final vAll = sortedLoans(vWorksite?.loans ?? const []);
        final vLoans = vAll.where((pLoan) => !pLoan.rented).toList();
        final vRentals = vAll.where((pLoan) => pLoan.rented).toList();

        Widget vTile(Loan pLoan, String pSubtitle, IconData pIcon) {
          final vLate = loanOverdue(pLoan, vToday);

          return Card(
            child: ListTile(
              leading: Icon(
                vLate ? AtelierIcons.warning : pIcon,
                color: vLate ? vTheme.colorScheme.error : null,
              ),
              title: Text(pLoan.tool),
              subtitle: Text(pSubtitle),
              trailing: TextButton(
                onPressed: () => _returned(vWorksite!, pLoan),
                child: Text(vText.loanReturned),
              ),
            ),
          );
        }

        String vRentalText(Loan pLoan) {
          final vLate = rentalLateDays(pLoan, vToday);
          final vLines = [
            if (pLoan.person.isNotEmpty) pLoan.person,
            vText.rentalLine(
              // Jour et mois suffisent pour une location de quelques jours
              '${pLoan.returnBy!.substring(8, 10)}/${pLoan.returnBy!.substring(5, 7)}',
              rentalDays(pLoan),
              formatDecimal(rentalCost(pLoan)),
              formatDecimal(pLoan.depositEuros),
            ),
            if (vLate > 0) vText.rentalLate(vLate, formatDecimal(vLate * pLoan.dayEuros)),
          ];

          return vLines.join('\n');
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(vText.loanTitle),
            actions: [
              IconButton(
                tooltip: vText.rentalAdd,
                icon: const Icon(Icons.storefront_outlined),
                onPressed: () => _rent(pContext, vToday),
              ),
            ],
          ),
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
                vTile(
                  vLoan,
                  vText.loanSince(vLoan.person, loanDays(vLoan, vToday)),
                  Icons.handshake_outlined,
                ),
              if (vRentals.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
                  child: Text(vText.rentalTitle, style: vTheme.textTheme.titleMedium),
                ),
                for (final vRental in vRentals)
                  vTile(vRental, vRentalText(vRental), Icons.storefront_outlined),
              ],
            ],
          ),
        );
      },
    );
  }
}
