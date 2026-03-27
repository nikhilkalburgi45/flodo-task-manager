# Task Manager — Flutter Frontend

Flutter app for the Flodo AI take-home assignment.  
Connects to the Node.js backend in `../backend/`.

## Step 1 — Run the Flutter app

```bash
cd frontend

# See connected devices/emulators
flutter devices

# Run on emulator or connected device
flutter run
```

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, Provider setup
├── models/
│   └── task.dart              # Task data model (matches backend schema)
├── services/
│   └── api_service.dart       # All HTTP calls to backend
├── providers/
│   └── task_provider.dart     # State management (ChangeNotifier)
├── screens/
│   ├── task_list_screen.dart  # Main screen: list, search, filter
│   └── task_form_screen.dart  # Create/Edit screen with draft support
└── widgets/
    └── task_card.dart         # Individual task card UI
```

---

## Features Implemented

| Feature               | Implementation                                                              |
| --------------------- | --------------------------------------------------------------------------- |
| View all tasks        | `GET /api/tasks` on screen load + pull-to-refresh                           |
| Create task           | Form → `POST /api/tasks` with 2s loading overlay                            |
| Edit task             | Tap card → pre-filled form → `PUT /api/tasks/:id`                           |
| Delete task           | Delete icon → confirmation dialog → `DELETE /api/tasks/:id`                 |
| Search by title       | Text field → `GET /api/tasks?search=`                                       |
| Filter by status      | Dropdown → `GET /api/tasks?status=`                                         |
| Blocked task UI       | Greyed out card + 🔒 Blocked badge + "Waiting for: X" text                  |
| Draft persistence     | `SharedPreferences` saves title/desc on every keystroke; restored on reopen |
| Loading state         | Spinner + disabled Save button during 2s backend delay                      |
| Double-tap prevention | Save button disabled while `isSaving` is true                               |

---

## Common Issues

**"Connection refused" error**
→ Make sure the backend is running: `npm run dev` in `/backend`
→ Check the API URL in `api_service.dart` matches your setup

**Emulator can't reach backend**
→ Use `10.0.2.2` not `localhost` for Android emulator
→ For real device, use your PC's local IP

**`flutter pub get` fails**
→ Run `flutter doctor` and fix any reported issues first
