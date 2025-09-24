# incidents/views.py

from rest_framework import viewsets, permissions , generics
from .models import IncidentReport
from .serializers import IncidentReportSerializer
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404

class IncidentReportViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows users to create and view their own incident reports.
    """
    serializer_class = IncidentReportSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        This view only returns reports for the currently authenticated user.
        """
        return IncidentReport.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        """
        Automatically set the user to the logged-in user when creating a report.
        """
        serializer.save(user=self.request.user)


class UserIncidentReportListView(generics.ListAPIView):
    """
    An admin-only endpoint to view all incident reports for a specific user.
    """
    serializer_class = IncidentReportSerializer
    permission_classes = [permissions.IsAdminUser] # Ensures only admins can access

    def get_queryset(self):
        """
        Filters reports based on the user ID provided in the URL.
        """
        # Get the user_id from the URL, which is passed in by the URL pattern
        user_id = self.kwargs['user_id']
        # Find the user with that ID
        CustomUser = get_user_model()
        target_user = get_object_or_404(CustomUser, id=user_id)
        # Return all reports for that user
        return IncidentReport.objects.filter(user=target_user)
