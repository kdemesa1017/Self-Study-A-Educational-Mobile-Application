# Self Study - Quiz Generator & Study Platform

A modern, offline-first quiz generator and study platform similar to Quizlet. Built with Flutter, Firebase, and Hive for local storage.

## System Overview

**Self Study** allows users to:
- Create custom quizzes with multiple-choice or flashcard questions
- Study offline with local data persistence (IndexedDB via Hive)
- Sync data with Firebase when online
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
│  ├── Quiz Service (Firestore + Local Sync)                │
│  └── Local Storage (Hive/IndexedDB)                       │
└─────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┴─────────────────┐
            │                                   │
     ┌──────▼──────┐                    ┌──────▼──────┐
     │   Firebase  │                    │   Local DB  │
     │  (Cloud)    │◄───── Sync ───────►│  (Offline)  │
     │             │                    │             │
     ├─────────────┤                    ├─────────────┤
     │ - Auth      │                    │ - Hive      │
     │ - Firestore │                    │ - IndexedDB │
     │ - Storage   │                    │ (Web)       │
     └─────────────┘                    └─────────────┘
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

# Generate Hive adapters
flutter pub run build_runner build
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

### Phase 2: Quiz Management (Offline Mode)

**Test offline capability:**
1. Disconnect internet (DevTools → Network → Offline)
2. Create Quiz:
   - Click "Create" tab
   - Enter: Title, Description, Category
   - Add 3+ questions (multiple choice or flashcard)
   - Submit → Should save locally
3. Verify in "My Quizzes" tab
4. Reconnect internet → Should auto-sync

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
   - Create quiz offline
   - Close browser
   - Reopen app → Data should persist
   - Login with same account → Quizzes available

## Key Features to Verify

| Feature | Test Scenario | Expected Result |
|---------|---------------|-----------------|
| Offline Create | Disconnect → Create Quiz | Saves locally, shows "unsynced" icon |
| Auto Sync | Reconnect after offline changes | Data uploads to Firebase |
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

### Hive/Local Storage Errors
```
Error: HiveError: Box not found
```
**Fix:** Run `flutter clean && flutter pub get`

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

## Developer Tools

### Inspect Local Storage
Chrome DevTools → Application → IndexedDB → hive

### Network Testing
Chrome DevTools → Network:
- **Offline mode**: Test local functionality
- **Throttle**: Test slow connection behavior

## Project Structure

```
lib/
├── models/              # Data classes with Hive adapters
├── services/            # Auth, Quiz, Local Storage
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
- [ ] User can create quiz with questions (online)
- [ ] User can create quiz with questions (offline)
- [ ] Data syncs when going from offline → online
- [ ] User can edit profile
- [ ] Flashcard study mode works
- [ ] Quiz study mode works with scoring
- [ ] Quiz search filters correctly
- [ ] Delete quiz removes from local + cloud
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
