import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/services/feedback_service.dart';
import '../domain/quiz_models.dart';
import 'quiz_session_controller.dart';

// -----------------------------------------------------------------------------
// Guess Word Widget (Image -> 4 Text)
// -----------------------------------------------------------------------------
class GuessWordWidget extends ConsumerWidget {
  final GuessWordQuestion question;

  const GuessWordWidget({super.key, required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizSessionControllerProvider);
    
    return Column(
      children: [
        GlassContainer(
          height: 220,
          width: double.infinity,
          opacity: 0.1,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(question.imagePath, fit: BoxFit.contain,
                errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text("What does this sign mean?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        
        ...question.options.map((option) {
           final isSelected = state.isAnswered; // Disable interaction if answered
           final isCorrect = option == question.correctLabel;
           
           // Determine Color
           Color? btnColor;
           if (state.isAnswered) {
             if (isCorrect) btnColor = Colors.green.withOpacity(0.8);
           }

           return Padding(
             padding: const EdgeInsets.only(bottom: 12),
             child: GlassButton(
               onPressed: isSelected ? null : () {
                 ref.read(quizSessionControllerProvider.notifier).submitAnswer(isCorrect);
               },
               color: btnColor,
               shouldAnimate: false,
               child: Text(option, style: const TextStyle(fontSize: 16)),
             ),
           );
        }).toList()
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Select Sign Widget (Text -> 4 Images)
// -----------------------------------------------------------------------------
class SelectSignWidget extends ConsumerStatefulWidget {
  final SelectSignQuestion question;

  const SelectSignWidget({super.key, required this.question});

  @override
  ConsumerState<SelectSignWidget> createState() => _SelectSignWidgetState();
}

class _SelectSignWidgetState extends ConsumerState<SelectSignWidget> {
  String? _selectedPath;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizSessionControllerProvider);

    return Column(
      children: [
        Text(widget.question.promptLabel.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Select the correct sign", style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 20),

        GridView.count(
           shrinkWrap: true,
           physics: const NeverScrollableScrollPhysics(),
           crossAxisCount: 2,
           mainAxisSpacing: 12,
           crossAxisSpacing: 12,
           childAspectRatio: 1.0, 
           children: widget.question.optionImagePaths.map((path) {
              final isCorrect = path == widget.question.correctImagePath;
              final isAnswered = state.isAnswered;
              final wasSelected = _selectedPath == path;
              
              // Determine visual state
              Color? containerColor;
              BoxBorder? containerBorder;
              double containerOpacity = 0.1;

              if (isAnswered) {
                if (isCorrect) {
                  containerColor = Colors.green;
                  containerBorder = Border.all(color: Colors.green, width: 3);
                  containerOpacity = 0.3;
                } else if (wasSelected && !isCorrect) {
                  containerColor = Colors.red;
                  containerBorder = Border.all(color: Colors.red, width: 3);
                  containerOpacity = 0.3;
                }
              }
              
              return GestureDetector(
                onTap: isAnswered ? null : () {
                  setState(() => _selectedPath = path);
                  ref.read(quizSessionControllerProvider.notifier).submitAnswer(isCorrect);
                },
                child: GlassContainer(
                   opacity: containerOpacity,
                   color: containerColor,
                   border: containerBorder,
                   borderRadius: BorderRadius.circular(20),
                   child: Padding(
                     padding: const EdgeInsets.all(12.0),
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(12),
                       child: Image.asset(path, fit: BoxFit.contain,
                         errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 40, color: Colors.grey)),
                     ),
                   ),
                ),
              );
           }).toList(),
        )
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Match Pair Widget
// -----------------------------------------------------------------------------
class MatchPairWidget extends ConsumerStatefulWidget {
  final MatchPairQuestion question;

  const MatchPairWidget({super.key, required this.question});

  @override
  ConsumerState<MatchPairWidget> createState() => _MatchPairWidgetState();
}

class _MatchPairWidgetState extends ConsumerState<MatchPairWidget> {
  String? selectedLabel;
  String? selectedImage;
  
  // Use a Set to store matched keys (labels)
  final Set<String> matchedLabels = {};
  
  // Local shuffled lists
  late List<String> shuffledLabels;
  late List<String> shuffledImages;

  // Error state for shaking/red flash
  bool isError = false;

  @override
  void initState() {
    super.initState();
    // Shuffle only on init
    shuffledLabels = widget.question.pairs.keys.toList()..shuffle();
    shuffledImages = widget.question.pairs.values.toList()..shuffle();
  }

  void _handleSelection(String type, String value) {
    if (isError) return; // Block input during error animation

    setState(() {
      if (type == 'label') {
        if (selectedLabel == value) selectedLabel = null; // Toggle off
        else selectedLabel = value;
      } else {
        if (selectedImage == value) selectedImage = null; // Toggle off
        else selectedImage = value;
      }
    });

    _checkMatch();
  }

  void _checkMatch() {
    if (selectedLabel != null && selectedImage != null) {
      // Both selected, check correctness
      final correctImage = widget.question.pairs[selectedLabel];
      
      if (correctImage == selectedImage) {
        // MATCH!
        FeedbackService().playCorrect();
        
        setState(() {
          matchedLabels.add(selectedLabel!);
          selectedLabel = null;
          selectedImage = null;
        });
        
        // Check if all matched
        if (matchedLabels.length == widget.question.pairs.length) {
           Future.delayed(const Duration(milliseconds: 500), () {
             if (mounted) {
               ref.read(quizSessionControllerProvider.notifier).submitAnswer(true);
             }
           });
        }
      } else {
        // MISMATCH
        FeedbackService().playWrong();
        setState(() {
          isError = true;
        });
        
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              isError = false;
              selectedLabel = null;
              selectedImage = null;
            });
          }
        });
      }
    } else {
       // Only one selected, play light haptic
       FeedbackService().hapticSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = shuffledLabels.length;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Labels Column
        Expanded(
          child: Column(
            children: List.generate(itemCount, (i) {
               final label = shuffledLabels[i];
               final isMatched = matchedLabels.contains(label);
               final isSelected = selectedLabel == label;
               final isErrorState = isError && isSelected;
               
               return Padding(
                 padding: EdgeInsets.only(bottom: i < itemCount - 1 ? 12 : 0),
                 child: GestureDetector(
                   onTap: isMatched ? null : () => _handleSelection('label', label),
                   child: GlassContainer(
                     height: 90,
                     opacity: isMatched ? 0.05 : (isSelected ? 0.2 : 0.1),
                     color: isErrorState ? Colors.red.withOpacity(0.5) : (isSelected ? Colors.blueAccent : (isMatched ? Colors.green : null)),
                     border: isSelected ? Border.all(color: isErrorState ? Colors.red : Colors.blueAccent, width: 2) : (isMatched ? Border.all(color: Colors.green.withOpacity(0.5), width: 2) : null),
                     borderRadius: BorderRadius.circular(16),
                     child: Center(child: Text(label, textAlign: TextAlign.center, style: TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 16,
                       color: isMatched ? Colors.green : (isSelected ? Colors.white : null)
                     ))),
                   )
                   .animate(target: isErrorState ? 1 : 0)
                   .shake(hz: 4, curve: Curves.easeInOutCubic)
                   .tint(color: Colors.red, duration: 300.ms),
                 ),
               );
            }),
          ),
        ),
        const SizedBox(width: 12),
        
        // Images Column
        Expanded(
          child: Column(
            children: List.generate(itemCount, (i) {
               final img = shuffledImages[i];
               final labelForImg = widget.question.pairs.entries.firstWhere((e) => e.value == img).key;
               final isMatched = matchedLabels.contains(labelForImg);
               final isSelected = selectedImage == img;
               final isErrorState = isError && isSelected;

               return Padding(
                 padding: EdgeInsets.only(bottom: i < itemCount - 1 ? 12 : 0),
                 child: GestureDetector(
                   onTap: isMatched ? null : () => _handleSelection('image', img),
                   child: GlassContainer(
                     height: 90,
                     opacity: isMatched ? 0.05 : (isSelected ? 0.2 : 0.1),
                     color: isErrorState ? Colors.red.withOpacity(0.5) : (isSelected ? Colors.blueAccent : (isMatched ? Colors.green : null)),
                     border: isSelected ? Border.all(color: isErrorState ? Colors.red : Colors.blueAccent, width: 2) : (isMatched ? Border.all(color: Colors.green.withOpacity(0.5), width: 2) : null),
                     borderRadius: BorderRadius.circular(16),
                     child: Padding(
                       padding: const EdgeInsets.all(8.0),
                       child: ClipRRect(
                         borderRadius: BorderRadius.circular(10),
                         child: Image.asset(img, fit: BoxFit.contain,
                           errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 30, color: Colors.grey)),
                       ),
                     ),
                   )
                   .animate(target: isErrorState ? 1 : 0)
                   .shake(hz: 4, curve: Curves.easeInOutCubic)
                   .tint(color: Colors.red, duration: 300.ms),
                 ),
               );
            }),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Flashcard Widget
// -----------------------------------------------------------------------------
class FlashcardWidget extends ConsumerStatefulWidget {
  final FlashcardQuestion question;

  const FlashcardWidget({super.key, required this.question});

  @override
  ConsumerState<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends ConsumerState<FlashcardWidget> {
  bool _isFlipped = false;

  void _flipCard() {
    FeedbackService().hapticSelection();
    setState(() => _isFlipped = !_isFlipped);
  }

  void _markAsKnown() {
    FeedbackService().playCorrect();
    // Ideally update persistent stats here via LearnController
    // ref.read(learnControllerProvider.notifier).markWordAsKnown(widget.question.label);
    
    // Proceed to next
    ref.read(quizSessionControllerProvider.notifier).submitAnswer(true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 400,
          child: GestureDetector(
            onTap: _flipCard,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, anime) => ScaleTransition(scale: anime, child: child),
              child: _isFlipped ? _buildBack() : _buildFront(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text("Tap card to flip", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        GlassButton(
          onPressed: _markAsKnown,
          color: Colors.purpleAccent,
          gradient: const LinearGradient(colors: [Colors.purpleAccent, Colors.deepPurple]), 
          shouldAnimate: false,
          child: const Text("Mark as Known", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFront() {
    return GlassContainer(
      key: const ValueKey("front"),
      width: double.infinity,
      height: 400, // Matches container height
      opacity: 0.1,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Image.asset(widget.question.imagePath, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return GlassContainer(
      key: const ValueKey("back"),
      width: double.infinity,
      height: 400, // Matches container height
      opacity: 0.15,
      color: Colors.deepPurple,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.question.label.toUpperCase(), 
               style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Container(height: 2, width: 50, color: Colors.white54),
          const SizedBox(height: 16),
          const Text("Sign Language", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
