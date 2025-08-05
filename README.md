# Smart Trip Planner Flutter

An intelligent travel planning app powered by Google Gemini AI that creates personalized itineraries with real-time validation and interactive follow-up conversations.

## 🎯 Features

- **AI-Powered Itinerary Generation** - Create detailed travel plans using natural language
- **Function Calling & Validation** - Ensures structured, valid JSON responses
- **Interactive Follow-up** - Refine and modify itineraries through conversation
- **Offline Storage** - Save and access your travel plans locally
- **Maps Integration** - Open locations directly in Google Maps
- **Responsive UI** - Beautiful, modern interface with smooth animations

## 📋 Table of Contents

- [Setup](#setup)
- [Architecture](#architecture)
- [Agent Chain Workflow](#agent-chain-workflow)
- [Token Cost Analysis](#token-cost-analysis)
- [Demo](#demo)
- [Contributing](#contributing)

## 🛠️ Setup

### Prerequisites

- Flutter SDK (>=3.0.3)
- Dart SDK (>=3.0.3)
- Firebase CLI
- Google Cloud Project with Gemini API enabled

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/smart_trip_planner_flutter.git
   cd smart_trip_planner_flutter
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Firebase CLI** (if not already installed)
   ```bash
   # macOS
   brew install firebase-cli
   
   # Windows
   npm install -g firebase-tools
   
   # Linux
   curl -sL https://firebase.tools | bash
   ```

4. **Configure Firebase**
   ```bash
   # Login to Firebase
   firebase login
   
   # Initialize Firebase in your project
   firebase init
   
   # Configure FlutterFire
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

5. **Set up Google Cloud Project**
   - Create a new project in [Google Cloud Console](https://console.cloud.google.com/)
   - Configure project using - flutterfire configure-project-your project data-
   - Enable the Gemini API

6. **Configure Firebase AI**
   ```bash
   # Add Firebase AI to your project
   firebase ext:install firebase/firebase-ai
   ```

7. **Run the app**
   ```bash
   flutter run
   ```


## 📊 Architecture

<img width="731" height="646" alt="image" src="https://github.com/user-attachments/assets/2d4365c5-05d5-473e-a4e3-be75e58e06a0" />


### Key Components

- **UI Layer**: Stacked architecture with ViewModels for state management
- **Services Layer**: Isolated processing using Dart isolates for better performance
- **Data Layer**: Hive for local storage, Firebase AI for LLM interactions
- **Validation Layer**: Function calling with JSON schema validation

