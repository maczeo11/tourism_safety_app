# users/views.py

from rest_framework.views import APIView
from rest_framework.viewsets import ModelViewSet
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth import get_user_model
from .serializers import RegisterSerializer, LoginSerializer, UserSerializer

CustomUser = get_user_model()


#auth views


class RegisterView(APIView):
    """
    Register a new user.
    Public endpoint — no authentication required.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            login(request, user)  # Auto-login after registration
            return Response({
                'success': True,
                'user': UserSerializer(user).data
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    """
    Log in an existing user.
    Public endpoint — no authentication required.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            username = serializer.validated_data['username']
            password = serializer.validated_data['password']
            user = authenticate(request, username=username, password=password)

            if user is not None:
                login(request, user)
                return Response({
                    'success': True,
                    'user': UserSerializer(user).data
                })
            else:
                return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LogoutView(APIView):
    """
    Log out the current user.
    Requires authentication.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        logout(request)
        return Response({'success': True, 'message': 'Logged out'})


class MeView(APIView):
    """
    Get current user's profile.
    Requires authentication.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)


class UserViewSet(ModelViewSet):
    """
    A viewset for viewing and editing user instances.

    Permissions:
    - list: Authenticated users see themselves; admins see all.
    - create: Admins only (public signup handled via /register/).
    - retrieve: Authenticated users can view themselves or any if admin.
    - update: Users can update themselves; admins can update anyone.
    - delete: Users can delete themselves; admins can delete anyone.
    """
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        Limit queryset based on user role.
        Regular users only see themselves.
        Admins see all users.
        """
        if self.request.user.is_staff:
            return CustomUser.objects.all()
        return CustomUser.objects.filter(id=self.request.user.id)

    def get_permissions(self):
        """
        Customize permissions per action.
        """
        if self.action == 'create':
            # Only admins can create via this endpoint (public signup is via /register/)
            permission_classes = [IsAdminUser]
        elif self.action in ['update', 'partial_update', 'destroy']:
            # Authenticated users can update/delete — queryset restricts to self unless admin
            permission_classes = [IsAuthenticated]
        else:
            # For list, retrieve — authenticated required
            permission_classes = [IsAuthenticated]
        return [permission() for permission in permission_classes]

    def perform_destroy(self, instance):
        """
        Optional: Add logic before deletion.
        Example: Prevent self-delete? Log deletion? Etc.
        """
        # Allow self-delete for regular users, full delete for admins
        if instance == self.request.user and not self.request.user.is_staff:
            # You can optionally prevent self-delete by raising an exception:
            # raise PermissionDenied("You cannot delete your own account.")
            pass
        instance.delete()