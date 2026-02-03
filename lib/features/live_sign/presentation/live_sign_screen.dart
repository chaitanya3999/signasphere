import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/services/tts_service.dart';
import '../data/sign_repository.dart';

// Provides the list of available cameras
final camerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});

class LiveSignScreen extends ConsumerStatefulWidget {
  const LiveSignScreen({super.key});

  @override
  ConsumerState<LiveSignScreen> createState() => _LiveSignScreenState();
}

class _LiveSignScreenState extends ConsumerState<LiveSignScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await ref.read(camerasProvider.future);
      if (cameras.isEmpty) return;

      // Use front camera if available
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final signStreamValue = ref.watch(recognizedSignStreamProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.white),
            onPressed: () {
               // Demo: Speak current text
               if (signStreamValue.hasValue && signStreamValue.value != null) {
                 ref.read(ttsServiceProvider).speak(signStreamValue.value!);
               }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Feed or Placeholder
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? 1, 
                    height: _cameraController!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_cameraController!)
                  ),
                ),
            )
          else
            Image.network(
              'https://images.unsplash.com/photo-1596742578443-7682af5251be', 
              fit: BoxFit.cover,
            ),
            
           // Tracking Overlay (Animated Boxes)
           if (_isCameraInitialized)
             _buildTrackingOverlay(),
          
          // Slight blur overlay for style
          const GlassContainer(
            borderRadius: BorderRadius.zero,
            blur: 0, 
            opacity: 0.0, 
            child: SizedBox.shrink(),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // Floating Transcript Panel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassContainer(
                    blur: 20,
                    opacity: 0.15,
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DETECTED SPEECH',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Icon(PhosphorIcons.speakerHigh(PhosphorIconsStyle.fill), color: Colors.white70, size: 16),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          signStreamValue.when(
                            data: (data) => data,
                            error: (_, __) => "Start signing...",
                            loading: () => "Listening...",
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ).animate(key: ValueKey(signStreamValue.asData?.value)).fadeIn(),
                         const SizedBox(height: 8),
                        Text(
                          "Confidence: ${_isRecording ? '98%' : 'Idle'}",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.greenAccent,
                              ),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms),

                const Spacer(flex: 1),

                // Bottom Control Dock
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlBubble(
                        icon: PhosphorIcons.keyboard(PhosphorIconsStyle.fill),
                        onTap: () {},
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () => setState(() => _isRecording = !_isRecording),
                        child: GlassContainer(
                          width: 80,
                          height: 80,
                          borderRadius: BorderRadius.circular(40),
                          opacity: 0.2,
                          color: _isRecording ? Colors.red : Colors.white,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                          child: Center(
                            child: Icon(
                              _isRecording ? PhosphorIcons.stop(PhosphorIconsStyle.fill) : PhosphorIcons.record(PhosphorIconsStyle.fill),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ).animate(target: _isRecording ? 1 : 0).shimmer(duration: 2000.ms),
                      ),
                      const SizedBox(width: 24),
                      _ControlBubble(
                        icon: PhosphorIcons.translate(PhosphorIconsStyle.fill),
                        onTap: () {
                           if (signStreamValue.hasValue && signStreamValue.value != null) {
                             ref.read(ttsServiceProvider).speak(signStreamValue.value!);
                           }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrackingOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds),
    );
  }
}

class _ControlBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlBubble({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        width: 50,
        height: 50,
        borderRadius: BorderRadius.circular(25),
        opacity: 0.15,
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
