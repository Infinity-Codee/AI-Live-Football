# LiveFootballAIDetection

Multi-platform project for Live Football AI Detection.

## Project Structure

```
LiveFootballAIDetection/
├── mobile/    → Flutter (iOS & Android)
├── web/       → React (Vite)
└── backend/   → Python (FastAPI)
```

## Getting Started

### Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run
```

### Web (React)
```bash
cd web
npm install
npm run dev
```

### Backend (Python)
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```
