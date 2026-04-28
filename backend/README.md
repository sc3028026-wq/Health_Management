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

3. Create superuser:
   ```
   python manage.py createsuperuser
   ```

4. Run server:
   ```
   python manage.py runserver
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

Create users via signup or admin panel with roles: admin, doctor, student, pharmacist.