# Self Study Application Documentation

## 1. Introduction

The Self Study application is a quiz and flashcard learning platform developed using Flutter. It enables users to create their own study materials, review them through interactive flashcards, and assess understanding through quiz-based study sessions. The system is designed to deliver a clean and modern learning experience that supports independent study.

The application integrates Firebase services for authentication and cloud-based data storage. Users can register and log in using email and password, then store quizzes and questions in Firestore. This provides a reliable cloud-backed learning experience.

To improve usability, the app organizes features into a structured interface with dashboard navigation, quiz management, and study modes. It supports creation, viewing, editing, and deletion of quizzes and questions, as well as profile management and basic progress/statistics tracking. Overall, the system aims to help learners build personalized reviewers and study more efficiently.

## 2. Project Context

Students and self-learners often rely on unstructured review methods such as rewriting notes, scrolling through documents, or memorizing from static materials. These approaches can be time-consuming and may not promote active recall—one of the most effective learning strategies.

Although many learning applications exist, they may focus heavily on pre-made content or require complex features. A lightweight, user-centered tool that supports custom quiz creation and simple progress tracking is more suitable for everyday academic reviewing and personal self-study.

### Project Context Problems

- Many learners do not have a systematic way to turn notes into repeatable study materials.
- Review routines are often inconsistent because materials are scattered across multiple sources.
- Learning apps with complex features can be inconvenient for simple daily reviewing.

## 3. Objectives

**General Objective:**

To develop a user-friendly Self Study application that allows learners to create and study customized quizzes and flashcards with Firebase cloud storage.

**Specific Objectives:**

- Implement secure account registration, login, and profile management using Firebase Authentication.
- Provide a quiz creation and management module where users can create, update, and delete quizzes and questions.
- Implement interactive study modes (Flashcards and Quiz Mode) with progress and score tracking.

## 4. Features List

The Self Study application is designed to provide users with a structured and systematic way of managing their self-made study materials. The features below describe the operational components of the system and explain how each function works within the application.

### A. User Management

- **User Registration.** Allows users to create a personal account using email and password credentials verified through Firebase Authentication. After registration, a user profile record is stored in Firestore.
- **User Login.** Enables registered users to access the system by validating credentials against Firebase Authentication. Successful login loads the user profile from Firestore and allows access to the main application features.
- **User Logout.** Allows users to terminate their session and clears the current user reference to prevent unauthorized access on shared devices.
- **Profile Management.** Enables users to update profile details such as display name and additional personal fields. Profile updates are saved to Firestore.

### B. Quiz Management

- **Create Quiz.** Allows users to create a quiz by entering quiz details (title, optional description/category) and adding questions. The quiz is stored in Firestore.
- **Update Quiz.** Allows users to correct mistakes by editing quiz metadata (title/description/category). Updates are saved to Firestore.
- **Delete Quiz.** Allows users to permanently remove a quiz from Firestore (along with its questions).
- **View Quiz Details.** Displays quiz information, number of questions, and study statistics. The detail page provides actions for studying and maintaining questions.

### C. Question Management

- **Add Question.** Allows users to add questions to an existing quiz. The system supports two types:
  - Multiple choice questions (with options and a correct answer)
  - Flashcard questions (front question with a back answer)
- **Update Question.** Allows users to edit question text, options, correct answer index, and flashcard back content. Updates are saved to Firestore.
- **Delete Question.** Allows users to remove incorrect or unnecessary questions from a quiz. The question is deleted from Firestore.

### D. Study Modes

- **Flashcard Study Mode.** Presents questions as flip cards. Users can flip to reveal the answer and mark cards as known/unknown to support spaced review behavior.
- **Quiz Study Mode.** Presents multiple-choice questions, tracks correct responses, and computes a final score at the end of the session.
- **Progress and Statistics Tracking.** Updates quiz stats such as study count and average score based on completed study sessions.

### E. Cloud Storage

- **Firestore.** Stores user profiles, quizzes, and questions in Cloud Firestore. All data is persisted in the cloud and requires an internet connection to access.

## 5. Tools and Technologies Used

### A. Development Framework

- **Flutter (Dart).** Cross-platform UI framework used to build the application for Web and Mobile platforms.

### B. Backend and Cloud Services

- **Firebase Authentication.** Email/password authentication for secure user sessions.
- **Cloud Firestore.** NoSQL database for storing quizzes, questions, and user profiles in the cloud.
- **Firebase Storage.** Used for file storage such as profile images.

### C. Flutter Packages Used (from `pubspec.yaml`)

- **flutter_riverpod.** State management layer for auth state and quiz state.
- **go_router.** Declarative navigation and route redirection.
- **firebase_core / firebase_auth / cloud_firestore / firebase_storage.** Firebase integration.
- **uuid.** Generates unique IDs for quizzes and questions.
- **flip_card / flutter_card_swiper.** UI animations and card interactions.
- **image_picker / cached_network_image.** Image selection and efficient image loading.
- **intl.** Formatting and localization utilities.

### D. Development Tools

- **Android Studio / VS Code.** IDE support for Flutter development.
- **Git & GitHub.** Version control and repository hosting.
- **Firebase Console.** Configuration and monitoring of Firebase services.

## 6. IPO Chart (Input–Process–Output)

| **Input** | **Process** | **Output** |
|---|---|---|
| User registration data (email, password, name) | Validate form, create account via Firebase Auth, store profile in Firestore | Created user account + stored profile |
| Login credentials (email, password) | Authenticate via Firebase Auth, load user profile from Firestore | Authenticated session + access to app |
| Quiz details (title, description, category) | Validate fields, create quiz model, save to Firestore | New quiz available in My Quizzes |
| Question data (question text, options, correct answer / flashcard back) | Validate question rules, save to Firestore, update quiz question list | Questions attached to quiz |
| Study actions (answers, known/unknown toggles) | Track results, compute score/progress, update quiz stats in Firestore | Updated stats + study session outcome |

## 7. System Flowchart (Mermaid)

> Note: The `flowchart/` folder in this project is currently empty. The flow below is provided as a Mermaid diagram you can paste into documentation or a Mermaid-supported editor.

```mermaid
flowchart TD
  A[Open App] --> B{Authenticated?}

  B -- No --> C[Login / Register]
  C --> D{Auth Success?}
  D -- No --> C
  D -- Yes --> E[Load User from Firestore + Initialize App]

  B -- Yes --> E

  E --> F[Main Layout (Bottom Navigation)]

  F --> G[Home Dashboard]
  F --> H[My Quizzes]
  F --> I[Create Quiz]
  F --> J[Study]
  F --> K[Profile]

  I --> I1[Enter Quiz Details]
  I1 --> I2[Add Questions]
  I2 --> I3{Valid Quiz?\n(>=1 question)}
  I3 -- No --> I2
  I3 -- Yes --> I4[Save to Firestore]
  I4 --> H

  H --> H1[Open Quiz Detail]
  H1 --> H2[Edit Quiz / Add / Edit / Delete Question]

  J --> J1[Select Quiz]
  J1 --> J2{Mode?}
  J2 -- Flashcards --> J3[Flashcard Session]
  J2 -- Quiz Mode --> J4[Quiz Session]
  J3 --> J5[Update Progress]
  J4 --> J6[Compute Score]
  J5 --> J7[Update Stats in Firestore]
  J6 --> J7
  J7 --> H

  K --> K1[Update Profile]
  K1 --> K2[Save to Firestore]
  K2 --> H
```
