import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_container.dart';

class ConversationScreen extends StatelessWidget {
  const ConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 120, 16, 100),
            children: [
              _ChatBubble(
                message: "Hi! I wanted to ask about the appointment.",
                isMe: false,
                timestamp: "10:23 AM",
                icon: PhosphorIcons.handWaving(PhosphorIconsStyle.fill),
                color: Theme.of(context).colorScheme.secondary,
              ),
              _ChatBubble(
                message: "Sure, what time fits you best?",
                isMe: true,
                timestamp: "10:24 AM",
                icon: PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                color: Theme.of(context).colorScheme.primary,
              ),
              _ChatBubble(
                message: "Is 2:00 PM okay?",
                isMe: false,
                timestamp: "10:24 AM",
                icon: PhosphorIcons.handWaving(PhosphorIconsStyle.fill),
                color: Theme.of(context).colorScheme.secondary,
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    "Listening...", 
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 1.seconds).fadeOut(delay: 1.seconds),
                ),
              ),
            ],
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
                   // Sign Input (Camera)
                   _FloatButton(
                     icon: PhosphorIcons.camera(PhosphorIconsStyle.fill),
                     color: Theme.of(context).colorScheme.secondary,
                     label: "Sign",
                     onTap: () {},
                   ),
                   
                   // Voice Input (Mic)
                   GestureDetector(
                     onTap: () {},
                     child: GlassContainer(
                       width: 80, 
                       height: 80,
                       borderRadius: BorderRadius.circular(40),
                       color: Theme.of(context).colorScheme.primary,
                       opacity: 0.2,
                       border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                       child: Icon(PhosphorIcons.microphone(PhosphorIconsStyle.fill), size: 32, color: Theme.of(context).colorScheme.primary),
                     ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 1.5.seconds),
                   ),

                   // Text Input (Keyboard)
                   _FloatButton(
                     icon: PhosphorIcons.keyboard(PhosphorIconsStyle.fill),
                     color: Colors.white,
                     label: "Type",
                     onTap: () {},
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
    return Column(
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
    );
  }
}
