import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/theme/theme_controller.dart';

final learnProgressProvider = NotifierProvider<LearnProgressNotifier, Map<String, double>>(LearnProgressNotifier.new);

class LearnProgressNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return {
      "basics": prefs.getDouble("progress_basics") ?? 0.0,
      "greetings": prefs.getDouble("progress_greetings") ?? 0.0,
      "emergency": prefs.getDouble("progress_emergency") ?? 0.0,
    };
  }

  Future<void> updateProgress(String moduleId, double value) async {
    state = {...state, moduleId: value};
    final prefs = ref.read(sharedPreferencesProvider); // Read directly for side effects
    await prefs.setDouble("progress_$moduleId", value);
  }
}

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(learnProgressProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: const Text('Learn Signs'),
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
                  Colors.pinkAccent.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
            children: [
              // Statistics Header
              GlassContainer(
                padding: const EdgeInsets.all(20),
                opacity: 0.1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(label: 'Streak', value: '3 Days', icon: Icons.local_fire_department, color: Colors.orange),
                    _StatItem(label: 'XP', value: '450', icon: Icons.star, color: Colors.yellow),
                    _StatItem(label: 'Level', value: '2', icon: Icons.military_tech, color: Colors.green),
                  ],
                ),
              ).animate().slideY(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              const Text('Modules', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _ModuleCard(
                title: "Basics: Alphabet",
                subtitle: "Learn A-Z handshapes",
                progress: progress["basics"] ?? 0.0,
                color: Colors.purpleAccent,
                icon: PhosphorIcons.textAa(PhosphorIconsStyle.fill),
                delay: 200,
                onTap: () => _showQuiz(context, ref, "basics", "Alphabet Quiz", ["A", "B", "C"], "A"),
              ),
              const SizedBox(height: 16),
              _ModuleCard(
                title: "Greetings",
                subtitle: "Hello, Goodbye, Thank you",
                progress: progress["greetings"] ?? 0.0,
                color: Colors.blueAccent,
                icon: PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill),
                delay: 300,
                onTap: () => _showQuiz(context, ref, "greetings", "Greetings Quiz", ["Hello", "Bye", "Thanks"], "Hello"),
              ),
              const SizedBox(height: 16),
               _ModuleCard(
                title: "Emergency Signs",
                subtitle: "Help, Doctor, Pain",
                progress: progress["emergency"] ?? 0.0,
                color: Colors.redAccent,
                icon: PhosphorIcons.siren(PhosphorIconsStyle.fill),
                delay: 400,
                onTap: () => _showQuiz(context, ref, "emergency", "Emergency Quiz", ["Help", "Doctor", "Fire"], "Help"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuiz(BuildContext context, WidgetRef ref, String moduleId, String title, List<String> options, String correctAnswer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => _QuizSheet(
        moduleId: moduleId, 
        title: title, 
        options: options, 
        correctAnswer: correctAnswer,
        onComplete: (score) {
           ref.read(learnProgressProvider.notifier).updateProgress(moduleId, score);
        },
      ),
    );
  }
}

class _QuizSheet extends StatefulWidget {
  final String moduleId;
  final String title;
  final List<String> options;
  final String correctAnswer;
  final Function(double) onComplete;

  const _QuizSheet({
    required this.moduleId, 
    required this.title, 
    required this.options, 
    required this.correctAnswer,
    required this.onComplete,
  });

  @override
  State<_QuizSheet> createState() => _QuizSheetState();
}

class _QuizSheetState extends State<_QuizSheet> {
  String? _selected;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
     return Container(
       height: 500,
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
         color: Theme.of(context).scaffoldBackgroundColor,
         borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
            Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 32),
            GlassContainer(
              height: 150,
              opacity: 0.1,
              child: Center(
                child: Icon(PhosphorIcons.handWaving(PhosphorIconsStyle.fill), size: 80, color: Theme.of(context).primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text("What does this sign mean?", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            ...widget.options.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selected == opt 
                      ? (opt == widget.correctAnswer ? Colors.green : Colors.red) 
                      : Theme.of(context).colorScheme.surface,
                  foregroundColor: _selected == opt ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _completed ? null : () {
                  setState(() {
                    _selected = opt;
                    _completed = true;
                  });
                  if (opt == widget.correctAnswer) {
                     Future.delayed(const Duration(seconds: 1), () {
                       widget.onComplete(1.0); // 100% progress
                       Navigator.pop(context);
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Correct! +50 XP")));
                     });
                  } else {
                     Future.delayed(const Duration(seconds: 1), () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Try Again!")));
                     });
                  }
                },
                child: Text(opt),
              ),
            )).toList(),
         ],
       ),
     );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final Color color;
  final IconData icon;
  final int delay;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
    required this.icon,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        height: 100,
        opacity: 0.05,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(progress >= 1.0 ? Icons.check_circle : Icons.play_circle_fill, 
                color: progress >= 1.0 ? Colors.green : color.withOpacity(0.5), size: 32),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms).slideX(),
    );
  }
}
