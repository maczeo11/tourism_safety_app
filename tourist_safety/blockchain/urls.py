# blockchain/urls.py

from django.urls import path
from . import views

urlpatterns = [
    # UUID Generation and Management
    path('generate-uuid/', views.generate_uuid, name='generate_uuid'),
    path('user-uuids/', views.get_user_uuids, name='get_user_uuids'),
    path('latest-uuid/', views.get_latest_uuid, name='get_latest_uuid'),
    path('verify-uuid/', views.verify_uuid, name='verify_uuid'),
    path('verify-block/', views.verify_block, name='verify_block'),
    
    # Blockchain Information
    path('info/', views.get_blockchain_info, name='get_blockchain_info'),
    path('details/', views.get_blockchain_details, name='get_blockchain_details'),
]
