import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService I = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      final result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (result == true) {
        _initialized = true;
        debugPrint('Notification service initialized successfully');

        // Request notification permission (Android 13+)
        await _requestPermissions();
      } else {
        debugPrint('Notification service initialization failed');
      }
    } catch (e) {
      debugPrint('Notification service initialization error: $e');
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('Notification permission: ${granted == true ? "Granted" : "Denied"}');
      }
    } catch (e) {
      debugPrint('Request notification permission error: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Send budget alert notification
  Future<void> sendBudgetAlert({
    required String percentage,
    required double spent,
    required double budget,
  }) async {
    if (!_initialized) {
      debugPrint('Notification service not initialized, skipping notification');
      return;
    }

    try {
      String title;
      String body;

      if (percentage == '100') {
        title = '⚠️ Budget Exceeded!';
        body = 'Monthly budget \$${budget.toStringAsFixed(2)} has been fully used!\nCurrent spending: \$${spent.toStringAsFixed(2)}';
      } else if (percentage == '80') {
        title = '⚡ Budget Alert';
        body = 'Monthly budget 80% used!\nSpent: \$${spent.toStringAsFixed(2)} / \$${budget.toStringAsFixed(2)}';
      } else {
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'budget_alerts',
        'Budget Alerts',
        channelDescription: 'Monthly budget usage alerts',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        percentage == '100' ? 1 : 0, // Different notification IDs
        title,
        body,
        notificationDetails,
        payload: 'budget_alert_$percentage',
      );

      debugPrint('Budget alert sent: $percentage%');
    } catch (e) {
      debugPrint('Send notification error: $e');
    }
  }

  // Send subscription alert notification
  Future<void> sendSubscriptionAlert({
    required String name,
    required double amount,
    required int daysUntil,
  }) async {
    if (!_initialized) {
      debugPrint('Notification service not initialized, skipping notification');
      return;
    }

    try {
      String title;
      String body;

      if (daysUntil == 0) {
        title = '💳 Billing Today';
        body = '$name will be billed \$${amount.toStringAsFixed(2)} today';
      } else if (daysUntil == 1) {
        title = '⏰ Billing Tomorrow';
        body = '$name will be billed \$${amount.toStringAsFixed(2)} tomorrow';
      } else {
        title = '📅 Upcoming Billing';
        body = '$name will be billed \$${amount.toStringAsFixed(2)} in $daysUntil days';
      }

      const androidDetails = AndroidNotificationDetails(
        'subscription_alerts',
        'Subscription Alerts',
        channelDescription: 'Fixed expense billing alerts',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        2 + daysUntil, // Different notification IDs
        title,
        body,
        notificationDetails,
        payload: 'subscription_alert_$name',
      );

      debugPrint('Subscription alert sent: $name ($daysUntil days)');
    } catch (e) {
      debugPrint('Send subscription notification error: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

