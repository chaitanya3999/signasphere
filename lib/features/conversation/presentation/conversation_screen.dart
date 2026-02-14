import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/services/stt_service.dart';
import '../data/conversation_repository.dart';
import '../presentation/conversation_controller.dart';
import '../presentation/quick_phrases_provider.dart';
import '../../user_tracking/controllers/usage_controller.dart';
import '../../user_tracking/models/usage_event.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _configureTts();
  }

  void _configureTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(conversationControllerProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _speak(String text) async {
    // Regex for words with 2+ uppercase letters (e.g. ME, HELP, STOP)
    // This avoids matching "I" in "I am here", but matches "ME" in "ME - HELP".
    final RegExp glossRegex = RegExp(r'\b[A-Z]{2,}\b');
    
    final matches = glossRegex.allMatches(text);
    if (matches.isNotEmpty) {
      // If we found Gloss words, speak ONLY those (joined by space)
      // This fulfills the request: "speak the words which in capital case only"
      final glossText = matches.map((m) => m.group(0)).join(" ");
      await _flutterTts.speak(glossText);
    } else {
      // Fallback: If no gloss found (e.g. simple sentence), speak everything
      await _flutterTts.speak(text);
    }
  }
  void _showFeatureMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Chat Options", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), color: Theme.of(context).colorScheme.primary),
              ),
              title: const Text("New Chat", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Clear context and start fresh"),
              onTap: () {
                Navigator.pop(context);
                ref.read(conversationControllerProvider.notifier).clearHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Started a new conversation"), duration: Duration(seconds: 1)),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, color: Colors.purple),
              ),
              title: const Text("View History", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("See previous messages"),
              onTap: () {
                Navigator.pop(context);
                _showHistory();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _HistoryModal(
        onClear: () {
          ref.read(conversationControllerProvider.notifier).clearHistory();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showManagePhrases() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _ManagePhrasesModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.read(usageControllerProvider).trackEvent(UsageEventType.usedConversation);
    final messages = ref.watch(conversationControllerProvider);

    // Auto-scroll on new messages & handle rate limit feedback
    ref.listen(conversationControllerProvider, (prev, next) {
      if (next.length > (prev?.length ?? 0)) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        
        // Show rate limit snackbars from error message
        final lastMsg = next.last;
        if (lastMsg.status == 'error') {
          if (lastMsg.text.contains("AI is busy")) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: const Text("AI is busy. Trying again..."),
                 backgroundColor: Colors.orangeAccent.withOpacity(0.8),
                 behavior: SnackBarBehavior.floating,
               )
             );
          } else if (lastMsg.text.contains("overloaded")) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: const Text("AI is overloaded. Please try again in 1 minute."),
                 backgroundColor: Colors.redAccent.withOpacity(0.8),
                 behavior: SnackBarBehavior.floating,
               )
             );
          }
        }
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Conversation',
        actions: [
          // GPT Mode Toggle
          Row(
            children: [
              Text("GPT", style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: ref.watch(gptModeProvider) ? Theme.of(context).colorScheme.primary : Colors.grey
              )),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: ref.watch(gptModeProvider),
                  onChanged: (val) {
                    ref.read(gptModeProvider.notifier).state = val;
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: _showManagePhrases,
            tooltip: 'Manage Phrases',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
            tooltip: 'History',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Chat Timeline
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 120, 16, 180),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              if (msg.isTyping) {
                return _TypingIndicator();
              }
              return _ChatBubble(
                message: msg.text,
                isMe: msg.isMe,
                timestamp: DateFormat('h:mm a').format(msg.timestamp),
                icon: msg.isMe
                    ? PhosphorIcons.user(PhosphorIconsStyle.fill)
                    : PhosphorIcons.robot(PhosphorIconsStyle.fill),
                color: msg.isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                onSpeak: () => _speak(msg.text),
                status: msg.status,
              );
            },
          ),

          // Bottom Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 30),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick Phrases Horizontal Bar
                  _QuickSuggestionChips(
                    onSelect: (text) => _sendMessage(text),
                  ),
                  const SizedBox(height: 12),
                  
                  // Simple Text Input Row
                  GlassContainer(
                    padding: const EdgeInsets.all(8),
                    opacity: 0.9, 
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(30),
                    child: Row(
                      children: [
                        // Feature Button (+) similar to ChatGPT
                        IconButton(
                          icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          onPressed: _showFeatureMenu,
                          tooltip: 'Features',
                        ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                        // Send Button (ChatGPT style)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                            onPressed: () => _sendMessage(_textController.text),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagePhrasesModal extends ConsumerStatefulWidget {
  const _ManagePhrasesModal();

  @override
  ConsumerState<_ManagePhrasesModal> createState() => _ManagePhrasesModalState();
}

class _ManagePhrasesModalState extends ConsumerState<_ManagePhrasesModal> {
  final TextEditingController _addController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final phrases = ref.watch(quickPhrasesProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Quick Phrases",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Add New Phrase
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addController,
                  decoration: InputDecoration(
                    hintText: "Add new phrase...",
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  maxLength: 30,
                  onSubmitted: (val) => _addPhrase(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addPhrase,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List Phrases
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: phrases.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final phrase = phrases[index];
                return ListTile(
                  title: Text(phrase),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      ref.read(quickPhrasesProvider.notifier).removePhrase(phrase);
                    },
                  ),
                );
              },
            ),
          ),
          
          if (phrases.isEmpty)
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text("No phrases yet.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
             ),
             
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
               ref.read(quickPhrasesProvider.notifier).resetToDefaults();
            }, 
            child: const Text("Reset to Defaults"),
          )
        ],
      ),
    );
  }

  void _addPhrase() {
    final text = _addController.text.trim();
    if (text.isNotEmpty) {
      ref.read(quickPhrasesProvider.notifier).addPhrase(text);
      _addController.clear();
    }
  }
}

class _HistoryModal extends StatelessWidget {
  final VoidCallback onClear;
  const _HistoryModal({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Conversation History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
              "Your chat history is saved locally. You can clear it anytime.",
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: onClear,
            child: const Text("Clear History"),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          color: Theme.of(context).colorScheme.surface,
          opacity: 0.05,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(delay: 0),
              const SizedBox(width: 4),
              _Dot(delay: 200),
              const SizedBox(width: 4),
              _Dot(delay: 400),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _Dot extends StatelessWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    )
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2), duration: 600.ms, delay: delay.ms)
    .fade(begin: 0.3, end: 1.0, duration: 600.ms, delay: delay.ms);
  }
}

class _ChatBubble extends ConsumerWidget {
  final String message;
  final bool isMe;
  final String timestamp;
  final IconData icon;
  final Color color;
  final VoidCallback onSpeak;
  final String status;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.icon,
    required this.color,
    required this.onSpeak,
    this.status = 'sent',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isError = status == 'error';
    final bubbleColor = isError ? Colors.redAccent : color;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: MediaQuery.of(context).size.width * 0.75,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
             if (!isMe) ...[
               CircleAvatar(
                 backgroundColor: bubbleColor.withOpacity(0.2),
                 radius: 16,
                 child: Icon(isError ? Icons.error_outline : icon, size: 16, color: bubbleColor),
               ),
               const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    color: isMe ? color : Theme.of(context).colorScheme.surface,
                    opacity: isMe || isError ? 0.2 : 0.05,
                    border: Border.all(
                      color: isMe
                          ? color.withOpacity(0.3)
                          : (isError ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 16, 
                            height: 1.4,
                            color: isError ? Colors.red.shade200 : null,
                          ),
                        ),
                        if (!isMe && !isError) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Speak Button
                              InkWell(
                                onTap: onSpeak,
                                child: Row(
                                  children: [
                                    Icon(PhosphorIcons.speakerHigh(PhosphorIconsStyle.fill), size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                    const SizedBox(width: 4),
                                    Text("Speak", style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Copy Button
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: message));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Copied to clipboard"), duration: Duration(seconds: 1)),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(PhosphorIcons.copy(PhosphorIconsStyle.fill), size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                    const SizedBox(width: 4),
                                    Text("Copy", style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                        if (isError) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              ref.read(conversationControllerProvider.notifier).retryLastMessage();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh, size: 14, color: Colors.redAccent),
                                  SizedBox(width: 4),
                                  Text("Retry", style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
             if (isMe) ...[
               const SizedBox(width: 8),
               CircleAvatar(
                 backgroundColor: color.withOpacity(0.2),
                 radius: 16,
                 child: Icon(icon, size: 16, color: color),
               ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}

class _QuickSuggestionChips extends ConsumerWidget {
  final Function(String) onSelect;
  const _QuickSuggestionChips({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(quickPhrasesProvider);

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: suggestions.map((text) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelect(text),
              borderRadius: BorderRadius.circular(20),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.primary,
                opacity: 0.1,
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

