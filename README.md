# Learning-Card-App

Learning-Card-App is a smart flashcard and note-taking application. The project includes a Flutter mobile app, a Node.js/Express backend API, MySQL database storage, JWT authentication, study progress tracking, and optional AI features for chat, explanations, summaries, and flashcard generation.

## Features

- User registration and login
- JWT-based authentication
- Create, edit, and delete flashcard sets
- Private-by-default flashcard sets and notes
- Share view access by email, revoke access, or publish content
- Creator attribution on shared flashcards and notes
- Create, edit, and delete flashcards
- Study mode and quiz mode
- Real study sessions, per-card review scheduling, dashboard, and review queue
- Immediate cross-content search for sets, cards, and notes
- Handwriting/note-taking support
- AI study assistant
- AI explanation, note summary, and flashcard generation
- MySQL database integration

## Tech Stack

**Frontend**

- Flutter
- Dart
- Provider
- Dio
- Shared Preferences

**Backend**

- Node.js
- Express.js
- MySQL
- JWT
- bcryptjs
- dotenv

**Database**

- MySQL

## Project Structure

```text
Learning-Card-App/
├── LearningCardApp/              # Flutter application
│   ├── lib/
│   │   ├── core/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   └── pubspec.yaml
│
├── LearningCardApp_Backend/      # Node.js backend API
│   ├── config/
│   ├── controllers/
│   ├── database/
│   ├── middleware/
│   ├── routes/
│   ├── services/
│   ├── package.json
│   └── server.js
│
└── README.md
```

## Database Setup

This project uses MySQL. The database schema is available at:

```text
LearningCardApp_Backend/database/schema.sql
```

### Option 1: Import with MySQL Workbench

1. Open MySQL Workbench.
2. Connect to your local MySQL server.
3. Go to `File > Open SQL Script`.
4. Select:

```text
LearningCardApp_Backend/database/schema.sql
```

5. Run the script using the lightning button.
6. Refresh the Schemas panel and check that this database exists:

```text
smart_flashcard_notes
```

### Option 2: Import with Command Line

If the `mysql` command is available:

```bash
cd LearningCardApp_Backend
mysql -u root -p < database/schema.sql
```

On Windows, if PowerShell does not support `<`, use CMD or run:

```powershell
Get-Content .\database\schema.sql | mysql -u root -p
```

## Backend Setup

Go to the backend folder:

```bash
cd LearningCardApp_Backend
```

Install dependencies:

```bash
npm install
```

Create a `.env` file in `LearningCardApp_Backend/`:

```env
PORT=5000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=12345
DB_NAME=smart_flashcard_notes
JWT_SECRET=replace_with_a_long_secret_key
GEMINI_API_KEY=your_gemini_api_key_here
```

Notes:

- If your MySQL root account has no password, leave `DB_PASSWORD` empty.
- `GEMINI_API_KEY` is optional. If it is empty, the AI service will return fallback responses for testing.

Apply the database migration. This is required for existing databases and is safe to run again:

```bash
npm run migrate
```

### Ready-to-use demo database

Create or reset the two dedicated demo accounts and their sample learning data:

```bash
npm run db:demo
```

This command runs the migration first and then loads flashcards, notes, shares, study sessions, progress, card review schedules, and AI chat examples. It can be run repeatedly and only resets the two demo accounts below; normal user accounts are not deleted.

| Demo account | Email | Password |
|---|---|---|
| Minh Anh | `minh.demo@learningcard.local` | `Demo@123` |
| Lan Chi | `lan.demo@learningcard.local` | `Demo@123` |

The sample intentionally demonstrates privacy:

- Minh has three owned flashcard sets, three notes, a seven-day streak, and one set/note shared by Lan.
- Lan has two owned flashcard sets, two notes, and receives one set/note from Minh.
- Private content stays hidden across accounts; shared content shows its creator; public examples are discoverable through search.
- Run `npm run test:demo` after seeding to verify the complete sample through the API.

Start the backend server:

```bash
npm run dev
```

The backend runs on:

```text
http://localhost:5000
```

Check API and database connection:

```text
http://localhost:5000/api/health
```

Expected response:

```json
{
  "success": true,
  "message": "API and database connection look good",
  "data": {
    "ok": 1
  }
}
```

## Frontend Setup

Go to the Flutter app folder:

```bash
cd LearningCardApp
```

Install Flutter dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

The API base URL is configured in:

```text
LearningCardApp/lib/core/constants/api_constants.dart
```

Current default:

```dart
static const String baseUrl = 'http://10.0.2.2:5000/api';
```

This works for Android Emulator. For other environments, update it:

- Android Emulator: `http://10.0.2.2:5000/api`
- iOS Simulator/Desktop/Web: `http://localhost:5000/api`
- Real phone: `http://YOUR_COMPUTER_LAN_IP:5000/api`

## API Routes

Main backend routes:

```text
GET    /api/health

POST   /api/auth/register
POST   /api/auth/login
GET    /api/auth/profile

GET    /api/sets
POST   /api/sets
GET    /api/sets/:id
PUT    /api/sets/:id
DELETE /api/sets/:id
POST   /api/sets/:id/share
GET    /api/sets/:id/shares
DELETE /api/sets/:id/shares/:userId
PUT    /api/sets/:id/visibility

GET    /api/cards/set/:setId
POST   /api/cards
PUT    /api/cards/:id
DELETE /api/cards/:id

GET    /api/progress/:setId
POST   /api/progress
POST   /api/progress/review

GET    /api/notes
POST   /api/notes
GET    /api/notes/:id
PUT    /api/notes/:id
DELETE /api/notes/:id
POST   /api/notes/:id/share
GET    /api/notes/:id/shares
DELETE /api/notes/:id/shares/:userId
PUT    /api/notes/:id/visibility

GET    /api/search?q=<query>
GET    /api/dashboard
GET    /api/dashboard/review

POST   /api/ai/chat
POST   /api/ai/explain
POST   /api/ai/summarize-notes
POST   /api/ai/generate-flashcards
```

Protected routes require an Authorization header:

```text
Authorization: Bearer <token>
```

## AI Features

The backend can connect to the Gemini API when `GEMINI_API_KEY` is configured.

Available AI features:

- Chat with an AI study assistant
- Explain a topic
- Summarize notes
- Generate flashcards from text

If `GEMINI_API_KEY` is not provided, the backend still returns sample fallback responses so the app UI can be tested.

## Common Issues

### MySQL command is not recognized

This means MySQL is not added to PATH. Use MySQL Workbench to import the SQL file, or run MySQL using the full path to `mysql.exe`.

### PowerShell does not accept `< database/schema.sql`

Use CMD instead, or use:

```powershell
Get-Content .\database\schema.sql | mysql -u root -p
```

### Flutter app cannot connect to backend

Check:

- Backend is running on port `5000`
- MySQL is running
- `/api/health` returns success
- `baseUrl` in `api_constants.dart` matches your device/emulator

### An existing database reports a missing column or table

Run the versioned migration, then restart the backend:

```bash
cd LearningCardApp_Backend
npm run migrate
npm run dev
```

## Privacy Model

- New flashcard sets and notes are private by default.
- Only the creator can edit, delete, share, revoke, or change visibility.
- A recipient shared by email receives read/study access and sees the creator name.
- Public content is discoverable in search but remains editable only by its creator.
- Flutter clears all user-scoped providers on login/logout so one account cannot inherit another account's cached lists.

Run the backend privacy regression test with a disposable A/B account pair:

```bash
cd LearningCardApp_Backend
npm run test:privacy
```

## Current Status

The project includes the redesigned Material 3 UI, private ownership and sharing, creator attribution, authenticated search, real dashboard/review data, progress tracking, notes, and AI integration.

## Author

Learning-Card-App project for building a smart flashcard learning application.
