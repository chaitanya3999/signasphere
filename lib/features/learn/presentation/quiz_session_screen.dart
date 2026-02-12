import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_button.dart';
import '../domain/quiz_models.dart';
import 'quiz_session_controller.dart';
import 'quiz_widgets.dart';
import 'learn_controller.dart';

class QuizSessionScreen extends ConsumerStatefulWidget {
  final QuizType? quizType; // Null means Full Test
  
  const QuizSessionScreen({super.key, required this.quizType});

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (widget.quizType == null) {
          ref.read(quizSessionControllerProvider.notifier).startFullTest(15);
       } else {
          ref.read(quizSessionControllerProvider.notifier).startQuiz(widget.quizType!, 10);
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizSessionControllerProvider);
    
    if (state.questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.isFinished) {
      return _QuizSummaryView(
        score: state.score, 
        total: state.questions.length,
        isTest: widget.quizType == null,
      );
    }

    final question = state.questions[state.currentIndex];
    final double progress = (state.currentIndex + 1) / state.questions.length;
    final String title = widget.quizType == null 
        ? "Full Assessment" 
        : _getQuizTitle(widget.quizType!);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: title,
        leadingIcon: Icons.close,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Colors.deepPurpleAccent.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subtitle & Mode Chip
                Text(
                  _getQuizSubtitle(widget.quizType),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),

                // Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),

                // Question Counter
                Text(
                  "Question ${state.currentIndex + 1}/${state.questions.length}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 20),

                // Question Content
                _buildQuestionView(question),

                const SizedBox(height: 20),

                // Next Button (only when answered)
                if (state.isAnswered || question.type == QuizType.flashcard)
                  GlassButton(
                    onPressed: () => ref.read(quizSessionControllerProvider.notifier).nextQuestion(),
                    color: (state.isCorrect || question.type == QuizType.flashcard) ? Colors.green : Colors.orange,
                    shouldAnimate: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          (state.isCorrect || question.type == QuizType.flashcard) ? Icons.check : Icons.arrow_forward,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (state.isCorrect || question.type == QuizType.flashcard) ? "Next" : "Got it, Next",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _getQuizSubtitle(QuizType? type) {
    if (type == null) return "Test your knowledge across all modes";
    switch(type) {
      case QuizType.guessWord: return "Identify the meaning of the sign";
      case QuizType.selectSign: return "Choose the correct sign for the word";
      case QuizType.matchPair: return "Match words with their signs";
      case QuizType.flashcard: return "Flip to reveal and learn";
    }
  }

  String _getQuizTitle(QuizType type) {
    switch(type) {
      case QuizType.guessWord: return "Guess the Word";
      case QuizType.selectSign: return "Select Correct Sign";
      case QuizType.matchPair: return "Match Pairs";
      case QuizType.flashcard: return "Flashcards";
      default: return "Quiz";
    }
  }

  Widget _buildQuestionView(QuizQuestion question) {
     switch (question.type) {
       case QuizType.guessWord:
         return GuessWordWidget(question: question as GuessWordQuestion, key: ValueKey(question.id));
       case QuizType.selectSign:
         return SelectSignWidget(question: question as SelectSignQuestion, key: ValueKey(question.id));
       case QuizType.matchPair:
         return MatchPairWidget(question: question as MatchPairQuestion, key: ValueKey(question.id));
       case QuizType.flashcard:
         return FlashcardWidget(question: question as FlashcardQuestion, key: ValueKey(question.id));
       default:
         return const Center(child: Text("Unknown Type"));
     }
  }
}

class _QuizSummaryView extends ConsumerWidget {
  final int score;
  final int total;
  final bool isTest;

  const _QuizSummaryView({required this.score, required this.total, required this.isTest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final xpEarned = (score * 10) + 50;
       
       ref.read(learnControllerProvider.notifier).recordQuizSession(
         xpEarned: xpEarned,
         correctCount: score,
         totalQuestions: total
       );
    });

    final percentage = score / total;
    String message = "Keep practicing!";
    if (percentage > 0.8) message = "Outstanding Performance!";
    else if (percentage > 0.5) message = "Good Job!";

    return Scaffold(
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
       body: Center(
         child: GlassContainer(
           margin: const EdgeInsets.all(30),
           padding: const EdgeInsets.all(30),
           child: SingleChildScrollView(
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(
                   percentage > 0.8 ? PhosphorIcons.trophy(PhosphorIconsStyle.fill) : PhosphorIcons.medal(PhosphorIconsStyle.fill),
                   size: 80,
                   color: percentage > 0.8 ? Colors.amber : Colors.blueAccent,
                 ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                 
                 const SizedBox(height: 24),
                 Text(message, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                 const SizedBox(height: 16),
                 
                 Text(isTest ? "Assessment Result" : "Quiz Complete", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                 const SizedBox(height: 8),
                 Text("$score / $total", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                 
                 const SizedBox(height: 32),
                 GlassButton(
                   onPressed: () => Navigator.pop(context),
                   color: Theme.of(context).primaryColor,
                   child: const Text("Finish", style: TextStyle(color: Colors.white)),
                 )
               ],
             ),
           ),
         ),
       ),
    );
  }
}
