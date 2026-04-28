from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView, TokenVerifyView
from . import views

router = DefaultRouter()
router.register(r'users', views.UserViewSet)
router.register(r'student-profiles', views.StudentProfileViewSet)
router.register(r'doctor-profiles', views.DoctorProfileViewSet)
router.register(r'appointments', views.AppointmentViewSet)
router.register(r'diagnoses', views.DiagnosisViewSet)
router.register(r'reports', views.MedicalReportViewSet)
router.register(r'prescriptions', views.PrescriptionViewSet)
router.register(r'medicines', views.MedicineItemViewSet)
router.register(r'inventory', views.InventoryViewSet)
router.register(r'medicine-requests', views.MedicineRequestViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
]