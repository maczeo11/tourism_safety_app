# users/models.py

from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import RegexValidator

class CustomUser(AbstractUser):
    email = models.EmailField(unique=True)
    phone_number = models.CharField(
        max_length=15,
        blank=True,
        null=True,
        validators=[
            RegexValidator(
                regex=r'^\+?1?\d{9,15}$',
                message="Phone number must be in format: '+999999999'. Up to 15 digits allowed."
            )
        ]
    )
    age = models.PositiveIntegerField(blank=True, null=True)
    nationality = models.CharField(max_length=50, blank=True, null=True)

    REQUIRED_FIELDS = ['email']

    def __str__(self):
        return self.username