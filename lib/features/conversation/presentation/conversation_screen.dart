import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/services/stt_service.dart';
import '../data/conversation_repository.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;

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
    ref.read(conversationRepositoryProvider).sendMessage(text);
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
    final simulatedSigns = ["Where is the restroom?", "Thank you for helping!", "I need a doctor."];
    final randomSign = (simulatedSigns..shuffle()).first;
    _sendMessage(randomSign);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(conversationStreamProvider);

    // Auto-scroll on new messages
    ref.listen(conversationStreamProvider, (prev, next) {
      if (next.hasValue) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          borderRadius: BorderRadius.circular(20),
          opacity: 0.1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.users(PhosphorIconsStyle.fill), size: 16, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Conversation Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          messagesAsync.when(
            data: (messages) {
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 120, 16, 100),
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
                    icon: msg.isMe ? PhosphorIcons.microphone(PhosphorIconsStyle.fill) : PhosphorIcons.handWaving(PhosphorIconsStyle.fill),
                    color: msg.isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
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
                       width: 80, 
                       height: 80,
                       borderRadius: BorderRadius.circular(40),
                       color: _isListening ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                       opacity: 0.2,
                       border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                       child: Icon(
                         _isListening ? Icons.stop : PhosphorIcons.microphone(PhosphorIconsStyle.fill), 
                         size: 32, 
                         color: _isListening ? Colors.white : Theme.of(context).colorScheme.primary
                       ),
                     ).animate(target: _isListening ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 1.5.seconds).then().shake(),
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
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(16),
                              opacity: 0.9, // High opacity for readability
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Row(
                                children: [
                                  Expanded(child: TextField(
                                    controller: _textController, 
                                    autofocus: true,
                                    decoration: const InputDecoration(hintText: "Type a message..."),
                                    onSubmitted: (val) {
                                      _sendMessage(val);
                                      Navigator.pop(context);
                                    },
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
                          )
                        );
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
         child: const Text("Partner is typing...", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).fade().scale(begin: const Offset(0.95, 0.95)),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String timestamp;
  final IconData icon;
  final Color color;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.icon,
    required this.color,
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
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                      color: isMe ? color.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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

  const _FloatButton({required this.icon, required this.color, required this.label, required this.onTap});

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
