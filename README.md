# 🎤 Voice Notes App

A Flutter application for recording voice notes with real-time speech-to-text conversion, local storage, and a beautiful dark/light UI.

---

## 📁 Project Structure

```
voice_notes_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/
│   │   └── note.dart                # Note data model
│   ├── providers/
│   │   ├── notes_provider.dart      # Notes state management
│   │   └── theme_provider.dart      # Dark/light theme management
│   ├── services/
│   │   ├── speech_service.dart      # Speech-to-text wrapper
│   │   └── storage_service.dart     # SharedPreferences storage
│   ├── screens/
│   │   ├── home_screen.dart         # Main notes list screen
│   │   └── note_detail_screen.dart  # Note view/edit screen
│   └── widgets/
│       ├── recording_sheet.dart     # Bottom sheet recorder
│       └── note_card.dart           # Swipeable note list card
├── android/app/src/main/
│   └── AndroidManifest.xml          # Android permissions
├── ios/Runner/
│   └── Info.plist                   # iOS permissions
└── pubspec.yaml                     # Dependencies
```



##  Dependencies

| Package | Version | Purpose |
|---|---|---|
| `speech_to_text` | ^6.6.0 | Real-time speech recognition |
| `shared_preferences` | ^2.2.2 | Local note persistence |
| `provider` | ^6.1.1 | State management |
| `uuid` | ^4.3.3 | Unique note IDs |
| `intl` | ^0.19.0 | Date formatting |
| `flutter_slidable` | ^3.1.0 | Swipe-to-delete/edit |
| `google_fonts` | ^6.2.1 | Typography (Space Grotesk, JetBrains Mono, Inter) |

---

##  Features

### 1. Voice Recording
- Tap the **mic FAB** to open the recording sheet
- Tap the **mic circle** to start recording — speech is transcribed in real time
- Partial results shown in italics; finalized text in normal weight
- Timer shows recording duration
- Tap **stop** to end recording, then **Save Note** to store it
- **Discard** button cancels without saving

### 2. Real-Time Transcription
- Uses `speech_to_text` package with `ListenMode.dictation`
- Continuous listening for up to 5 minutes
- 5-second pause detection for natural speech
- Partial results displayed inline as you speak

### 3. Local Storage
- All notes stored via `SharedPreferences` as JSON strings
- Each note includes:
  - Auto-generated UUID
  - Auto-generated title (first 5 words of content)
  - Full transcribed content
  - `createdAt` and `updatedAt` timestamps
  - Recording duration

### 4. Notes List with Search
- Notes sorted by most recently updated
- Live search filters by **title**, **content**, and **date**
- Search clears with one tap
- Empty state with contextual messaging

### 5. Swipe Actions
- **Swipe left** on any note card to reveal Edit and Delete
- Smooth `DrawerMotion` animation
- Confirmation dialog before deletion

### 6. Note Detail & Edit
- Full note view with metadata (date, duration)
- Tap edit icon or swipe-edit to enter edit mode
- Edit title and content independently
- Auto-generates title if only content is changed
- Unsaved changes prompt on back navigation

### 7. Dark Mode
- Default: Dark mode
- Toggle via sun/moon button in header
- Preference persisted across sessions via `SharedPreferences`
- Smooth animated transitions

---

## 🎨 Design System

| Element | Dark | Light |
|---|---|---|
| Background | `#13131F` | `#F0F0FA` |
| Card | `#1E1E2E` | `#FFFFFF` |
| Primary | `#6C63FF` | `#6C63FF` |
| Accent | `#FF6584` | `#FF6584` |
| Text | `#E0E0F0` | `#1A1A2E` |

**Fonts:** Space Grotesk (headings) · Inter (body) · JetBrains Mono (timestamps/code)

---

## 🔐 Permissions

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

### iOS (`Info.plist`)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Voice Notes needs microphone access...</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Voice Notes uses speech recognition...</string>
```

---

## 🔧 Customization

### Change listening duration
In `speech_service.dart`:
```dart
listenFor: const Duration(minutes: 5),  // max recording time
pauseFor: const Duration(seconds: 5),   // auto-stop after silence
```

### Change default theme
In `theme_provider.dart`:
```dart
bool _isDarkMode = true; // Change to false for light default
```

### Change title generation
In `note.dart`:
```dart
final titleWords = words.take(5).join(' '); // Change 5 to more/fewer words
```

---

## ⚠️ Known Considerations

1. **Speech recognition requires network** on Android (Google STT). On iOS, on-device recognition is used when available.
2. **Microphone permission** must be granted at runtime — the app handles this gracefully with error messaging.
3. `SharedPreferences` is suitable for personal notes; for large datasets consider migrating to SQLite/`sqflite`.

---

## 📄 License

MIT — Free to use and modify.
