import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/review.dart';
import '../logic/time_tracking.dart';
import '../state/worksites_controller.dart';
import 'dialogs.dart';
import 'planning_card.dart';
import 'shopping_texts.dart';
import 'theme.dart';

/// Bilan de fin de chantier : coût prévu et réel, temps, chutes, reprises, et leçons à garder.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.controller, required this.worksiteId});

  final WorksitesController controller;
  final String worksiteId;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (pContext, _) {
        final vWorksite = controller.worksite(worksiteId);
        if (vWorksite == null) {
          return const Scaffold();
        }
        final vReview = reviewWorksite(vWorksite);
        final vOverrun = vReview.overrunPercent;

        return Scaffold(
          appBar: AppBar(title: Text(vText.reviewTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final vLesson = await askName(
                pContext,
                pTitle: vText.reviewAddLesson,
                pLabel: vText.reviewLesson,
              );
              if (vLesson != null && vLesson.trim().isNotEmpty) {
                controller.updateWorksite(
                  vWorksite.copyWith(lessons: [...vWorksite.lessons, vLesson.trim()]),
                );
              }
            },
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(vText.reviewAddLesson),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vText.reviewCost, style: vTheme.textTheme.titleMedium),
                      BigFigure('${formatEuros(vReview.spentCost)} €'),
                      Text(
                        vText.reviewPlanned(formatEuros(vReview.plannedCost)) +
                            (vReview.plannedIncomplete ? vText.reviewPlannedIncomplete : ''),
                      ),
                      EstimateNote(vText.estimateFromPrices),
                      if (vOverrun != null)
                        IconLine(
                          vOverrun > 0 ? Icons.trending_up : Icons.trending_down,
                          vOverrun > 0
                              ? vText.reviewOver(vOverrun.round())
                              : vText.reviewUnder((-vOverrun).round()),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              IconLine(Icons.timer_outlined, vText.reviewTime(formatDuration(vReview.minutes))),
              if (vReview.longestPhase != null)
                IconLine(
                  Icons.hourglass_top,
                  vText.reviewLongest(phaseLabel(vText, vReview.longestPhase!)),
                ),
              IconLine(Icons.recycling, vText.reviewOffcuts(vReview.offcutsKept)),
              if (vReview.touchUpsTotal > 0)
                IconLine(
                  Icons.format_paint_outlined,
                  vText.reviewTouchUps(vReview.touchUpsDone, vReview.touchUpsTotal),
                ),
              IconLine(Icons.menu_book_outlined, vText.reviewJournal(vReview.journalEntries)),
              if (vReview.daysWorked > 0)
                IconLine(Icons.event_available_outlined, vText.reviewDays(vReview.daysWorked)),
              const SizedBox(height: 12),
              Text(vText.reviewLessons, style: vTheme.textTheme.titleMedium),
              if (vWorksite.lessons.isEmpty) Text(vText.reviewLessonsEmpty),
              for (var vIndex = 0; vIndex < vWorksite.lessons.length; vIndex++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(vWorksite.lessons[vIndex]),
                  trailing: IconButton(
                    tooltip: vText.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => controller.updateWorksite(
                      vWorksite.copyWith(lessons: [...vWorksite.lessons]..removeAt(vIndex)),
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
