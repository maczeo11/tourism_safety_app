// lib/home_screen.dart

import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'report_incident_screen.dart'; // Import the new screen
import 'unsafe_geofence_screen.dart';
import 'package:provider/provider.dart';
import 'auth_providers.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.03),
              colorScheme.secondary.withOpacity(0.02),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tourist Safety',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          'Secure & Protected',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.logout, color: colorScheme.primary),
                        onPressed: () async {
                          await Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).logout();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Dashboard Cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    children: [
                      _buildVerticalCard(
                        context,
                        'Blockchain UUID',
                        'Generate & manage your secure identity',
                        Icons.fingerprint,
                        const Color(0xFF2563EB), // Modern Blue
                        () => _showUUIDDialog(context),
                      ),
                      const SizedBox(height: 16),
                      _buildVerticalCard(
                        context,
                        'Verify Block',
                        'Check blockchain integrity',
                        Icons.verified_user,
                        const Color(0xFF059669), // Emerald Green
                        () => _showBlockVerificationDialog(context),
                      ),
                      const SizedBox(height: 16),
                      _buildVerticalCard(
                        context,
                        'Live Location',
                        'Track your current position',
                        Icons.location_on,
                        const Color(0xFFDC2626), // Red Rose
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildVerticalCard(
                        context,
                        'Report Incident',
                        'Report safety concerns',
                        Icons.report_problem,
                        const Color(0xFFEA580C), // Orange
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportIncidentScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildVerticalCard(
                        context,
                        'Geofence Alerts',
                        'Unsafe location warnings',
                        Icons.shield,
                        const Color(0xFF7C3AED), // Purple
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UnsafeGeofenceScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.surface, accentColor.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withOpacity(0.15),
                        accentColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),

                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: accentColor.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUUIDDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const UUIDDialog();
      },
    );
  }

  void _showBlockVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const BlockVerificationDialog();
      },
    );
  }
}

class UUIDDialog extends StatefulWidget {
  const UUIDDialog({super.key});

  @override
  State<UUIDDialog> createState() => _UUIDDialogState();
}

class _UUIDDialogState extends State<UUIDDialog> {
  String? _currentUUID;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLatestUUID();
  }

  Future<void> _loadLatestUUID() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.getLatestUUID();
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _currentUUID = response['data']['uuid_value'];
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'No UUID found';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load UUID: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateNewUUID() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.generateUUID();
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _currentUUID = response['data']['uuid_value'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New UUID generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to generate UUID';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to generate UUID: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    if (_currentUUID != null) {
      // Note: You'll need to add flutter/services to your pubspec.yaml for Clipboard
      // For now, we'll just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('UUID: $_currentUUID'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blockchain UUID',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Secure Identity Management',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(40),
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ),
                  ],
                ),
              )
            else if (_currentUUID != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Blockchain UUID',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: SelectableText(
                        _currentUUID!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No UUID available',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Description
            Text(
              'This UUID is stored in a blockchain and linked to your account. It can be used for secure identification and verification.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _loadLatestUUID,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Refresh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _generateNewUUID,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Generate New'),
                  ),
                ),
              ],
            ),

            if (_currentUUID != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy UUID'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BlockVerificationDialog extends StatefulWidget {
  const BlockVerificationDialog({super.key});

  @override
  State<BlockVerificationDialog> createState() =>
      _BlockVerificationDialogState();
}

class _BlockVerificationDialogState extends State<BlockVerificationDialog> {
  final TextEditingController _blockIdController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _verificationResult;

  @override
  void dispose() {
    _blockIdController.dispose();
    super.dispose();
  }

  Future<void> _verifyBlock() async {
    final blockIdText = _blockIdController.text.trim();
    if (blockIdText.isEmpty) {
      setState(() {
        _error = 'Please enter a Block ID';
      });
      return;
    }

    final blockId = int.tryParse(blockIdText);
    if (blockId == null) {
      setState(() {
        _error = 'Please enter a valid Block ID (number)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _verificationResult = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.verifyBlock(blockId);

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _verificationResult = response['data'];
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Block verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to verify block: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blockchain Verification',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Verify Block Integrity',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Input Field
            TextField(
              controller: _blockIdController,
              decoration: InputDecoration(
                labelText: 'Block ID',
                hintText: 'Enter block ID to verify',
                prefixIcon: Icon(Icons.fingerprint, color: colorScheme.primary),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Content
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(40),
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ),
                  ],
                ),
              )
            else if (_verificationResult != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      _verificationResult!['hash_valid'] == true &&
                          _verificationResult!['chain_valid'] == true
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _verificationResult!['hash_valid'] == true &&
                            _verificationResult!['chain_valid'] == true
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _verificationResult!['hash_valid'] == true &&
                                  _verificationResult!['chain_valid'] == true
                              ? Icons.check_circle_outline
                              : Icons.warning_outlined,
                          color:
                              _verificationResult!['hash_valid'] == true &&
                                  _verificationResult!['chain_valid'] == true
                              ? Colors.green[600]
                              : Colors.orange[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Block Verification Results',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                _verificationResult!['hash_valid'] == true &&
                                    _verificationResult!['chain_valid'] == true
                                ? Colors.green[600]
                                : Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Results Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 8,
                      children: [
                        _buildResultCard(
                          'Block ID',
                          _verificationResult!['block_id'].toString(),
                        ),
                        _buildResultCard(
                          'Block Index',
                          _verificationResult!['block_index'].toString(),
                        ),
                        _buildResultCard(
                          'Hash Valid',
                          _verificationResult!['hash_valid'] ? 'Yes' : 'No',
                        ),
                        _buildResultCard(
                          'Chain Valid',
                          _verificationResult!['chain_valid'] ? 'Yes' : 'No',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Block Hash
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Block Hash:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _verificationResult!['block_hash'],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_verificationResult!['uuids_in_block'].isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'UUIDs in Block:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_verificationResult!['uuids_in_block'] as List).map(
                        (uuid) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SelectableText(
                                  '${uuid['uuid']} (${uuid['user']})',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Description
            Text(
              'Enter a Block ID to verify its integrity in the blockchain. This will check hash validity and chain continuity.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _verifyBlock,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Verify Block'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _blockIdController.clear();
                      setState(() {
                        _error = null;
                        _verificationResult = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
