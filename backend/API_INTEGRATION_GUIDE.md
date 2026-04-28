# CampusCare Backend API Guide

## Run Backend

1. `cd backend`
2. `pip install -r requirements.txt`
3. `python manage.py migrate`
4. `python manage.py seed_sample_data`
5. `python manage.py runserver 0.0.0.0:8000`

## Auth APIs (JWT)

- `POST /api/users/login/`
  - body: `{ "email": "...", "password": "..." }`
  - returns: `access`, `refresh`, `user`
- `POST /api/users/signup/`
- `POST /api/users/logout/`
  - body: `{ "refresh": "<refresh_token>" }`
- `GET /api/users/me/`

Use header on protected APIs:

`Authorization: Bearer <access_token>`

## Role-Based Modules

- Admin user management: `GET/POST /api/users/`, `PUT/PATCH/DELETE /api/users/{id}/`
- Student profile CRUD: `/api/student-profiles/`
- Doctor profile CRUD: `/api/doctor-profiles/`
- Appointments: `/api/appointments/`
  - Accept: `POST /api/appointments/{id}/accept/`
  - Set deadline: `POST /api/appointments/{id}/set_deadline/`
- Diagnosis: `/api/diagnoses/`
- Medical reports: `/api/reports/`
  - Download metadata: `GET /api/reports/{id}/download/`
- Prescriptions: `/api/prescriptions/`
- Medicines: `/api/medicines/`
  - Add stock: `POST /api/medicines/add_stock/`
  - Issue medicine: `POST /api/medicines/issue/`
- Inventory read API: `/api/inventory/`
- Medicine requests: `/api/medicine-requests/`
  - Notify admin: `POST /api/medicine-requests/notify_admin/`
  - Provide request: `POST /api/medicine-requests/{id}/provide/`

## Sample Users

- Admin: `admin@gmail.com / Admin@123`
- Doctor: `doctor@gmail.com / Doctor@123`
- Student: `student@gmail.com / Student@123`
- Pharmacist: `pharma@gmail.com / Pharma@123`

## Flutter Integration Notes

- Current Flutter pharmacist API integration already uses:
  - `POST /api/medicine-requests/notify_admin/`
  - `GET /api/medicine-requests/`
  - `POST /api/medicine-requests/{id}/provide/`
- For login migration to backend auth, call `/api/users/login/` and store JWT tokens.
- Set backend base URL in Flutter to: `http://localhost:8000/api/`.
