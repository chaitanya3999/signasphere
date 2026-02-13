import 'package:shared_preferences/shared_preferences.dart';
import '../models/usage_event.dart';

class UsageTrackerService {
  final SharedPreferences _prefs;

  UsageTrackerService(this._prefs);

  String _key(String userId) => 'usage_events_$userId';

  List<UsageEvent> getEvents(String userId) {
    final jsonStr = _prefs.getString(_key(userId));
    if (jsonStr == null || jsonStr.isEmpty) return [];
    return UsageEvent.decodeList(jsonStr);
  }

  Future<void> trackEvent(String userId, UsageEventType type) async {
    final events = getEvents(userId);
    final event = UsageEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      timestamp: DateTime.now(),
    );
    events.add(event);
    // Keep only last 500 events per user
    final trimmed = events.length > 500 ? events.sublist(events.length - 500) : events;
    await _prefs.setString(_key(userId), UsageEvent.encodeList(trimmed));
  }
}
