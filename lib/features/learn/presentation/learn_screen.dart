import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../domain/quiz_models.dart';
import 'learn_controller.dart';
import 'quiz_session_screen.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  void _startQuizSession(BuildContext context, WidgetRef ref, QuizType? type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizSessionScreen(quizType: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnControllerProvider);

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'Learn Signs',
        leadingIcon: Icons.arrow_back_ios_new,
      ),
      body: Stack(
        children: [
          // Background Gradient
           Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Colors.blueAccent.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
            children: [
              // ----------------------------------------------------
              // Section 1: Stats Panel
              // ----------------------------------------------------
              GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                opacity: 0.1,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'Level', value: '${state.level}', icon: Icons.military_tech, color: Colors.amber),
                        _StatItem(label: 'XP', value: '${state.xp}', icon: Icons.star, color: Colors.orange),
                        _StatItem(label: 'Streak', value: '${state.streak}', icon: Icons.local_fire_department, color: Colors.redAccent),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 32),
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'Quizzes', value: '${state.totalQuizzesPlayed}', icon: Icons.quiz, color: Colors.blueAccent),
                        _StatItem(label: 'Accuracy', value: '${(state.accuracy * 100).toStringAsFixed(0)}%', icon: Icons.track_changes, color: Colors.green),
                        _StatItem(label: 'Known', value: '${state.knownWordsCount}', icon: Icons.bookmark, color: Colors.purpleAccent),
                      ],
                    ),
                  ],
                ),
              ).animate().slideY(begin: -0.2, end: 0).fadeIn(),

              const SizedBox(height: 32),
              
              const Text('Start Learning', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // Section 2: Quiz Type Cards
              // ----------------------------------------------------

              // 1. Full Test Mode (Hero Card)
              GestureDetector(
                onTap: () => _startQuizSession(context, ref, null), // null means Full Test
                child: GlassContainer(
                  height: 120,
                  opacity: 0.15,
                  gradient: const LinearGradient(colors: [Colors.indigoAccent, Colors.deepPurpleAccent]),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                         child: Icon(PhosphorIcons.exam(PhosphorIconsStyle.fill), size: 40, color: Colors.white),
                       ),
                       const SizedBox(width: 20),
                       const Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text("Full Assessment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text("Mix all quiz types", style: TextStyle(fontSize: 12, color: Colors.white70)),
                         ],
                       ),
                       const Spacer(),
                       const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                     ],
                  ),
                ),
              ).animate().fadeIn().scale().moveX(),
              
              const SizedBox(height: 16),

              // 2. Guess the Word
              _QuizTypeCard(
                title: "Guess the Word",
                subtitle: "Identify the sign from options",
                icon: PhosphorIcons.textAa(PhosphorIconsStyle.fill),
                color: Colors.pinkAccent,
                onTap: () => _startQuizSession(context, ref, QuizType.guessWord),
              ),

              // 3. Select Correct Sign
              _QuizTypeCard(
                title: "Select Correct Sign",
                subtitle: "Match text to the right image",
                icon: PhosphorIcons.image(PhosphorIconsStyle.fill),
                color: Colors.cyanAccent,
                onTap: () => _startQuizSession(context, ref, QuizType.selectSign),
              ),

              // 4. Match Pairs
              _QuizTypeCard(
                title: "Match the Pair",
                subtitle: "Connect words with signs",
                icon: PhosphorIcons.link(PhosphorIconsStyle.fill),
                color: Colors.tealAccent,
                onTap: () => _startQuizSession(context, ref, QuizType.matchPair),
              ),

               // 5. Flashcards
              _QuizTypeCard(
                title: "Flashcards",
                subtitle: "Swipe to learn new signs",
                icon: PhosphorIcons.cards(PhosphorIconsStyle.fill),
                color: Colors.orangeAccent,
                onTap: () => _startQuizSession(context, ref, QuizType.flashcard),
              ),
            ],
          ),
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
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }
}

class _QuizTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuizTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          height: 90,
          opacity: 0.05,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GlassContainer(
                width: 30, height: 30, borderRadius: BorderRadius.circular(10), opacity: 0.1,
                child: const Icon(Icons.play_arrow, size: 16),
              )
            ],
          ),
        ).animate().fadeIn().slideX(),
      ),
    );
  }
}
