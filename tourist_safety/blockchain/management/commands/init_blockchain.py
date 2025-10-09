# blockchain/management/commands/init_blockchain.py

from django.core.management.base import BaseCommand
from blockchain.models import BlockchainService


class Command(BaseCommand):
    help = 'Initialize the blockchain system'

    def handle(self, *args, **options):
        try:
            # Create the main blockchain
            blockchain = BlockchainService.get_or_create_blockchain()
            
            self.stdout.write(
                self.style.SUCCESS(
                    f'Successfully initialized blockchain: {blockchain.name}'
                )
            )
            
            # Get blockchain info
            info = BlockchainService.get_blockchain_info()
            self.stdout.write(f'Blockchain Info:')
            self.stdout.write(f'  - Name: {info["blockchain_name"]}')
            self.stdout.write(f'  - Total Blocks: {info["total_blocks"]}')
            self.stdout.write(f'  - Total UUIDs: {info["total_uuids"]}')
            self.stdout.write(f'  - Created: {info["created_at"]}')
            
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Error initializing blockchain: {str(e)}')
            )
