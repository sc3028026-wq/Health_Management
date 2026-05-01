import secrets
from random import randint

from django.conf import settings
from django.contrib.auth import authenticate
from django.core.cache import cache
from django.core.mail import send_mail
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
import os
from django.template.loader import get_template
from xhtml2pdf import pisa
from io import BytesIO
from django.core.files.base import ContentFile
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
from .serializers import (
    PasswordResetCompleteSerializer,
    PasswordResetOtpVerifySerializer,
    PasswordResetRequestSerializer,
    UserSerializer,
    StudentProfileSerializer,
    DoctorProfileSerializer,
    AppointmentSerializer,
    DiagnosisSerializer,
    MedicalReportSerializer,
    PrescriptionSerializer,
    MedicineItemSerializer,
    InventorySerializer,
    MedicineRequestSerializer,
)
from .permissions import IsAdminRole

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

    def get_permissions(self):
        if self.action in ['login', 'signup']:
            return [AllowAny()]
        if self.action in ['logout', 'me']:
            return super().get_permissions()
        if self.action in ['create', 'list', 'destroy']:
            return [IsAdminRole()]
        return super().get_permissions()

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return User.objects.none()
        if user.role == 'admin':
            return User.objects.all().order_by('id')
        return User.objects.filter(id=user.id)

    @action(detail=False, methods=['post'], permission_classes=[AllowAny])
    def login(self, request):
        identifier = request.data.get('email') or request.data.get('username')
        password = request.data.get('password')
        if not identifier or not password:
            return Response(
                {'error': 'Username/email and password are required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        user = authenticate(request, username=identifier, password=password)
        if not user and '@' in identifier:
            # Support either email or username in request payload.
            try:
                candidate = User.objects.get(email__iexact=identifier)
                user = authenticate(request, username=candidate.username, password=password)
            except User.DoesNotExist:
                user = None
        if user:
            refresh = RefreshToken.for_user(user)
            return Response({
                'message': 'Login successful',
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': UserSerializer(user).data
            })
        return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

    @action(detail=False, methods=['post'], permission_classes=[AllowAny])
    def signup(self, request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': serializer.data
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'])
    def logout(self, request):
        refresh_token = request.data.get('refresh')
        if not refresh_token:
            return Response({'error': 'Refresh token is required.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except Exception:
            return Response({'error': 'Invalid refresh token.'}, status=status.HTTP_400_BAD_REQUEST)
        return Response({'message': 'Logout successful.'})

    @action(detail=False, methods=['get'])
    def me(self, request):
        return Response(UserSerializer(request.user).data)

    @action(detail=False, methods=['get'])
    def doctors(self, request):
        doctors_qs = User.objects.filter(role='doctor').order_by('full_name', 'id')
        return Response(UserSerializer(doctors_qs, many=True).data)

    @action(detail=False, methods=['post'], permission_classes=[AllowAny], url_path='password-reset/send-otp')
    def send_password_reset_otp(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email'].strip().lower()
        otp = f'{randint(0, 999999):06d}'
        session_id = secrets.token_urlsafe(24)

        cache.set(
            f'password-reset:{session_id}',
            {
                'email': email,
                'otp': otp,
                'verified': False,
            },
            timeout=10 * 60,
        )

        send_mail(
            subject='CampusCare password reset OTP',
            message=(
                f'Your OTP for password reset is {otp}.\n'
                'It is valid for 10 minutes.\n'
                'If you did not request this, please ignore this email.'
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
            fail_silently=False,
        )

        return Response(
            {
                'message': 'OTP sent successfully to your email.',
                'session_id': session_id,
            }
        )

    @action(detail=False, methods=['post'], permission_classes=[AllowAny], url_path='password-reset/verify-otp')
    def verify_password_reset_otp(self, request):
        serializer = PasswordResetOtpVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email'].strip().lower()
        session_id = serializer.validated_data['session_id']
        otp = serializer.validated_data['otp']

        cache_key = f'password-reset:{session_id}'
        cached_reset = cache.get(cache_key)
        if not cached_reset or cached_reset.get('email') != email:
            return Response(
                {'error': 'Password reset session expired. Please request OTP again.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if cached_reset.get('otp') != otp:
            return Response({'error': 'Invalid OTP.'}, status=status.HTTP_400_BAD_REQUEST)

        cached_reset['verified'] = True
        cache.set(cache_key, cached_reset, timeout=10 * 60)
        return Response({'message': 'OTP verified successfully.'})

    @action(detail=False, methods=['post'], permission_classes=[AllowAny], url_path='password-reset/complete')
    def complete_password_reset(self, request):
        serializer = PasswordResetCompleteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email'].strip().lower()
        session_id = serializer.validated_data['session_id']
        new_password = serializer.validated_data['new_password']

        cache_key = f'password-reset:{session_id}'
        cached_reset = cache.get(cache_key)
        if not cached_reset or cached_reset.get('email') != email:
            return Response(
                {'error': 'Password reset session expired. Please request OTP again.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not cached_reset.get('verified'):
            return Response(
                {'error': 'OTP verification is required before resetting password.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = User.objects.filter(email__iexact=email).first()
        if user:
            user.set_password(new_password)
            user.save(update_fields=['password'])

        cache.delete(cache_key)
        return Response({'message': 'Password reset successful. Please login with new password.'})


class StudentProfileViewSet(viewsets.ModelViewSet):
    queryset = StudentProfile.objects.select_related('user').all().order_by('-id')
    serializer_class = StudentProfileSerializer
    permission_classes = [IsAdminRole]


class DoctorProfileViewSet(viewsets.ModelViewSet):
    queryset = DoctorProfile.objects.select_related('user').all().order_by('-id')
    serializer_class = DoctorProfileSerializer
    permission_classes = [IsAdminRole]


class AppointmentViewSet(viewsets.ModelViewSet):
    queryset = Appointment.objects.all()
    serializer_class = AppointmentSerializer

    def get_queryset(self):
        user = self.request.user
        base_qs = Appointment.objects.select_related('student', 'doctor').all().order_by('-date', '-id')
        if user.role == 'admin':
            return base_qs
        if user.role == 'doctor':
            return base_qs.filter(doctor=user) | base_qs.filter(doctor_name=user.full_name)
        if user.role == 'student':
            return base_qs.filter(student=user) | base_qs.filter(student_name=user.full_name)
        return Appointment.objects.none()

    def perform_create(self, serializer):
        user = self.request.user
        if user.role != 'student':
            raise PermissionDenied('Only students can book appointments.')
        serializer.save(
            student=user,
            student_name=user.full_name,
        )

    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        if request.user.role not in ['doctor', 'admin']:
            raise PermissionDenied('Only doctor or admin can accept appointments.')
        appointment = self.get_object()
        appointment.status = 'Accepted'
        if request.user.role == 'doctor':
            appointment.doctor = request.user
            appointment.doctor_name = request.user.full_name
        appointment.save()
        return Response({'status': 'Appointment accepted'})

    @action(detail=True, methods=['post'])
    def set_deadline(self, request, pk=None):
        if request.user.role not in ['doctor', 'admin']:
            raise PermissionDenied('Only doctor or admin can set deadline.')
        appointment = self.get_object()
        deadline = request.data.get('deadline')
        if deadline:
            appointment.deadline = deadline
            if appointment.status == 'Pending':
                appointment.status = 'Accepted'
            appointment.save()
            return Response({'status': 'Deadline set'})
        return Response({'error': 'Deadline required'}, status=status.HTTP_400_BAD_REQUEST)

class DiagnosisViewSet(viewsets.ModelViewSet):
    queryset = Diagnosis.objects.all()
    serializer_class = DiagnosisSerializer

    def get_queryset(self):
        user = self.request.user
        qs = Diagnosis.objects.select_related('student', 'doctor').all().order_by('-created_at', '-id')
        if user.role == 'admin':
            return qs
        if user.role == 'doctor':
            return qs.filter(doctor=user) | qs.filter(doctor_name=user.full_name)
        if user.role == 'student':
            return qs.filter(student=user) | qs.filter(student_name=user.full_name)
        return Diagnosis.objects.none()

    def perform_create(self, serializer):
        if self.request.user.role != 'doctor':
            raise PermissionDenied('Only doctors can add diagnosis.')
        serializer.save(
            doctor=self.request.user,
            doctor_name=self.request.user.full_name,
        )

class MedicalReportViewSet(viewsets.ModelViewSet):
    queryset = MedicalReport.objects.all()
    serializer_class = MedicalReportSerializer

    def get_queryset(self):
        user = self.request.user
        qs = MedicalReport.objects.select_related('student', 'doctor').all().order_by('-date', '-id')
        if user.role == 'admin':
            return qs
        if user.role == 'doctor':
            return qs.filter(doctor=user) | qs.filter(updated_by=user.full_name)
        if user.role == 'student':
            return qs.filter(student=user) | qs.filter(student_name=user.full_name)
        return MedicalReport.objects.none()

    def perform_create(self, serializer):
        if self.request.user.role != 'doctor':
            raise PermissionDenied('Only doctors can update reports.')
        report = serializer.save(
            doctor=self.request.user,
            updated_by=self.request.user.full_name,
            date=timezone.now(),
        )
        
        # Generate PDF
        template_path = 'report_template.html'
        context = {
            'report': report,
        }
        template = get_template(template_path)
        html = template.render(context)
        
        result = BytesIO()
        pdf = pisa.pisaDocument(BytesIO(html.encode("UTF-8")), result)
        
        if not pdf.err:
            file_name = f"Report_{report.id}_{report.student_name.replace(' ', '_')}.pdf"
            report.pdf_file.save(file_name, ContentFile(result.getvalue()), save=True)


    @action(detail=True, methods=['get'])
    def download(self, request, pk=None):
        report = self.get_object()
        pdf_url = request.build_absolute_uri(report.pdf_file.url) if report.pdf_file else None
        return Response({
            'report_id': report.id,
            'student_name': report.student_name,
            'summary': report.summary,
            'updated_by': report.updated_by,
            'date': report.date,
            'pdf_url': pdf_url,
            'download_url': pdf_url,
        })
        
    @action(detail=True, methods=['get'])
    def pdf(self, request, pk=None):
        report = self.get_object()
        if report.pdf_file:
            return Response({'pdf_url': request.build_absolute_uri(report.pdf_file.url)})
        return Response({'error': 'PDF not generated yet'}, status=404)


class PrescriptionViewSet(viewsets.ModelViewSet):
    queryset = Prescription.objects.select_related('student', 'doctor').all().order_by('-created_at', '-id')
    serializer_class = PrescriptionSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role == 'admin':
            return self.queryset
        if user.role == 'doctor':
            return self.queryset.filter(doctor=user)
        if user.role == 'student':
            return self.queryset.filter(student=user)
        return Prescription.objects.none()

    def perform_create(self, serializer):
        if self.request.user.role != 'doctor':
            raise PermissionDenied('Only doctors can prescribe medicines.')
        serializer.save(doctor=self.request.user)

class MedicineItemViewSet(viewsets.ModelViewSet):
    queryset = MedicineItem.objects.all()
    serializer_class = MedicineItemSerializer

    def get_queryset(self):
        return MedicineItem.objects.all().order_by('name')

    def perform_create(self, serializer):
        if self.request.user.role not in ['admin', 'pharmacist']:
            raise PermissionDenied('Only admin/pharmacist can add medicines.')
        item = serializer.save()
        Inventory.objects.get_or_create(medicine=item)

    @action(detail=False, methods=['post'])
    def add_stock(self, request):
        if request.user.role not in ['admin', 'pharmacist']:
            raise PermissionDenied('Only admin/pharmacist can update stock.')
        name = request.data.get('name')
        stock = int(request.data.get('stock', 0))
        if not name or stock <= 0:
            return Response({'error': 'Valid medicine name and stock are required.'}, status=status.HTTP_400_BAD_REQUEST)
        medicine, created = MedicineItem.objects.get_or_create(name=name)
        medicine.stock += stock
        medicine.save()
        inventory, _ = Inventory.objects.get_or_create(medicine=medicine)
        inventory.last_updated_by = request.user
        inventory.last_updated_at = timezone.now()
        inventory.save()
        return Response(MedicineItemSerializer(medicine).data)

    @action(detail=False, methods=['post'])
    def issue(self, request):
        if request.user.role not in ['admin', 'pharmacist']:
            raise PermissionDenied('Only admin/pharmacist can issue medicines.')
        name = request.data.get('name')
        qty = int(request.data.get('qty', 0))
        if not name or qty <= 0:
            return Response({'error': 'Valid medicine name and quantity are required.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            medicine = MedicineItem.objects.get(name=name)
            if medicine.stock >= qty:
                medicine.stock -= qty
                medicine.save()
                return Response({'message': 'Medicine issued successfully'})
            return Response({'error': 'Not enough stock'}, status=status.HTTP_400_BAD_REQUEST)
        except MedicineItem.DoesNotExist:
            return Response({'error': 'Medicine not found'}, status=status.HTTP_404_NOT_FOUND)


class InventoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Inventory.objects.select_related('medicine', 'last_updated_by').all().order_by('medicine__name')
    serializer_class = InventorySerializer


class MedicineRequestViewSet(viewsets.ModelViewSet):
    queryset = MedicineRequest.objects.all()
    serializer_class = MedicineRequestSerializer

    def get_queryset(self):
        user = self.request.user
        qs = MedicineRequest.objects.select_related('requested_by_user').all().order_by('-requested_at', '-id')
        if user.role in ['admin', 'pharmacist']:
            return qs
        return qs.filter(requested_by_user=user)

    @action(detail=True, methods=['post'])
    def provide(self, request, pk=None):
        if request.user.role != 'admin':
            raise PermissionDenied('Only admin can provide refill requests.')
        medicine_request = self.get_object()
        if medicine_request.status == 'Provided':
            return Response({'error': 'Already provided'}, status=status.HTTP_400_BAD_REQUEST)
        # Add to stock
        medicine, created = MedicineItem.objects.get_or_create(name=medicine_request.medicine_name)
        medicine.stock += medicine_request.requested_qty
        medicine.save()
        medicine_request.status = 'Provided'
        medicine_request.provided_at = timezone.now()
        medicine_request.save()
        return Response({'status': 'Medicine provided'})

    @action(detail=False, methods=['post'])
    def notify_admin(self, request):
        if request.user.role != 'pharmacist':
            raise PermissionDenied('Only pharmacist can notify admin.')
        medicine_name = request.data.get('medicine_name')
        requested_qty = request.data.get('requested_qty')
        message = request.data.get('message', '')
        requested_by = request.user.full_name

        if not medicine_name or not requested_qty:
            return Response({'error': 'Medicine name and requested quantity are required'}, status=status.HTTP_400_BAD_REQUEST)

        # Create a new MedicineRequest
        medicine_request = MedicineRequest.objects.create(
            medicine_name=medicine_name,
            requested_qty=requested_qty,
            message=message,
            requested_by=requested_by,
            requested_by_user=request.user,
        )

        # Notify admin (this can be extended to send an email or push notification)
        # For now, we will just log the notification
        print(f"Admin Notification: {requested_by} requested {requested_qty} units of {medicine_name}. Message: {message}")

        return Response({'status': 'Admin notified successfully', 'request_id': medicine_request.id})