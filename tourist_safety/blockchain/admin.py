# blockchain/admin.py

from django.contrib import admin
from .models import Blockchain, Block, UserUUID


@admin.register(Blockchain)
class BlockchainAdmin(admin.ModelAdmin):
    list_display = ['name', 'created_at', 'is_active']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name']
    readonly_fields = ['created_at']


@admin.register(Block)
class BlockAdmin(admin.ModelAdmin):
    list_display = ['blockchain', 'index', 'timestamp', 'hash_short', 'nonce']
    list_filter = ['blockchain', 'timestamp']
    search_fields = ['hash']
    readonly_fields = ['timestamp', 'hash']
    
    def hash_short(self, obj):
        return f"{obj.hash[:10]}..." if obj.hash else "N/A"
    hash_short.short_description = "Hash (Short)"


@admin.register(UserUUID)
class UserUUIDAdmin(admin.ModelAdmin):
    list_display = ['user', 'uuid_value', 'block_index', 'created_at', 'is_active']
    list_filter = ['is_active', 'created_at', 'block__blockchain']
    search_fields = ['user__username', 'user__email', 'uuid_value']
    readonly_fields = ['created_at', 'uuid_value']
    
    def block_index(self, obj):
        return obj.block.index
    block_index.short_description = "Block Index"