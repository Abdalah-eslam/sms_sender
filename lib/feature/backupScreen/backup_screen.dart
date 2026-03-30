import 'package:flutter/material.dart';
import 'package:sms_sender/core/service/backupService.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  List<BackupFile> backups = [];
  bool isLoading = false;
  BackupStats? stats;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => isLoading = true);
    try {
      final loadedBackups = await BackupService.getAvailableBackups();
      final backupStats = await BackupService.getBackupStats();
      setState(() {
        backups = loadedBackups;
        stats = backupStats;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Error loading backups: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => isLoading = true);
    try {
      await BackupService.exportBackup(autoCleanup: true, validate: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Backup created successfully'),
          duration: Duration(seconds: 2),
        ),
      );

      await _loadBackups();
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to create backup: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _restoreBackup(BackupFile backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will import all contacts and groups from the backup.',
              ),
              const SizedBox(height: 12),
              Text(
                'Groups: ${backup.groupCount} | Contacts: ${backup.contactCount}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Existing groups with the same name will be merged.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Restore',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      await BackupService.importBackup(
        backup.path,
        merge: true,
        validate: true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Backup restored successfully'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true); // Refresh parent screen
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to restore backup: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteBackup(BackupFile backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Backup'),
          content: Text('Delete backup "${backup.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await BackupService.deleteBackup(backup.path);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✓ Backup deleted')));

      await _loadBackups();
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to delete backup: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Section
                    if (stats != null && stats!.totalBackups > 0)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Backup Statistics',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _StatItem(
                                    label: 'Total Backups',
                                    value: stats!.totalBackups.toString(),
                                  ),
                                  _StatItem(
                                    label: 'Total Size',
                                    value: BackupService.formatFileSize(
                                      stats!.totalSize,
                                    ),
                                  ),
                                  _StatItem(
                                    label: 'Groups',
                                    value: stats!.totalGroups.toString(),
                                  ),
                                  _StatItem(
                                    label: 'Contacts',
                                    value: stats!.totalContacts.toString(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Create Backup Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _createBackup,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Create Backup Now'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Available Backups Section
                    const Text(
                      'Available Backups',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (backups.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.backup_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No backups yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: backups.length,
                        itemBuilder: (context, index) {
                          final backup = backups[index];
                          final formattedDate = BackupService.getFormattedDate(
                            backup.modified,
                          );
                          final fileSize = BackupService.formatFileSize(
                            backup.fileSize,
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(
                                Icons.backup,
                                color: Colors.blue,
                                size: 28,
                              ),
                              title: Text(
                                backup.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Date: $formattedDate',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Size: $fileSize | Groups: ${backup.groupCount} | Contacts: ${backup.contactCount}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: const Row(
                                      children: [
                                        Icon(Icons.restore, size: 20),
                                        SizedBox(width: 10),
                                        Text('Restore'),
                                      ],
                                    ),
                                    onTap: () => _restoreBackup(backup),
                                  ),
                                  PopupMenuItem(
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _deleteBackup(backup),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Statistics item widget
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
