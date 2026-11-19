import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/noise.dart';
import 'theme.dart';

/// Bruit et voisinage : horaires habituels, où l'on en est maintenant, et le rappel du week-end.
class NoiseScreen extends StatelessWidget {
  const NoiseScreen({super.key, this.now});

  /// Instant de référence ; maintenant si absent, fixé dans les tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNow = now ?? DateTime.now();
    final vStatus = noiseStatus(vNow);

    return Scaffold(
      appBar: AppBar(title: Text(vText.noiseTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          IconLine(Icons.account_balance_outlined, vText.noiseIntro),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final vDay in NoiseDay.values) ...[
                    Text(_dayName(vText, vDay), style: vTheme.textTheme.titleSmall),
                    for (final vWindow in noiseWindows(vDay))
                      IconLine(
                        Icons.schedule,
                        vText.noiseWindow(
                          noiseClockText(vText, vWindow.fromMinute),
                          noiseClockText(vText, vWindow.toMinute),
                        ),
                      ),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          IconLine(
            vStatus.allowed ? Icons.volume_up_outlined : Icons.volume_off_outlined,
            vStatus.allowed
                ? vText.noiseNowAllowed(_time(vText, vStatus.until!))
                : vText.noiseNowQuiet(
                    _isSameDay(vStatus.next, vNow) ? vText.noiseToday : vText.noiseTomorrow,
                    _time(vText, vStatus.next),
                  ),
            color: vStatus.allowed ? null : vTheme.colorScheme.error,
          ),
          IconLine(Icons.construction, vText.noiseTools),
          IconLine(Icons.handshake_outlined, vText.noiseTips),
          IconLine(Icons.alarm_add_outlined, vText.noiseReminder),
        ],
      ),
    );
  }
}

String _dayName(AppLocalizations pText, NoiseDay pDay) => switch (pDay) {
  NoiseDay.weekday => pText.noiseWeekday,
  NoiseDay.saturday => pText.noiseSaturday,
  NoiseDay.sundayOrHoliday => pText.noiseSunday,
};

bool _isSameDay(DateTime pA, DateTime pB) =>
    pA.year == pB.year && pA.month == pB.month && pA.day == pB.day;

String _time(AppLocalizations pText, DateTime pAt) =>
    noiseClockText(pText, pAt.hour * 60 + pAt.minute);

/// Heure écrite comme on la dit : « 8 h 30 », « 12 h ».
String noiseClockText(AppLocalizations pText, int pMinute) {
  final vMinute = pMinute % 60;
  final rText = pText
      .noiseClock(pMinute ~/ 60, vMinute == 0 ? '' : vMinute.toString().padLeft(2, '0'))
      .trim();

  return rText;
}
