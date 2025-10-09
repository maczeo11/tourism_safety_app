# incidents/serializers.py

from rest_framework import serializers
from .models import IncidentReport

class IncidentReportSerializer(serializers.ModelSerializer):
    # To show username in the API response instead of just the user ID
    user = serializers.StringRelatedField()

    class Meta:
        model = IncidentReport
        fields = ['id', 'user', 'details', 'created_at']
        read_only_fields = ['user', 'created_at']