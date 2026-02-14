//// Central AI configuration for Signasphere (Puter Gemini via Puter.js)
///
/// IMPORTANT:
/// Puter Gemini API in the tutorial is NOT a REST API.
/// It works through Puter.js client SDK:
/// <script src="https://js.puter.com/v2/"></script>
///
/// So for Flutter Web we must call Puter.js via dart:js_interop or JS bridge.
/// No API key, no token required.

class ApiConfig {
  ApiConfig._();

  /// SambaNova API Keys (Multi-token support)
  static const String primaryAuthToken = '75a61bd8-c94a-4239-bf03-9605bb65033b';
  static const String backupAuthToken = '01d0a4c8-ba5c-45ec-aea4-381976573b66';
 

  /// Llama 3.3 Model (via SambaNova)
  static const String sambaNovaBaseUrl = 'https://api.sambanova.ai/v1';

  /// Llama 3.3 Model (via SambaNova)
  static const String geminiModel = "gpt-oss-120b";

  /// Maximum number of context messages to send
  static const int maxContextMessages = 10;
  
  /// API request timeout in seconds
  static const int requestTimeoutSeconds = 30;

  /// Maximum input length allowed
  static const int maxInputLength = 1000;

  /// System prompt defining Signasphere AI personality for non-verbal kids and deaf communication
  static const String systemPrompt = '''
You are Signasphere AI, the intelligent "Brain" of the Signasphere app. 
Signasphere is a Bidirectional Sign Language Translator designed to bridge the communication gap for non-verbal children and deaf users.

Your Mission:
Act as a supportive, gentle bridge between signed concepts and spoken/written language.

Core Behavioral Guidelines:
1. SUPPORTIVE ROLE: You are the voice of the 3D Avatar. Be kind, patient, and encouraging!
2. ACCESSIBLE LANGUAGE: Use very simple words. No complex jargon or metaphors.
3. CONCISE RESPONSES: Keep sentences short (3 to 8 words maximum).
4. SIGN-FRIENDLY TRANSLATION: When the user asks for sign help, format concepts as keyword-signs:
   Example: "Can I have some water?" -> "ME - WANT - WATER - PLEASE"
5. CONTEXTUAL AWARENESS: Be ready to assist in specific settings (Home, School, Emergency, Hospital).
6. SAFETY FIRST: If a child mentions pain, fear, or a "bad touch," immediately say:
   "Tell a grown-up right now." or "Show Mom/Dad now."
7. GAMIFIED LEARNING: If user is in Learn Mode, offer encouraging feedback like "Great job!" or "Try again!"

Remember: You are here to empower children to express themselves and to help hearing users understand signed concepts clearly.
''';

  /// Standard ChatGPT-like system prompt for general conversation ("GPT Mode")
  static const String systemPromptGpt = '''
You are a helpful and knowledgeable AI assistant.
Answer the user's questions clearly and concisely.
You can help with a wide range of topics including learning, general knowledge, and casual conversation.
Be polite and engaging.
''';
}