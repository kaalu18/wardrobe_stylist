import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'stylist_engine.dart';
import 'wardrobe_db.dart';

/// Runs once a day in the background (even if the app is closed), picks the
/// outfit of the day fully offline, stores it, and raises a local notification.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Hive.initFlutter();
      await Hive.openBox('wardrobe');
      await Hive.openBox('settings');

      final picks = StylistEngine.suggest(WardrobeDb.items(), count: 1);
      if (picks.isNotEmpty) {
        await WardrobeDb.settings.put('dailyOutfit', picks.first);

        const init = AndroidInitializationSettings('@mipmap/ic_launcher');
        final notif = FlutterLocalNotificationsPlugin();
        await notif.initialize(const InitializationSettings(android: init));
        await notif.show(
          1,
          'Your outfit today',
          'Tap to see today\u2019s style pick',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_outfit', 'Daily outfit',
              channelDescription: 'Daily offline outfit suggestion',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
      return Future.value(true);
    } catch (_) {
      return Future.value(false);
    }
  });
}
