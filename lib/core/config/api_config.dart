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

  /// Puter.js SDK URL (must be injected in web/index.html)
  static const String puterJsSdkUrl = "https://js.puter.com/v2/";

  /// Puter API base URL (Required for Mobile/Desktop REST calls)
  static const String puterBaseUrl = 'https://api.puter.com';

  /// Puter auth token — get this from your Puter account console for Mobile/Desktop.
  /// for Web, Puter.js handles auth/anonymous access automatically.
  static const String puterAuthToken = 'YOUR_PUTER_AUTH_TOKEN';

  /// Gemini model name (exactly as mentioned in Puter docs)
  /// Recommended fast free model
  static const String geminiModel = "gemini-3-flash-preview";

  /// Alternative free model (also valid)
  static const String geminiModelAlt = "gemini-2.0-flash-exp:free";

  /// Maximum number of context messages to send
  static const int maxContextMessages = 10;
  
  /// API request timeout in seconds
  static const int requestTimeoutSeconds = 15;

  /// Maximum input length allowed
  static const int maxInputLength = 500;

  /// System prompt defining Signasphere AI personality for non-verbal kids
  static const String systemPrompt = '''
You are Signasphere AI, a gentle and supportive assistant for non-verbal children.

Your goal:
Help children communicate needs, feelings, and requests in very simple language.

Rules:
1. USE VERY SIMPLE WORDS.
2. Use SHORT SENTENCES (3 to 6 words).
3. Be KIND and CALM.
4. If the child seems scared, hurt, or unsafe, tell them:
   "Please show an adult now."
5. If asked to translate to sign keywords, break into sign-friendly format:
   Example: "I am hungry" -> "ME - HUNGRY - EAT"
6. Ask simple follow-up questions if unclear:
   Example: "Where?" or "Show again?"
7. Avoid medical/legal advice. Always recommend adult help.
8. Do NOT use complex grammar.
''';

  /// Standard ChatGPT-like system prompt for general conversation ("GPT Mode")
  static const String systemPromptGpt = '''
You are a helpful and knowledgeable AI assistant.
Answer the user's questions clearly and concisely.
You can help with a wide range of topics including learning, general knowledge, and casual conversation.
Be polite and engaging.
''';
}