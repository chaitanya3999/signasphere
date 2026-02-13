import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_contacts_service.dart';

final emergencyContactsServiceProvider = Provider<EmergencyContactsService>((ref) {
  return EmergencyContactsService();
});

final emergencyContactsProvider =
    AsyncNotifierProvider<EmergencyContactsNotifier, List<EmergencyContact>>(
  EmergencyContactsNotifier.new,
);

class EmergencyContactsNotifier extends AsyncNotifier<List<EmergencyContact>> {
  EmergencyContactsService get _service => ref.read(emergencyContactsServiceProvider);

  @override
  Future<List<EmergencyContact>> build() async {
    return _service.loadContacts();
  }

  Future<bool> addContact(EmergencyContact contact) async {
    final current = state.valueOrNull ?? [];
    if (current.length >= EmergencyContactsService.maxContacts) return false;

    state = const AsyncLoading();
    final success = await _service.addContact(contact);
    if (success) {
      state = AsyncData(await _service.loadContacts());
    } else {
      state = AsyncData(current);
    }
    return success;
  }

  Future<void> updateContact(EmergencyContact updated) async {
    state = const AsyncLoading();
    await _service.updateContact(updated);
    state = AsyncData(await _service.loadContacts());
  }

  Future<void> deleteContact(String id) async {
    state = const AsyncLoading();
    await _service.deleteContact(id);
    state = AsyncData(await _service.loadContacts());
  }
}
