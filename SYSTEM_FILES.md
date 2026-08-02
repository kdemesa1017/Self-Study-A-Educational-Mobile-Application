# System File Architecture & Component Guide

This document provides a comprehensive overview of all necessary files and directories within the **Self Study Application** codebase. It outlines the responsibilities, dependencies, and relationships of each file across the project hierarchy.

---

## 1. Executive Summary & Architecture Overview

The Self Study application is a cross-platform mobile and web study app built with **Flutter (Dart)**. It uses **Riverpod** for reactive state management, **Cloud Firestore & Firebase Auth** for cloud backend infrastructure, **Hive** for local offline persistence and caching, and **Google Gemini AI** for automated quiz generation.

```
┌────────────────────────────────────────────────────────────────────────┐
│                          UI Layer (Screens & Widgets)                  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ consumes
┌───────────────────────────────────▼────────────────────────────────────┐
│                    State Management (Riverpod Providers)               │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ calls
┌───────────────────────────────────▼────────────────────────────────────┐
│                             Services Layer                             │
│   (AuthService, QuizService, GeminiService, LocalStores, SyncService)  │
└──────────┬────────────────────────┬─────────────────────────┬──────────┘
           │                        │                         │
┌──────────▼─────────────┐ ┌────────▼─────────────┐ ┌─────────▼──────────┐
│  Firebase Auth &       │ │  Hive Local Store    │ │  Google Gemini    │
│  Cloud Firestore       │ │  (Offline Support)   │ │  AI 2.0 Flash API │
└────────────────────────┘ └──────────────────────┘ └───────────────────┘
```

---

## 2. Root Configuration & Project Manifests

| File Path | Description & Purpose |
|---|---|
| `pubspec.yaml` | Primary project manifest specifying app metadata, environment SDK constraints, third-party dependencies (`flutter_riverpod`, `go_router`, `cloud_firestore`, `hive_flutter`, `google_generative_ai`), and asset declarations. |
| `pubspec.lock` | Automatically generated lockfile fixing exact versions of all transitive Dart/Flutter package dependencies. |
| `analysis_options.yaml` | Static analysis rules, lint constraints (`flutter_lints`), and code quality enforcement settings for the Dart compiler. |
| `devtools_options.yaml` | Configuration file for Flutter DevTools debugging and performance profiling suite. |
| `cors.json` | Cross-Origin Resource Sharing (CORS) rules for Firebase Storage and Google Cloud APIs when running on web platform. |
| `README.md` | General repository overview, quickstart setup instructions, and feature summary. |
| `Docs.md` | Detailed project documentation detailing functional specs, objectives, IPO chart, and Mermaid workflow diagrams. |
| `mobapp_project.iml` | IDE module configuration file for IntelliJ IDEA and Android Studio. |
| `.gitignore` | Version control exclusion rules for build artifacts, local secrets, and IDE caches. |

---

## 3. Application Core (`lib/`)

| File Path | Description & Purpose |
|---|---|
| `lib/main.dart` | Application entry point (`main()`). Handles early initialization of Flutter bindings, Firebase services, Hive offline storage, and wraps the app in Riverpod's `ProviderScope`. |
| `lib/app.dart` | Root `SelfStudyApp` widget. Configures `MaterialApp.router` with `GoRouter` declarative navigation, authentication route guards, and global visual theme tokens (Material 3 color palette). |
| `lib/config/app_config.dart` | Global configuration constants, API key defaults (e.g., Gemini AI keys), and system-wide default settings. |

---

## 4. Data Models (`lib/models/`)

These classes define the structured data schemas used throughout the app with serialization (`toMap()` / `fromMap()`) and immutability helpers (`copyWith()`).

| File Path | Description & Purpose |
|---|---|
| `lib/models/user_model.dart` | Data schema for application users. Tracks user ID, email, display name, photo URL, study streak counts, total sessions completed, and registration timestamps. |
| `lib/models/quiz_model.dart` | Schema for study quizzes. Contains quiz ID, title, description, category, author ID, public visibility toggle, total question count, and study statistics (times studied, average score). |
| `lib/models/question_model.dart` | Schema for individual quiz items. Supports two types: **Multiple Choice** (question text, options list, correct index) and **Flashcard** (front question, back answer). |
| `lib/models/pending_quiz_operation.dart` | Offline transaction model. Queues pending offline create, update, or delete operations to sync with Firestore when internet connection is restored. |

---

## 5. Services Layer (`lib/services/`)

The services layer handles all external APIs, databases, local cache reads/writes, and network operations.

| File Path | Description & Purpose |
|---|---|
| `lib/services/auth_service.dart` | Handles user authentication via `FirebaseAuth` and manages user profile persistence in Cloud Firestore (`users` collection). |
| `lib/services/quiz_service.dart` | Performs CRUD operations for quizzes and questions on Cloud Firestore (`quizzes` and `questions` collections). |
| `lib/services/gemini_service.dart` | Connects to Google's Gemini 2.0 Flash API to generate quizzes and questions from user prompt text or uploaded documents (PDF, TXT, DOCX). |
| `lib/services/local_user_store.dart` | Manages local storage of user profiles using Hive to enable instant app launch and offline profile access. |
| `lib/services/local_quiz_store.dart` | Handles local Hive database caching of quizzes and questions, enabling full offline study capability. |
| `lib/services/quiz_sync_service.dart` | Sync engine that detects connection restoration and executes queued offline operations (`PendingQuizOperation`) against Cloud Firestore. |
| `lib/services/connectivity_service.dart` | Monitors system internet connectivity using `connectivity_plus` and emits real-time connectivity status events. |

---

## 6. State Management / Providers Layer (`lib/providers/`)

Riverpod providers expose reactive state streams to UI widgets, decoupling presentation from business logic.

| File Path | Description & Purpose |
|---|---|
| `lib/providers/auth_provider.dart` | Exposes authentication state, current logged-in `UserModel`, and handles login/registration UI actions. |
| `lib/providers/quiz_provider.dart` | Manages active quiz lists, selected quiz details, user-created quizzes, search query filters, and active study session scores. |
| `lib/providers/streak_provider.dart` | Calculates daily study streaks, tracks completed daily study goals, and manages streak persistence. |
| `lib/providers/connectivity_provider.dart` | Provides application-wide online/offline status updates to dynamically toggle offline UI modes. |

---

## 7. Screens & UI Views (`lib/screens/`)

The screens folder contains top-level page views organized by functional domain.

### Main Layout & Navigation
| File Path | Description & Purpose |
|---|---|
| `lib/screens/main_layout.dart` | Navigation scaffold containing the persistent Bottom Navigation Bar and side drawer for transitioning between Home, My Quizzes, AI Quiz Generator, Study, and Profile. |

### Authentication (`lib/screens/auth/`)
| File Path | Description & Purpose |
|---|---|
| `lib/screens/auth/login_screen.dart` | Login view supporting email/password sign-in, validation feedback, password reset requests, and navigation to registration. |
| `lib/screens/auth/register_screen.dart` | Registration screen for new users to enter display name, email, and password. |

### Dashboard (`lib/screens/home/`)
| File Path | Description & Purpose |
|---|---|
| `lib/screens/home/home_screen.dart` | Main dashboard featuring study streak widgets, recent quizzes, daily study goals, quick study recommendations, and platform statistics. |

### Quiz Management (`lib/screens/quiz/`)
| File Path | Description & Purpose |
|---|---|
| `lib/screens/quiz/my_quizzes_screen.dart` | Quiz library view listing all user-created and saved quizzes with search bars, category tags, and deletion triggers. |
| `lib/screens/quiz/create_quiz_screen.dart` | Quiz editor form allowing manual creation/editing of quiz titles, categories, and addition/modification of questions. |
| `lib/screens/quiz/quiz_detail_screen.dart` | Comprehensive quiz detail view presenting question lists, study mode entry points, author info, and session statistics. |

### AI Quiz Generator (`lib/screens/ai_quiz/`)
| File Path | Description & Purpose |
|---|---|
| `lib/screens/ai_quiz/ai_quiz_generator_screen.dart` | AI generation screen where users input text prompts or attach documents (PDF/DOCX/TXT) to automatically generate structured quizzes via Gemini AI. |

### Study Modes (`lib/screens/study/`)
| File Path | Description & Purpose |
|---|---|
| `lib/screens/study/study_mode_screen.dart` | Mode selection interface allowing users to launch either Flashcard Mode or Quiz Mode for a selected quiz. |
| `lib/screens/study/flashcard_study_screen.dart` | Interactive flashcard review screen utilizing 3D card flips and swipe gestures with known/unknown card categorization. |
| `lib/screens/study/quiz_study_screen.dart` | Timed or self-paced multiple-choice test runner with instant answer feedback, score tracking, and end-of-quiz result summary. |

### User Profile (`lib/screens/profile/`)
| File Path | Description & Purpose |
|---|---|
| `lib/screens/profile/profile_screen.dart` | User profile page displaying account details, total quizzes created, study session counts, dark mode toggle, and logout button. |

---

## 8. Reusable UI Components & Widgets (`lib/widgets/`)

Shared components used across multiple screen views to ensure visual consistency.

| File Path | Description & Purpose |
|---|---|
| `lib/widgets/auth_background.dart` | Styled gradient background widget used behind authentication screens. |
| `lib/widgets/glass_card.dart` | Reusable glassmorphic UI container providing modern translucent visual styling. |
| `lib/widgets/offline_mode_dialog.dart` | Dialog modal alerting users when working in offline mode and indicating sync queue status. |
| `lib/widgets/skeleton_loader.dart` | Animated shimmering placeholder loader displayed while content is being fetched asynchronously. |

---

## 9. Platform & Asset Directories

| Path | Description & Purpose |
|---|---|
| `android/` | Android native project source code, Gradle build files, and `AndroidManifest.xml`. |
| `ios/` | iOS native Xcode project configuration, Podfile, and `Info.plist`. |
| `web/` | Web host files including `index.html`, `manifest.json`, and web entry assets. |
| `assets/images/Logo.png` | Application branding logo asset used on launcher icons and splash/header screens. |

---

## 10. File Dependency Flow Summary

```
                  ┌───────────────────────┐
                  │    lib/main.dart      │
                  └──────────┬────────────┘
                             │
                  ┌──────────▼────────────┐
                  │     lib/app.dart      │
                  └──────────┬────────────┘
                             │
               ┌─────────────▼─────────────┐
               │  lib/screens/main_layout  │
               └─────────────┬─────────────┘
                             │
     ┌───────────────────────┼───────────────────────┐
     │                       │                       │
┌────▼─────────────────┐┌────▼─────────────────┐┌────▼─────────────────┐
│ HomeScreen / Quizzes ││ StudyMode / AI Quiz  ││ ProfileScreen        │
└────┬─────────────────┘└────┬─────────────────┘└────┬─────────────────┘
     │                       │                       │
     └───────────────────────┼───────────────────────┘
                             │
               ┌─────────────▼─────────────┐
               │    lib/providers/*        │
               └─────────────┬─────────────┘
                             │
               ┌─────────────▼─────────────┐
               │    lib/services/*         │
               └─────────────┬─────────────┘
                             │
               ┌─────────────▼─────────────┐
               │    lib/models/*           │
               └───────────────────────────┘
```
