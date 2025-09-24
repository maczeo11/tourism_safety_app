# tourist_safety/urls.py

from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('auth/', include('users.urls')),
    path('api/', include('incidents.urls')),
    path('blockchain/', include('blockchain.urls')),
]