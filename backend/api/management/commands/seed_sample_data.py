from django.core.management.base import BaseCommand
from django.utils import timezone

from api.models import (
    User,
    StudentProfile,
    DoctorProfile,
    Appointment,
    Diagnosis,
    MedicalReport,
    Prescription,
    MedicineItem,
    Inventory,
)


class Command(BaseCommand):
    help = "Seed sample data for Health Management backend."

    def handle(self, *args, **options):
        admin, _ = User.objects.get_or_create(
            email='admin@gmail.com',
            defaults={
                'username': 'admin@gmail.com',
                'full_name': 'System Admin',
                'phone': '9000000001',
                'department': 'Administration',
                'role': 'admin',
            },
        )
        admin.set_password('Admin@123')
        admin.save()

        doctor, _ = User.objects.get_or_create(
            email='doctor@gmail.com',
            defaults={
                'username': 'doctor@gmail.com',
                'full_name': 'Dr. Priya Sharma',
                'phone': '9000000002',
                'department': 'Medical Unit',
                'role': 'doctor',
            },
        )
        doctor.set_password('Doctor@123')
        doctor.save()

        student, _ = User.objects.get_or_create(
            email='student@gmail.com',
            defaults={
                'username': 'student@gmail.com',
                'full_name': 'Rahul Kumar',
                'phone': '9000000003',
                'department': 'CSE',
                'role': 'student',
            },
        )
        student.set_password('Student@123')
        student.save()

        pharmacist, _ = User.objects.get_or_create(
            email='pharma@gmail.com',
            defaults={
                'username': 'pharma@gmail.com',
                'full_name': 'Amit Verma',
                'phone': '9000000004',
                'department': 'Pharmacy',
                'role': 'pharmacist',
            },
        )
        pharmacist.set_password('Pharma@123')
        pharmacist.save()

        StudentProfile.objects.get_or_create(
            user=student,
            defaults={'enrollment_no': 'CSE2026001', 'semester': '6', 'course': 'B.Tech CSE'},
        )
        DoctorProfile.objects.get_or_create(
            user=doctor,
            defaults={'specialization': 'General Medicine', 'license_no': 'LIC-2026-DR-1001'},
        )

        appointment, _ = Appointment.objects.get_or_create(
            student=student,
            doctor=doctor,
            issue='Fever and headache',
            defaults={
                'student_name': student.full_name,
                'doctor_name': doctor.full_name,
                'date': timezone.now(),
                'status': 'Accepted',
            },
        )

        Diagnosis.objects.get_or_create(
            student=student,
            doctor=doctor,
            student_name=student.full_name,
            doctor_name=doctor.full_name,
            notes='Viral fever suspected. Hydration advised.',
        )

        MedicalReport.objects.get_or_create(
            student=student,
            doctor=doctor,
            student_name=student.full_name,
            summary='Paracetamol 500mg twice a day for 3 days.',
            updated_by=doctor.full_name,
        )

        Prescription.objects.get_or_create(
            student=student,
            doctor=doctor,
            medicine_name='Paracetamol',
            dosage='500mg',
            duration_days=3,
            instructions='After meals',
        )

        med, _ = MedicineItem.objects.get_or_create(name='Paracetamol', defaults={'stock': 180})
        Inventory.objects.get_or_create(medicine=med, defaults={'reorder_level': 30, 'last_updated_by': pharmacist})
        self.stdout.write(self.style.SUCCESS('Sample data seeded successfully.'))
