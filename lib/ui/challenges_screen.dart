import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/challenges.dart';
import '../state/settings_controller.dart';
import 'gestures_screen.dart';
import 'theme.dart';

/// Mode apprentissage : un défi par carte, réussi ou à refaire, et un badge discret en haut.
/// Avec [settings], le carnet des défis est gardé dans les réglages de l'appli.
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key, this.settings});

  final SettingsController? settings;

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  // Carnet tenu ici quand il n'y a pas de réglages où l'enregistrer
  var _local = <Challenge, ChallengeRecord>{};

  Map<Challenge, ChallengeRecord> get _records => widget.settings?.settings.challenges ?? _local;

  Future<void> _note(Challenge pChallenge, bool pSuccess) async {
    final vRecords = recordAttempt(_records, pChallenge, pSuccess: pSuccess);
    final vSettings = widget.settings;
    if (vSettings == null) {
      setState(() => _local = vRecords);
    } else {
      await vSettings.update(vSettings.settings.copyWith(challenges: vRecords));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vSettings = widget.settings;

    return vSettings == null
        ? _build(context)
        : ListenableBuilder(listenable: vSettings, builder: (pContext, _) => _build(pContext));
  }

  Widget _build(BuildContext pContext) {
    final vText = AppLocalizations.of(pContext);
    final vTheme = Theme.of(pContext);
    final vBadge = learningBadge(_records);

    return Scaffold(
      appBar: AppBar(
        title: Text(vText.learnTitle),
        actions: [
          // Badge discret : une icône, son nom en info-bulle
          if (vBadge != LearningBadge.none)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: learningBadgeName(vText, vBadge),
                child: Icon(_badgeIcon(vBadge), color: vTheme.colorScheme.primary),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(vText.learnIntro, style: vTheme.textTheme.bodyMedium),
          ),
          if (widget.settings == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: IconLine(Icons.info_outline, vText.learnNoSave),
            ),
          for (final vChallenge in Challenge.values)
            _ChallengeCard(
              challenge: vChallenge,
              record: _records[vChallenge] ?? noAttempt,
              onNote: (pSuccess) => _note(vChallenge, pSuccess),
            ),
        ],
      ),
    );
  }
}

IconData _badgeIcon(LearningBadge pBadge) => switch (pBadge) {
  LearningBadge.none => Icons.workspace_premium_outlined,
  LearningBadge.first => Icons.star_outline,
  LearningBadge.half => Icons.star_half,
  LearningBadge.all => Icons.star,
};

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge, required this.record, required this.onNote});

  final Challenge challenge;
  final ChallengeRecord record;
  final ValueChanged<bool> onNote;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vDone = record.successes > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(challengeName(vText, challenge), style: vTheme.textTheme.titleMedium),
                ),
                if (vDone) Icon(Icons.check_circle, color: vTheme.colorScheme.primary),
              ],
            ),
            Text(
              record.attempts == 0
                  ? vText.learnNever
                  : vText.learnRecord(record.successes, record.attempts),
              style: vTheme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(vText.learnTry, style: vTheme.textTheme.titleSmall),
            Text(challengeTry(vText, challenge)),
            const SizedBox(height: 4),
            Text(vText.learnCheck, style: vTheme.textTheme.titleSmall),
            Text(challengeCheck(vText, challenge)),
            Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => GestureScreen(gesture: challenge.gesture),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(vText.learnSeeGesture),
                ),
                OutlinedButton(onPressed: () => onNote(false), child: Text(vText.learnFailed)),
                FilledButton(onPressed: () => onNote(true), child: Text(vText.learnSuccess)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String learningBadgeName(AppLocalizations pText, LearningBadge pBadge) => switch (pBadge) {
  LearningBadge.none => '',
  LearningBadge.first => pText.learnBadgeFirst,
  LearningBadge.half => pText.learnBadgeHalf,
  LearningBadge.all => pText.learnBadgeAll,
};

String challengeName(AppLocalizations pText, Challenge pChallenge) => switch (pChallenge) {
  Challenge.squareCut => pText.learnSquareCut,
  Challenge.straightHole => pText.learnStraightHole,
  Challenge.sealantBead => pText.learnSealantBead,
  Challenge.mitreCut => pText.learnMitreCut,
  Challenge.levelLine => pText.learnLevelLine,
  Challenge.tenon => pText.learnTenon,
};

String challengeTry(AppLocalizations pText, Challenge pChallenge) => switch (pChallenge) {
  Challenge.squareCut => pText.learnSquareCutTry,
  Challenge.straightHole => pText.learnStraightHoleTry,
  Challenge.sealantBead => pText.learnSealantBeadTry,
  Challenge.mitreCut => pText.learnMitreCutTry,
  Challenge.levelLine => pText.learnLevelLineTry,
  Challenge.tenon => pText.learnTenonTry,
};

String challengeCheck(AppLocalizations pText, Challenge pChallenge) => switch (pChallenge) {
  Challenge.squareCut => pText.learnSquareCutCheck,
  Challenge.straightHole => pText.learnStraightHoleCheck,
  Challenge.sealantBead => pText.learnSealantBeadCheck,
  Challenge.mitreCut => pText.learnMitreCutCheck,
  Challenge.levelLine => pText.learnLevelLineCheck,
  Challenge.tenon => pText.learnTenonCheck,
};
