import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/usage_event.dart';
import '../services/usage_tracker_service.dart';

final usageTrackerServiceProvider = Provider<UsageTrackerService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return UsageTrackerService(prefs);
});

final usageControllerProvider = Provider<UsageController>((ref) {
  return UsageController(ref);
});

class UsageController {
  final Ref _ref;

  UsageController(this._ref);

  Future<void> trackEvent(UsageEventType type) async {
    final user = _ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    await _ref.read(usageTrackerServiceProvider).trackEvent(user.id, type);
  }
}
