# Bidirectional Sign Language Translator

A Flutter application bridging the communication gap between deaf and hearing users through real-time sign language translation and a 3D avatar inteface.

## 🌟 Key Features
- **Project Name:** Signasphere
- **Liquid Glass UI:** Modern, translucent, accessible aesthetics.
- **Live Sign → Speech:** Real-time sign language recognition (Simulated).
- **Text → 3D Avatar:** Text-to-Sign translation using a 3D avatar (Simulated).
- **Conversation Mode:** Two-way real-time communication interface.
- **Learn Mode:** Gamified sign language lessons with progress tracking.

## 🏗 Architecture
- **Framework:** Flutter (Cross-platform)
- **State Management:** Riverpod (Providers, Consumers)
- **Navigation:** GoRouter (Shell routes, declarative routing)
- **Design System:** Custom "Liquid Glass" theme with `GlassContainer` widgets.
- **Separation of Concerns:** Feature-first folder structure (`lib/features/`).

## 🚀 Getting Started

1. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the App:**
   ```bash
   flutter run
   ```

## 📂 Project Structure
```
lib/
├── core/
│   ├── router/         # GoRouter configuration
│   ├── services/       # Abstract service interfaces
│   ├── theme/          # AppTheme and Color Palettes
│   └── widgets/        # Reusable components (GlassContainer)
├── features/
│   ├── home/           # Dashboard & Splash
│   ├── live_sign/      # Camera & Recognition Logic
│   ├── avatar/         # Avatar Visualization
│   ├── conversation/   # Chat Interface
│   ├── learn/          # Learning Modules
│   └── settings/       # Profile & App Settings
└── main.dart           # Entry point
```

## 🎨 Design Philosophy
The app uses a "Liquid Glass" design language characterized by:
- Frosted glass surfaces (`BackdropFilter`)
- Vibrant, accessible color gradients
- Smooth physics-based animations (`flutter_animate`)
- Floating UI elements with ample whitespace

## 🎬 Demo Flow (Hackathon Guide)
1. **Splash & Home**: Launch app. Show the "System Online" status and Smooth animations.
2. **Settings (Theming)**: Go to Settings -> Appearance. Toggle **Dark Mode** to show the liquid glass adapting instantly.
3. **Live Sign**: Open "Sign" tab. Show the simulated camera feed and real-time transcript confidence.
4. **Avatar**: Open "Avatar" tab. Type "Hello World" to trigger the avatar animation (simulated).
5. **Conversation**: key feature for 2-way communication.
6. **Learn**: Show the gamification elements.

## 🎨 Why "Liquid Glass"?
Glassmorphism was chosen to represent **transparency** and **clarity**—core values of communication. The frosted effect allows the UI to float above the "real world" (camera feed/avatar space) without blocking context, making it the perfect accessible overlay for an AR-ready sign language tool.

## 🔮 Future Roadmap (Hackathon)
- Integrate MediaPipe/TFLite for real-time hand tracking.
- Connect to Unity/Rive for advanced 3D avatar control.
- Implement specialized modes (Hospital, Emergency) using the quick tiles.
