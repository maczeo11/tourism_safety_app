 

# Create your models here.
# incidents/models.py

from django.db import models
from django.conf import settings

class IncidentReport(models.Model):
    """
    Represents an incident report filed by a user.
    It is linked to the active user model defined in the project's settings.
    """
    # This correctly links the report to your CustomUser model
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='incident_reports'
    )

    # A flexible field to store any kind of incident data
    details = models.JSONField()

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Report by {self.user.username} at {self.created_at.strftime('%Y-%m-%d %H:%M')}"