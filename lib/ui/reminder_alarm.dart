import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../logic/reminders.dart';

/// Notification Android à la fin d'une attente : remplaçable dans les tests.
abstract interface class ReminderAlarm {
  Future<void> schedule(Reminder pReminder, String pTitle, String pBody);

  Future<void> cancel(Reminder pReminder);
}

/// Sans notification : tests, et tant que l'appli n'a pas branché la vraie.
class SilentAlarm implements ReminderAlarm {
  const SilentAlarm();

  @override
  Future<void> schedule(Reminder pReminder, String pTitle, String pBody) async {}

  @override
  Future<void> cancel(Reminder pReminder) async {}
}

/// Alarme utilisée par les écrans ; [main] y met la vraie au démarrage.
ReminderAlarm aReminderAlarm = const SilentAlarm();

/// Notifications locales : programmées sur le téléphone, rien ne passe par le réseau.
class LocalReminderAlarm implements ReminderAlarm {
  final _aPlugin = FlutterLocalNotificationsPlugin();
  bool _aReady = false;

  Future<void> _init() async {
    if (_aReady) {
      return;
    }
    tz_data.initializeTimeZones();
    await _aPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    // Android 13 et plus demandent l'accord de l'utilisateur, une fois
    await _aPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _aReady = true;
  }

  @override
  Future<void> schedule(Reminder pReminder, String pTitle, String pBody) async {
    if (!pReminder.dueAt.isAfter(DateTime.now())) {
      return;
    }
    await _init();
    await _aPlugin.zonedSchedule(
      id: notificationId(pReminder.id),
      title: pTitle,
      body: pBody,
      // Un instant absolu : le fuseau UTC suffit, sans lire celui du téléphone
      scheduledDate: tz.TZDateTime.from(pReminder.dueAt, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('attentes', 'Attentes du chantier'),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(Reminder pReminder) async {
    await _init();
    await _aPlugin.cancel(id: notificationId(pReminder.id));
  }
}
