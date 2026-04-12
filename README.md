```md
# 🛡️ Medi Locker

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Android](https://img.shields.io/badge/Android-APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![AI](https://img.shields.io/badge/Cura-AI%20Assistant-10B981?style=for-the-badge)
![Security](https://img.shields.io/badge/Security-AES--256-16A34A?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-v1.0.1-7C3AED?style=for-the-badge)

Medi Locker is a modern health records app built with Flutter and Firebase, designed to help users securely manage medical reports, personal health data, and AI-assisted health guidance through **Cura**.

It combines clean mobile-first design, secure document handling, Firebase-powered backend services, and a practical user experience focused on privacy, clarity, and real-life usability.

## 🌐 Live Website

- Website: [medilocker4u.netlify.app](https://medilocker4u.netlify.app/)
- Releases: [GitHub Releases](https://github.com/Stranger4uu/Medi-Locker-App/releases)

## 📦 Download APK

Get the latest Android build from the releases page:

- [Download Latest APK](https://github.com/Stranger4uu/Medi-Locker-App/releases)

## ✨ Highlights

- 🔐 Secure medical record storage flow
- 🤖 Cura AI health assistant
- 📁 Upload, view, download, and manage reports
- 👤 Email/password authentication with profile setup
- 🧾 Export personal data
- 🗑️ Account deletion flow
- ☁️ Firebase backend integration
- 🛠️ Remote-config ready maintenance and update controls
- 📲 Signed release APK support
- 🌙 Modern dark UI with a clean health-focused experience

## 🧠 What Medi Locker Does

Medi Locker helps users keep their health records organized and accessible in one place. Instead of losing prescriptions, reports, and scans across chat apps and downloads folders, users can upload and manage them inside a dedicated health vault.

Alongside that, **Cura** provides AI-assisted health guidance for general questions and basic interpretation support, while maintaining a clear medical disclaimer and escalation-aware behavior.

## 🧩 Core Features

### 🔐 Authentication & Profile
- Email + password sign in
- New user onboarding
- Profile setup flow
- Health details like blood group, allergies, and conditions
- Profile editing and persistence with Firestore

### 📁 Records Management
- Upload reports from file picker, gallery, or camera
- View report details in a clean screen
- Download reports to `Downloads > Medi Locker`
- Delete reports when no longer needed
- Report metadata stored and organized per user

### 🤖 Cura AI Assistant
- AI chat experience inside the app
- Firebase Cloud Functions + Gemini-powered backend
- Friendly fallback handling for server/network failures
- Medical disclaimer and escalation-aware messaging
- Built as a practical assistant, not a replacement for a doctor

### 🛡️ Privacy & User Control
- AES-256 based encrypted upload flow support
- Export user profile, records metadata, and Cura history
- Delete account with linked data cleanup
- Remote config readiness for maintenance and update controls

## 🏗️ Tech Stack

### Frontend
- Flutter
- Dart
- Riverpod
- GoRouter

### Backend & Services
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Functions
- Firebase Remote Config

### AI Layer
- Gemini API
- Cura AI assistant workflow

### Android Release
- Signed APK release pipeline
- GitHub Releases based distribution
- In-app update readiness

## 📱 App Flow

```text
Splash → Onboarding → Login / Register → Profile Setup → Home

Bottom Navigation:
Home | Cura | Records | Profile
```

## 🧭 Architecture Overview

The project follows a modular Flutter structure with clear feature separation:

- `core/` for app-wide router, theme, config, utils, and shared logic
- `features/auth/` for onboarding, login, register, and profile setup
- `features/home/` for dashboard and quick actions
- `features/records/` for upload, listing, detail, download, and delete
- `features/cura/` for AI chat, repository, models, and widgets
- `features/profile/` for account management, editing, export, and delete
- `features/notifications/` for notification support
- `shared/` for reusable widgets and UI building blocks

## 🔒 Security & Privacy

Medi Locker is built around the idea that health data should feel controlled, understandable, and protected.

Current security-focused capabilities include:
- authenticated user-specific data access
- Firebase rules-based protection
- secure record handling flow
- local export support for user ownership
- account deletion support
- signed release build support for trusted APK distribution

## ⚠️ Medical Disclaimer

**Cura AI is not a substitute for professional medical advice, diagnosis, or treatment.**  
It is intended for general guidance and support only. Users should always consult a qualified medical professional for serious or urgent health concerns.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Android Studio / VS Code
- Firebase project
- Android device or emulator

### Setup
```bash
git clone <your-repo-url>
cd Medi-Locker-App/medi_locker
flutter pub get
flutter run
```

### Firebase Setup
Make sure the project is configured with:
- `google-services.json`
- `firebase_options.dart`
- Firebase Authentication
- Firestore
- Storage
- Cloud Functions
- Remote Config

## 🏁 Release Build

To build a signed release APK:

```bash
flutter build apk --release
```

Release signing is configured through:
- `android/key.jks`
- `android/key.properties`

## 🛣️ Roadmap

- stronger report-to-Cura contextual analysis
- richer report summaries
- improved update workflow
- production hardening for wider rollout
- landing page and public release polish
- future platform expansion

## 👨‍💻 Developer

Built by **Yash Saini**

- GitHub: [@Stranger4uu](https://github.com/Stranger4uu)
- LinkedIn: [Yash Saini](https://www.linkedin.com/in/yashhere4uu/)
- X: [@YashHere86](https://x.com/YashHere86)
- Reddit: [u/Stranger4uu](https://www.reddit.com/user/Stranger4uu/)
- Email: [yashsaini4824@gmail.com](mailto:yashsaini4824@gmail.com)

## 📌 Project Status

Medi Locker is an actively evolving product focused on secure health record management and AI-assisted guidance, with core mobile workflows already implemented and release-ready Android builds available through GitHub Releases.
```

For the GitHub **About** section, use this:

```text
A modern Flutter health vault for secure medical records, AI-assisted guidance through Cura, and privacy-first user control.
```
