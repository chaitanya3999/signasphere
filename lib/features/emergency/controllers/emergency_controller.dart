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
    if (contacts.isEmpty) return;
    
    final contact = contacts.first;
    
    String locationText = "";
    try {
      final position = await getCurrentLocation();
      if (position != null) {
        locationText = "\nLocation: https://maps.google.com/?q=${position.latitude},${position.longitude}";
      }
    } catch (_) {
      // Ignore location errors and send message anyway
    }

    final fullMessage = "🚨 EMERGENCY ALERT from Signasphere 🚨\nMessage: $message$locationText";
    
    // Use the `sms:` scheme. 
    // Note: On Android, the query parameter for body is 'body'. on iOS it might be '&body=' but url_launcher handles some of this.
    // Ideally we use a consistent URI.
    final Uri uri = Uri(
      scheme: 'sms',
      path: contact.phone,
      queryParameters: <String, String>{
        'body': fullMessage,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback or error handling
      print("Could not launch SMS url");
    }
  }

  Future<void> sendWhatsApp(String message) async {
    final contacts = await _contactsService.loadContacts();
    if (contacts.isEmpty) return;

    final contact = contacts.first;
    
    String locationText = "";
    try {
      final position = await getCurrentLocation();
      if (position != null) {
        locationText = "\nLocation: https://maps.google.com/?q=${position.latitude},${position.longitude}";
      }
    } catch (_) {
      // Ignore location errors
    }
    
    final fullMessage = "🚨 EMERGENCY ALERT from Signasphere 🚨\nMessage: $message$locationText";
    
    // Clean phone number (remove +, spaces, dashes for wa.me link if needed, but whatsapp:// usually handles it)
    String phone = contact.phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // 1. Try Native WhatsApp scheme first (Android/iOS app)
    final nativeUri = Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encodeComponent(fullMessage)}");
    
    // 2. Fallback Web/Universal Link (Works on Web & Android if app not found/intercepted)
    final webUri = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(fullMessage)}");

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri);
      } else {
        // Fallback to web link
        if (await canLaunchUrl(webUri)) {
           await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print("Error launching WhatsApp: $e");
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
