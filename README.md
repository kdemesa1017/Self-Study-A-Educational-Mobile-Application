# Self Study - Quiz Generator & Study Platform

A modern quiz generator and study platform similar to Quizlet. Built with Flutter and Firebase.

## System Overview

**Self Study** allows users to:
- Create custom quizzes with multiple-choice or flashcard questions
- Store and sync data with Firebase Firestore
- Track study progress and scores
- Use flashcard or quiz mode for studying

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Web App                        │
├─────────────────────────────────────────────────────────────┤
│  UI Layer (Screens)                                        │
│  ├── Auth (Login/Register)                                 │
│  ├── Home Dashboard                                        │
│  ├── Quiz Management (Create/Edit/Delete)                  │
│  ├── Study Modes (Flashcards/Quiz)                        │
│  └── Profile                                              │
├─────────────────────────────────────────────────────────────┤
│  State Management (Riverpod)                                │
│  ├── Auth Provider                                        │
│  └── Quiz Provider                                        │
├─────────────────────────────────────────────────────────────┤
│  Services                                                  │
│  ├── Auth Service (Firebase Auth)                          │
│  └── Quiz Service (Firestore)                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │    Firebase     │
                     │    (Cloud)      │
                     │                 │
                     ├─────────────────┤
                     │ - Auth          │
                     │ - Firestore     │
                     │ - Storage       │
                     └─────────────────┘
```

## Quick Start (Testing)

### Prerequisites

- Flutter SDK (>=3.11.1)
- Chrome browser
- Firebase project (configured)

### 1. Setup

```bash
# Get dependencies
flutter pub get
```

### 2. Run on Web

```bash
# Development mode with hot reload
flutter run -d chrome

# With verbose output for debugging
flutter run -d chrome --verbose
```

### 3. Build for Production

```bash
flutter build web --release
```

## Testing Process

### Phase 1: Authentication Flow

1. **Registration Test**
   - Navigate to app (auto-redirects to login)
   - Click "Sign Up"
   - Enter: Name, Email, Password (6+ chars)
   - Submit → Should redirect to Home
   - Verify: Profile shows correct name

2. **Login Test**
   - Logout from Profile page
   - Enter credentials
   - Submit → Should redirect to Home
   - Verify: Welcome message shows user name

3. **Logout Test**
   - Go to Profile → Click Logout
   - Verify: Redirected to login screen

### Phase 2: Quiz Management

**Test quiz creation:**
1. Click "Create" tab
2. Enter: Title, Description, Category
3. Add 3+ questions (multiple choice or flashcard)
4. Submit → Should save to Firebase
5. Verify in "My Quizzes" tab

**Test quiz editing:**
1. Open existing quiz
2. Add new question via bottom sheet
3. Delete question (swipe or button)
4. Delete entire quiz (swipe in list)

### Phase 3: Study Modes

**Flashcard Mode:**
1. Create quiz with flashcard questions
2. Go to "Study" tab or Quiz Detail
3. Click "Flashcards" button
4. Test:
   - Tap card to flip (front/back)
   - Click "Got it!" or "Still Learning"
   - Verify progress bar updates
   - Complete all cards → See results

**Quiz Mode:**
1. Create quiz with multiple-choice questions
2. Click "Quiz Mode" button
3. Test:
   - Select answers (shows correct/wrong)
   - Verify score updates
   - Complete quiz → See percentage score
4. Verify: Quiz stats updated (study count, avg score)

### Phase 4: Profile & Data

1. **Profile Edit**
   - Profile tab → Edit
   - Change name, age, address, bio
   - Save → Verify updates in UI

2. **Data Persistence Test**
   - Create quiz
   - Close browser
   - Reopen app → Login with same account
   - Quizzes available from Firebase

## Key Features to Verify

| Feature | Test Scenario | Expected Result |
|---------|---------------|-----------------|
| Create Quiz | Create Quiz with questions | Saves to Firebase |
| Image Upload | Profile picture upload | Shows in top-right avatar |
| Search | Type in "My Quizzes" search | Filters quiz list |
| Progress Tracking | Complete study session | Stats update (count, score) |
| Swipe Actions | Swipe left on quiz | Delete option appears |

## Debugging Common Issues

### Firebase Connection Errors
```
Error: FirebaseOptions cannot be null
```
**Fix:** Verify `main.dart` has Firebase config for web

### UI State Errors
```
Error: setState() called after dispose()
```
**Fix:** Add `if (!mounted) return;` before setState

### Chrome CORS Issues
Launch Chrome with disabled security (dev only):
```bash
chrome.exe --disable-web-security --user-data-dir="C:/temp"
```

## Network Testing
Chrome DevTools → Network:
- **Throttle**: Test slow connection behavior

## Project Structure

```
lib/
├── models/              # Data classes
├── services/            # Auth, Quiz
├── providers/           # Riverpod state management
├── screens/             # UI components
│   ├── auth/
│   ├── home/
│   ├── quiz/
│   ├── study/
│   └── profile/
├── app.dart             # MaterialApp + Router
└── main.dart            # Entry point
```

## Testing Checklist

- [ ] User can register with email/password
- [ ] User can login with existing account
- [ ] User can create quiz with questions
- [ ] User can edit profile
- [ ] Flashcard study mode works
- [ ] Quiz study mode works with scoring
- [ ] Quiz search filters correctly
- [ ] Delete quiz removes from Firebase
- [ ] Logout clears session
- [ ] Data persists after browser close/reopen
- [ ] Works on mobile browser (responsive)

---

## Original Flutter README

This project is a starting point for a Flutter application.

A few resources to get you started:
- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
