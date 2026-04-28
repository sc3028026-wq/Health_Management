from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone


class User(AbstractUser):
    ROLE_CHOICES = [
        ('admin', 'Admin'),
        ('doctor', 'Doctor'),
        ('student', 'Student'),
        ('pharmacist', 'Pharmacist'),
    ]
    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=15)
    department = models.CharField(max_length=100)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    profile_photo = models.ImageField(upload_to='profiles/', blank=True, null=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'full_name', 'phone', 'department', 'role']

    def __str__(self):
        return self.email


class StudentProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='student_profile')
    enrollment_no = models.CharField(max_length=50, unique=True)
    semester = models.CharField(max_length=20, blank=True)
    course = models.CharField(max_length=100, blank=True)

    def __str__(self):
        return f"StudentProfile({self.user.email})"


class DoctorProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='doctor_profile')
    specialization = models.CharField(max_length=100)
    license_no = models.CharField(max_length=50, unique=True)
    years_of_experience = models.PositiveIntegerField(default=0)

    def __str__(self):
        return f"DoctorProfile({self.user.email})"


class Appointment(models.Model):
    STATUS_CHOICES = [
        ('Pending', 'Pending'),
        ('Accepted', 'Accepted'),
        ('Completed', 'Completed'),
    ]
    student = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='student_appointments')
    doctor = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='doctor_appointments')
    student_name = models.CharField(max_length=255)
    doctor_name = models.CharField(max_length=255)
    date = models.DateTimeField()
    issue = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Pending')
    deadline = models.DateTimeField(blank=True, null=True)

    def __str__(self):
        return f"{self.student_name} - {self.doctor_name}"

class Diagnosis(models.Model):
    student = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='diagnoses_received')
    doctor = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='diagnoses_given')
    student_name = models.CharField(max_length=255)
    notes = models.TextField()
    doctor_name = models.CharField(max_length=255)
    created_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"Diagnosis for {self.student_name}"

class MedicalReport(models.Model):
    student = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='medical_reports')
    doctor = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='authored_reports')
    student_name = models.CharField(max_length=255)
    summary = models.TextField()
    updated_by = models.CharField(max_length=255)
    date = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"Report for {self.student_name}"

class MedicineItem(models.Model):
    name = models.CharField(max_length=255, unique=True)
    stock = models.PositiveIntegerField(default=0)

    def __str__(self):
        return self.name


class Prescription(models.Model):
    student = models.ForeignKey(User, on_delete=models.CASCADE, related_name='prescriptions')
    doctor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='prescribed_items')
    medicine_name = models.CharField(max_length=255)
    dosage = models.CharField(max_length=100)
    duration_days = models.PositiveIntegerField(default=1)
    instructions = models.TextField(blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"{self.student.email} - {self.medicine_name}"


class Inventory(models.Model):
    medicine = models.OneToOneField(MedicineItem, on_delete=models.CASCADE, related_name='inventory')
    reorder_level = models.PositiveIntegerField(default=20)
    last_updated_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='inventory_updates',
    )
    last_updated_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"Inventory({self.medicine.name})"


class MedicineRequest(models.Model):
    STATUS_CHOICES = [
        ('Pending', 'Pending'),
        ('Provided', 'Provided'),
        ('Rejected', 'Rejected'),
    ]
    requested_by_user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='medicine_requests')
    medicine_name = models.CharField(max_length=255)
    requested_qty = models.PositiveIntegerField()
    message = models.TextField()
    requested_by = models.CharField(max_length=255)
    requested_at = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Pending')
    provided_at = models.DateTimeField(blank=True, null=True)

    def __str__(self):
        return f"Request for {self.medicine_name} by {self.requested_by}"