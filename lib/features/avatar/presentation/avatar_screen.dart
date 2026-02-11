import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/avatar_repository.dart';
import '../../../../core/services/stt_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_container.dart';

class AvatarScreen extends ConsumerStatefulWidget {
  const AvatarScreen({super.key});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isRendering = false;
  bool _isListening = false;
  String _avatarState = "idle"; // idle, listening, thinking, signing

  void _handleVoiceInput() async {
    final sttService = ref.read(sttServiceProvider);
    
    if (_isListening) {
      await sttService.stop();
      setState(() {
        _isListening = false;
        _avatarState = "idle";
      });
    } else {
      setState(() {
        _isListening = true;
        _avatarState = "listening";
      });
      
      await sttService.listen(onResult: (text) {
        setState(() {
          _textController.text = text;
        });
        
        // Auto-submit if silence/final result (simulated for demo)
        // In real app, we'd wait for finalResult flag from STT
        if (text.isNotEmpty && text.split(' ').length > 2) {
             _submitText(); 
             sttService.stop();
             setState(() => _isListening = false);
        }
      });
    }
  }

  void _submitText() async {
    if (_textController.text.isNotEmpty && !_isRendering) {
      setState(() {
        _isRendering = true;
        _avatarState = "thinking";
      });
      
      final text = _textController.text;
      _textController.clear();
      
      // Artificial delay for "processing"
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() => _avatarState = "signing");

      // Call repository (Mock)
      await ref.read(avatarRepositoryProvider).renderSign(text);
      
      if (mounted) {
        setState(() {
          _isRendering = false;
          _avatarState = "idle";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signs Rendered Successfully'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Avatar Translator',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient Background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                   Theme.of(context).colorScheme.primary.withOpacity(0.1),
                   Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),

          // Avatar Mock (Creating depth with layers)
          Positioned.fill(
            top: 50,
            child: Align(
              alignment: Alignment.center,
              child: Image.network(
                'https://cdn3d.iconscout.com/3d/premium/thumb/man-standing-5692601-4742295.png', // Stock 3D Avatar
                height: 500,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(width: 50, height: 50, child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => 
                    Icon(PhosphorIcons.robot(), size: 100, color: Colors.grey),
              )
              .animate(target: _avatarState == "signing" ? 1 : 0)
              .shimmer(duration: 1.seconds) // Signing effect
              .animate(target: _avatarState == "listening" ? 1 : 0)
              .scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 500.ms, curve: Curves.easeInOut) // Leaning in
              .animate(target: _avatarState == "thinking" ? 1 : 0)
              .tint(color: Colors.blue.withOpacity(0.3)) // Thinking effect
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(begin: 0, end: -10, duration: 2000.ms, curve: Curves.easeInOutQuad), // Idle breathing
            ),
          ),

          // Floor Shadow
          Positioned(
            bottom: 250,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 200,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    )
                  ],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleX(begin: 1, end: 0.9, duration: 2000.ms),
          ),


          // Bottom Input Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: GlassContainer(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: BorderRadius.circular(30),
              opacity: 0.1,
              blur: 25,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Listening...' : 'Type to sign...', 
                        hintStyle: TextStyle(
                            color: _isListening 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _handleVoiceInput,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          _isListening ? Icons.stop : Icons.mic, 
                          color: Colors.white
                      ),
                    ).animate(target: _isListening ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2), duration: 500.ms, curve: Curves.easeInOut).then().shake(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isRendering 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _submitText,
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 1, end: 0, delay: 300.ms, duration: 500.ms, curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }
}
