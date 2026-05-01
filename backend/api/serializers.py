from rest_framework import serializers
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


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False, min_length=6)

    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'username',
            'password',
            'full_name',
            'phone',
            'department',
            'role',
            'profile_photo',
        ]
        read_only_fields = ['id']

    def create(self, validated_data):
        password = validated_data.pop('password', None)
        if not password:
            raise serializers.ValidationError({'password': 'Password is required.'})
        if not validated_data.get('username'):
            validated_data['username'] = validated_data['email']
        user = User.objects.create_user(**validated_data)
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        for field, value in validated_data.items():
            setattr(instance, field, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class PasswordResetOtpVerifySerializer(serializers.Serializer):
    email = serializers.EmailField()
    session_id = serializers.CharField()
    otp = serializers.RegexField(r'^\d{6}$', max_length=6)


class PasswordResetCompleteSerializer(serializers.Serializer):
    email = serializers.EmailField()
    session_id = serializers.CharField()
    new_password = serializers.CharField(min_length=6, max_length=128)
    confirm_password = serializers.CharField(min_length=6, max_length=128)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError(
                {'confirm_password': 'New password and confirm password must match.'}
            )
        return attrs


class StudentProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = StudentProfile
        fields = '__all__'


class DoctorProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorProfile
        fields = '__all__'


class AppointmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Appointment
        fields = '__all__'

class DiagnosisSerializer(serializers.ModelSerializer):
    class Meta:
        model = Diagnosis
        fields = '__all__'

class MedicalReportSerializer(serializers.ModelSerializer):
    pdf_url = serializers.SerializerMethodField()

    class Meta:
        model = MedicalReport
        fields = '__all__'

    def get_pdf_url(self, obj):
        request = self.context.get('request')
        if obj.pdf_file and request:
            return request.build_absolute_uri(obj.pdf_file.url)
        elif obj.pdf_file:
            return obj.pdf_file.url
        return None


class PrescriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Prescription
        fields = '__all__'


class MedicineItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicineItem
        fields = '__all__'


class InventorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Inventory
        fields = '__all__'


class MedicineRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicineRequest
        fields = '__all__'