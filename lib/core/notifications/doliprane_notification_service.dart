import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service de notifications locales pour les rappels d'ordonnance Doliprane.
/// Sur web : aucune opération (no-op).
class DolipraneNotificationService {
  DolipraneNotificationService._();

  static final DolipraneNotificationService _instance = DolipraneNotificationService._();
  static DolipraneNotificationService get instance => _instance;

  static const int _idBase = 50000;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// ID de notification unique pour une ordonnance (évite les collisions).
  static int notificationIdForPrescription(int prescriptionId) => _idBase + prescriptionId;

  /// Initialise le plugin et demande les permissions. À appeler au démarrage de l'app (mobile uniquement).
  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_instance._initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Paris'));
    } catch (_) {
      // Fallback si la timezone n'est pas trouvée
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _instance._plugin.initialize(settings);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _instance._plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _instance._plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _instance._initialized = true;
  }

  /// Planifie une notification de rappel pour la date donnée à 9h (heure locale).
  /// [prescriptionId] : id de l'ordonnance (pour annuler plus tard).
  /// [reminderDate] : date du rappel (jour à 9h).
  /// [childFirstName] : prénom de l'enfant (affiché dans le corps du message).
  static Future<void> scheduleReminder({
    required int prescriptionId,
    required DateTime reminderDate,
    String? childFirstName,
  }) async {
    if (kIsWeb) return;
    if (!_instance._initialized) return;

    final scheduled = tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
      0,
    );
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    final id = notificationIdForPrescription(prescriptionId);
    final childLabel = childFirstName != null && childFirstName.isNotEmpty ? ' ($childFirstName)' : '';
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'doliprane_reminders',
        'Rappels ordonnance Doliprane',
        channelDescription: 'Rappel avant fin de validité d\'une ordonnance Doliprane',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
      ),
    );

    await _instance._plugin.zonedSchedule(
      id,
      'Rappel ordonnance Doliprane',
      'Pensez à renouveler l\'ordonnance Doliprane$childLabel.',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Annule le rappel pour l'ordonnance donnée.
  static Future<void> cancelReminder(int prescriptionId) async {
    if (kIsWeb) return;
    final id = notificationIdForPrescription(prescriptionId);
    await _instance._plugin.cancel(id);
  }
}
