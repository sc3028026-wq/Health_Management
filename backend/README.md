# Health Management Backend

Django REST API for Health Management System.

## Setup

1. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

2. Run migrations:
   ```
   python manage.py makemigrations
   python manage.py migrate
   ```

3. Apply migrations (this also seeds demo users):
   ```
   python manage.py migrate
   ```

4. (Optional) Create your own superuser:
   ```
   python manage.py createsuperuser
   ```

5. Run server:
   ```
   python manage.py runserver 0.0.0.0:8000
   ```

## API Endpoints

- `/api/users/` - User management (login, signup)
- `/api/appointments/` - Appointments CRUD
- `/api/diagnoses/` - Diagnoses CRUD
- `/api/reports/` - Medical reports CRUD
- `/api/medicines/` - Medicine items CRUD
- `/api/medicine-requests/` - Medicine requests CRUD

## Authentication

Uses JWT tokens. Login to get tokens, include in headers: `Authorization: Bearer <access_token>`

## Default Users

On migrate, demo users are auto-created/updated:

- Admin: `admin@gmail.com` / `Admin@123`
- Doctor: `doctor@gmail.com` / `Doctor@123`
- Student: `student@gmail.com` / `Student@123`
- Pharmacist: `pharma@gmail.com` / `Pharma@123`