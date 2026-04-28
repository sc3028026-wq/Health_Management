import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'health_backend.settings')
django.setup()

from api.models import User

User.objects.create_superuser(
    username='admin@gmail.com',
    email='admin@gmail.com',
    password='Admin@123',
    full_name='System Admin',
    phone='9000000001',
    department='Administration',
    role='admin'
)