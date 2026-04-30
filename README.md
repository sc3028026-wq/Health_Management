# CampusCare (Health Management)

Flutter app + Django REST backend for role-based dashboards:
**Admin**, **Doctor**, **Student**, **Pharmacist**.

## Default demo logins

- **Admin**: `admin@gmail.com` / `Admin@123`
- **Doctor**: `doctor@gmail.com` / `Doctor@123`
- **Student**: `student@gmail.com` / `Student@123`
- **Pharmacist**: `pharma@gmail.com` / `Pharma@123`

## Run backend (Windows / PowerShell)

```powershell
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

## Run Flutter (Android emulator)

```powershell
flutter run
```

## Run Flutter (physical Android phone)

1. Start backend with `0.0.0.0:8000` (above).
2. In the app, on the login screen open **Settings (⚙️)** and set:
   - `http://<YOUR_PC_IP>:8000/api`

Alternative (CLI):

```powershell
flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:8000/api
```

## Dev checks

```powershell
flutter analyze
flutter test
```
