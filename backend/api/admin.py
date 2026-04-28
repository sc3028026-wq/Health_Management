from django.contrib import admin
from .models import (
    User,
    StudentProfile,
    DoctorProfile,
    Appointment,
    Diagnosis,
    MedicalReport,
    Prescription,
    MedicineItem,
    Inventory,
    MedicineRequest,
)


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('id', 'email', 'full_name', 'role', 'department', 'is_staff', 'is_active')
    search_fields = ('email', 'full_name', 'phone', 'department')
    list_filter = ('role', 'department', 'is_staff', 'is_active')
    ordering = ('id',)


@admin.register(StudentProfile)
class StudentProfileAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'enrollment_no', 'semester', 'course')
    search_fields = ('user__email', 'enrollment_no', 'course')
    list_filter = ('semester', 'course')
    ordering = ('id',)


@admin.register(DoctorProfile)
class DoctorProfileAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'specialization', 'license_no', 'years_of_experience')
    search_fields = ('user__email', 'specialization', 'license_no')
    list_filter = ('specialization', 'years_of_experience')
    ordering = ('id',)


@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ('id', 'student_name', 'doctor_name', 'status', 'date', 'deadline')
    search_fields = ('student_name', 'doctor_name', 'issue', 'student__email', 'doctor__email')
    list_filter = ('status', 'date', 'deadline')
    ordering = ('-date', '-id')


@admin.register(Diagnosis)
class DiagnosisAdmin(admin.ModelAdmin):
    list_display = ('id', 'student_name', 'doctor_name', 'created_at')
    search_fields = ('student_name', 'doctor_name', 'notes')
    list_filter = ('created_at',)
    ordering = ('-created_at', '-id')


@admin.register(MedicalReport)
class MedicalReportAdmin(admin.ModelAdmin):
    list_display = ('id', 'student_name', 'updated_by', 'date')
    search_fields = ('student_name', 'summary', 'updated_by')
    list_filter = ('date',)
    ordering = ('-date', '-id')


@admin.register(Prescription)
class PrescriptionAdmin(admin.ModelAdmin):
    list_display = ('id', 'student', 'doctor', 'medicine_name', 'dosage', 'duration_days', 'created_at')
    search_fields = ('student__email', 'doctor__email', 'medicine_name', 'dosage')
    list_filter = ('created_at',)
    ordering = ('-created_at', '-id')


@admin.register(MedicineItem)
class MedicineItemAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'stock')
    search_fields = ('name',)
    ordering = ('name',)


@admin.register(Inventory)
class InventoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'medicine', 'reorder_level', 'last_updated_by', 'last_updated_at')
    search_fields = ('medicine__name', 'last_updated_by__email')
    list_filter = ('last_updated_at',)
    ordering = ('medicine__name',)


@admin.register(MedicineRequest)
class MedicineRequestAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'medicine_name',
        'requested_qty',
        'requested_by',
        'status',
        'requested_at',
        'provided_at',
    )
    search_fields = ('medicine_name', 'requested_by', 'message', 'requested_by_user__email')
    list_filter = ('status', 'requested_at', 'provided_at')
    ordering = ('-requested_at', '-id')