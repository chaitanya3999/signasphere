import 'package:flutter/material.dart';
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

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;

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

  void _handleVoiceInput() async {
    final sttService = ref.read(sttServiceProvider);

    if (_isListening) {
      await sttService.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await sttService.listen(onResult: (text) {
        if (text.isNotEmpty) {
          _sendMessage(text);
          sttService.stop();
          setState(() => _isListening = false);
        }
      });
    }
  }

  void _handleSignInput() async {
    // Simulate sign input for demo
    final simulatedSigns = [
      "Where is the restroom?",
      "Thank you for helping!",
      "I need a doctor.",
      "Can you help me?"
    ];
    final randomSign = (simulatedSigns..shuffle()).first;
    _sendMessage(randomSign);
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
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

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(conversationControllerProvider);

    // Auto-scroll on new messages
    ref.listen(conversationControllerProvider, (prev, next) {
      if (next.length > (prev?.length ?? 0)) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Conversation',
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
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
            padding: const EdgeInsets.fromLTRB(16, 120, 16, 120),
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
                    ? PhosphorIcons.microphone(PhosphorIconsStyle.fill)
                    : PhosphorIcons.handWaving(PhosphorIconsStyle.fill),
                color: msg.isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                onSpeak: () => _speak(msg.text),
              );
            },
          ),

          // Bottom Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 30),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sign Input (Simulated)
                  _FloatButton(
                    icon: PhosphorIcons.camera(PhosphorIconsStyle.fill),
                    color: Theme.of(context).colorScheme.secondary,
                    label: "Sign",
                    onTap: _handleSignInput,
                  ),

                  // Voice Input (Mic)
                  GestureDetector(
                    onTap: _handleVoiceInput,
                    child: GlassContainer(
                      width: 70,
                      height: 70,
                      borderRadius: BorderRadius.circular(35),
                      color: _isListening
                          ? Colors.redAccent
                          : Theme.of(context).colorScheme.primary,
                      opacity: 0.2,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.primary, width: 2),
                      child: Icon(
                          _isListening
                              ? Icons.stop
                              : PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                          size: 28,
                          color: _isListening
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary),
                    ).animate(target: _isListening ? 1 : 0)
                     .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.5.seconds)
                     .then()
                     .shake(),
                  ),

                  // Text Input (Keyboard)
                  _FloatButton(
                    icon: PhosphorIcons.keyboard(PhosphorIconsStyle.fill),
                    color: Colors.white,
                    label: "Type",
                    onTap: () {
                      showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (c) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(16),
                                  opacity: 0.9, // High opacity for readability
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: GlassTextField(
                                        controller: _textController,
                                        hintText: "Type a message...",
                                        onSubmitted: (val) {
                                          _sendMessage(val);
                                          Navigator.pop(context);
                                        },
                                        focusNode: FocusNode()..requestFocus(),
                                      )),
                                      IconButton(
                                        icon: const Icon(Icons.send),
                                        onPressed: () {
                                          _sendMessage(_textController.text);
                                          Navigator.pop(context);
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ));
                    },
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("Partner is typing...",
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade()
          .scale(begin: const Offset(0.95, 0.95)),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String timestamp;
  final IconData icon;
  final Color color;
  final VoidCallback onSpeak;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.icon,
    required this.color,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
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
                 backgroundColor: color.withOpacity(0.2),
                 radius: 16,
                 child: Icon(icon, size: 16, color: color),
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
                    opacity: isMe ? 0.2 : 0.05,
                    border: Border.all(
                      color: isMe
                          ? color.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: const TextStyle(fontSize: 16, height: 1.4),
                        ),
                        if (!isMe) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: onSpeak,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(PhosphorIcons.speakerHigh(PhosphorIconsStyle.fill), size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                const SizedBox(width: 4),
                                Text("Speak", style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                              ],
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

class _FloatButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _FloatButton(
      {required this.icon,
      required this.color,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassContainer(
            width: 50,
            height: 50,
            borderRadius: BorderRadius.circular(25),
            opacity: 0.1,
            child: IconButton(
              icon: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
              onPressed: onTap,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
