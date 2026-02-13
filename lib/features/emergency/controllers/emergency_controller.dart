import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/sound_service.dart';
import '../services/emergency_contacts_service.dart';
import '../models/emergency_contact.dart';

final emergencyControllerProvider = StateNotifierProvider<EmergencyController, bool>((ref) {
  final soundService = ref.watch(soundServiceProvider);
  return EmergencyController(soundService);
});

class EmergencyController extends StateNotifier<bool> {
  final SoundService _soundService;
  final EmergencyContactsService _contactsService = EmergencyContactsService();

  EmergencyController(this._soundService) : super(false);

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<void> sendSMS(String message) async {
    final contacts = await _contactsService.loadContacts();
    if (contacts.isEmpty) {
      // Logic for no contacts can be handled in UI by checking this before calling
      return; 
    }
    
    // Send to first contact for now, or loop? The requirement implies singular action.
    // "Send SMS + Location to parent contacts"
    // We'll pick the first one as primary.
    final contact = contacts.first;
    
    final position = await getCurrentLocation();
    String locationText = "";
    if (position != null) {
      locationText = "\nLocation: https://maps.google.com/?q=${position.latitude},${position.longitude}";
    }

    final fullMessage = "🚨 EMERGENCY ALERT from Signasphere 🚨\nMessage: $message$locationText";
    
    final uri = Uri(
      scheme: 'sms',
      path: contact.phone,
      queryParameters: <String, String>{
        'body': fullMessage,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> sendWhatsApp(String message) async {
    final contacts = await _contactsService.loadContacts();
    if (contacts.isEmpty) return;

    final contact = contacts.first;
    final position = await getCurrentLocation();
    String locationText = "";
    if (position != null) {
      locationText = "\nLocation: https://maps.google.com/?q=${position.latitude},${position.longitude}";
    }
    
    final fullMessage = Uri.encodeComponent("🚨 EMERGENCY ALERT from Signasphere 🚨\nMessage: $message$locationText");
    // Ensure number is international format for WA. Assuming user stored it correctly or we prepend cleaner.
    // Just using what's stored.
    final uri = Uri.parse("https://wa.me/${contact.phone}?text=$fullMessage");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> callParent() async {
    final contacts = await _contactsService.loadContacts();
    if (contacts.isEmpty) return;

    final contact = contacts.first;
    final uri = Uri.parse("tel:${contact.phone}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> toggleAlarm() async {
    if (state) {
      await _soundService.stopAlarm();
      state = false;
    } else {
      await _soundService.playAlarm();
      state = true;
    }
  }

  Future<void> stopAlarm() async {
    if (state) {
      await _soundService.stopAlarm();
      state = false;
    }
  }
  
  // Expose sound service helpers
  Future<void> playTap() => _soundService.playTap();
  Future<void> playWarning() => _soundService.playWarning();
}
