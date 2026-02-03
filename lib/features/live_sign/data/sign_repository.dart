import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class SignRepository {
  Stream<String> getRecognizedSignStream();
}

class MockSignRepository implements SignRepository {
  @override
  Stream<String> getRecognizedSignStream() async* {
    final sentences = [
      ["Hello", "Hello world"],
      ["Nice", "Nice to", "Nice to meet", "Nice to meet you"],
      ["Can", "Can you", "Can you help", "Can you help me?"],
      ["Where", "Where is", "Where is the", "Where is the hospital?"],
      ["I", "I am", "I am learning", "I am learning ASL"],
    ];
    
    int sentenceIndex = 0;
    
    while (true) {
      await Future.delayed(const Duration(seconds: 2)); // Waiting for "input"
      
      // Pick a progressive sentence
      final progression = sentences[sentenceIndex % sentences.length];
      
      for (final part in progression) {
         await Future.delayed(const Duration(milliseconds: 800)); // Typing effect
         yield part;
      }
      
      sentenceIndex++;
      await Future.delayed(const Duration(seconds: 3)); // Pause between sentences
    }
  }
}

final signRepositoryProvider = Provider<SignRepository>((ref) {
  return MockSignRepository();
});

final recognizedSignStreamProvider = StreamProvider<String>((ref) {
  final repository = ref.watch(signRepositoryProvider);
  return repository.getRecognizedSignStream();
});
