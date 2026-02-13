import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_contact.dart';

class EmergencyContactsService {
  static const String _storageKey = 'emergency_contacts';
  static const int maxContacts = 20;

  Future<List<EmergencyContact>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    return EmergencyContact.decodeList(jsonStr);
  }

  Future<void> saveContacts(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, EmergencyContact.encodeList(contacts));
  }

  Future<bool> addContact(EmergencyContact contact) async {
    final contacts = await loadContacts();
    if (contacts.length >= maxContacts) return false;
    contacts.add(contact);
    await saveContacts(contacts);
    return true;
  }

  Future<void> updateContact(EmergencyContact updated) async {
    final contacts = await loadContacts();
    final index = contacts.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      contacts[index] = updated;
      await saveContacts(contacts);
    }
  }

  Future<void> deleteContact(String id) async {
    final contacts = await loadContacts();
    contacts.removeWhere((c) => c.id == id);
    await saveContacts(contacts);
  }
}
