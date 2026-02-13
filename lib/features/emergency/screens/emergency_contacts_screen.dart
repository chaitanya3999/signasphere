import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../controllers/emergency_contacts_controller.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_contacts_service.dart';

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(emergencyContactsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const GlassAppBar(title: 'Emergency Contacts'),
      body: SafeArea(
        child: contactsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load contacts: $e')),
          data: (contacts) {
            if (contacts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.addressBook(PhosphorIconsStyle.light),
                      size: 64,
                      color: colorScheme.onSurface.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No emergency contacts yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first contact',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.3),
                          ),
                    ),
                  ],
                ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return _ContactCard(
                  contact: contact,
                  delayMs: index * 80,
                ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.1, end: 0);
              },
            );
          },
        ),
      ),
      floatingActionButton: _AddContactFAB(),
    );
  }
}

// ──────────────────────── Contact Card ────────────────────────

class _ContactCard extends ConsumerWidget {
  final EmergencyContact contact;
  final int delayMs;

  const _ContactCard({required this.contact, this.delayMs = 0});

  Future<void> _launchDialer(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color _categoryColor(ContactCategory cat) {
    switch (cat) {
      case ContactCategory.family:
        return const Color(0xFF6C63FF);
      case ContactCategory.friend:
        return const Color(0xFF00D2D3);
      case ContactCategory.doctor:
        return const Color(0xFFE53935);
      case ContactCategory.custom:
        return const Color(0xFFFF8F00);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _categoryColor(contact.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        opacity: 0.06,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
              ),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name & category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: color,
                        opacity: 0.15,
                        child: Text(
                          contact.category.label,
                          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        contact.phone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            _IconAction(
              icon: PhosphorIcons.phone(PhosphorIconsStyle.fill),
              color: const Color(0xFF43A047),
              onTap: () {
                HapticFeedback.mediumImpact();
                _launchDialer(contact.phone);
              },
            ),
            const SizedBox(width: 4),
            _IconAction(
              icon: PhosphorIcons.pencilSimple(PhosphorIconsStyle.fill),
              color: Theme.of(context).colorScheme.primary,
              onTap: () => _showContactDialog(context, ref, existing: contact),
            ),
            const SizedBox(width: 4),
            _IconAction(
              icon: PhosphorIcons.trash(PhosphorIconsStyle.fill),
              color: const Color(0xFFE53935),
              onTap: () => _showDeleteConfirmation(context, ref, contact),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────── Small icon button ────────────────────────

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

// ──────────────────────── FAB ────────────────────────

class _AddContactFAB extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showContactDialog(context, ref);
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00D2D3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    ).animate().scale(delay: 300.ms);
  }
}

// ──────────────────────── Add / Edit Dialog ────────────────────────

void _showContactDialog(BuildContext context, WidgetRef ref, {EmergencyContact? existing}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final phoneController = TextEditingController(text: existing?.phone ?? '');
  ContactCategory selectedCategory = existing?.category ?? ContactCategory.family;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final colorScheme = Theme.of(ctx).colorScheme;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.08),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    existing != null ? 'Edit Contact' : 'Add Contact',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),

                  GlassTextField(
                    controller: nameController,
                    hintText: 'Name',
                    prefixIcon: PhosphorIcons.user(PhosphorIconsStyle.regular),
                  ),
                  const SizedBox(height: 12),

                  GlassTextField(
                    controller: phoneController,
                    hintText: 'Phone Number',
                    prefixIcon: PhosphorIcons.phone(PhosphorIconsStyle.regular),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Category selector
                  Text(
                    'Category',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ContactCategory.values.map((cat) {
                      final isSelected = cat == selectedCategory;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? colorScheme.primary.withOpacity(0.15)
                                  : colorScheme.onSurface.withOpacity(0.04),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary.withOpacity(0.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        if (name.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: const Text('Name and phone are required'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          return;
                        }

                        HapticFeedback.mediumImpact();
                        final notifier = ref.read(emergencyContactsProvider.notifier);

                        if (existing != null) {
                          await notifier.updateContact(existing.copyWith(
                            name: name,
                            phone: phone,
                            category: selectedCategory,
                          ));
                        } else {
                          final contact = EmergencyContact(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            phone: phone,
                            category: selectedCategory,
                          );
                          final success = await notifier.addContact(contact);
                          if (!success && ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Contact limit reached (max ${EmergencyContactsService.maxContacts})',
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(
                        existing != null ? 'Save Changes' : 'Add Contact',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ──────────────────────── Delete Confirmation ────────────────────────

void _showDeleteConfirmation(BuildContext context, WidgetRef ref, EmergencyContact contact) {
  showDialog(
    context: context,
    builder: (ctx) {
      final colorScheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Contact'),
        content: Text('Remove "${contact.name}" from emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await ref.read(emergencyContactsProvider.notifier).deleteContact(contact.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      );
    },
  );
}
