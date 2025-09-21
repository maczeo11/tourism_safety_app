# users/models.py

import hashlib
import secrets
import string
from django.db import models

class User(models.Model):
    username = models.CharField(max_length=150, unique=True)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=15, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    password_hash = models.CharField(max_length=255)
    password_salt = models.CharField(max_length=64)

    def set_password(self, raw_password):
        salt = ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(32))
        hash_obj = hashlib.sha256((raw_password + salt).encode('utf-8'))
        self.password_salt = salt
        self.password_hash = hash_obj.hexdigest()

    def check_password(self, raw_password):
        hash_obj = hashlib.sha256((raw_password + self.password_salt).encode('utf-8'))
        return hash_obj.hexdigest() == self.password_hash

    def __str__(self):
        return self.username