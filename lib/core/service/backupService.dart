import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sms_sender/feature/homeSceen/data/group_model.dart';
import 'package:sms_sender/feature/homeSceen/data/contact_model.dart';

/// Enhanced Backup Service with validation, metadata, and auto-cleanup
class BackupService {
  static const String _tag = 'BackupService';
  static const String _backupDir = 'sms_backups';
  static const String _metadataFile = 'backup_metadata.json';
  static const int _maxBackups = 10;

  // ============================================
  // EXPORT BACKUP
  // ============================================

  /// Export all groups to JSON backup file with validation and metadata
  /// [autoCleanup] - Automatically remove old backups if max count exceeded
  /// [validate] - Validate backup integrity after creation
  static Future<BackupFile> exportBackup({
    bool autoCleanup = true,
    bool validate = true,
  }) async {
    try {
      final box = Hive.box<GroupModel>("groups");

      if (box.isEmpty) {
        throw BackupException('No groups to backup');
      }

      developer.log('Starting backup with ${box.length} groups', name: _tag);

      // Prepare backup data with metadata
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'data_count': {
          'groups': box.length,
          'total_contacts': box.values.fold<int>(
            0,
            (sum, group) => sum + group.contacts.length,
          ),
        },
        'groups': box.values.map((group) {
          return {
            'name': group.name,
            'contacts': group.contacts
                .map(
                  (contact) => {'name': contact.name, 'phone': contact.phone},
                )
                .toList(),
          };
        }).toList(),
      };

      // Convert to JSON
      final jsonString = jsonEncode(backupData);

      // Calculate checksum for integrity verification
      final checksum = md5.convert(utf8.encode(jsonString)).toString();

      // Get backup directory
      final backupDirPath = await _getBackupDirectory();

      // Create filename with timestamp
      final timestamp = _generateTimestamp();
      final backupFileName = 'backup_$timestamp.json';
      final backupFile = File('$backupDirPath/$backupFileName');

      // Write backup file
      await backupFile.writeAsString(jsonString);

      // Get file statistics
      final fileSize = await backupFile.length();
      final modified = DateTime.now();
      final totalContacts = box.values.fold<int>(
        0,
        (sum, group) => sum + group.contacts.length,
      );

      // Create backup file object
      final backup = BackupFile(
        path: backupFile.path,
        name: backupFileName,
        fileSize: fileSize,
        modified: modified,
        checksum: checksum,
        groupCount: box.length,
        contactCount: totalContacts,
        status: 'pending_validation',
      );

      // Validate backup integrity
      if (validate) {
        final isValid = await _validateBackup(backupFile.path);
        if (!isValid) {
          await backupFile.delete();
          throw BackupException('Backup validation failed');
        }
        backup.status = 'completed';
      }

      // Save backup metadata
      await _saveBackupMetadata(backup);

      // Auto cleanup old backups
      if (autoCleanup) {
        await _cleanupOldBackups();
      }

      developer.log(
        'Backup created: ${backupFile.path} (${_formatFileSize(fileSize)})',
        name: _tag,
      );

      return backup;
    } catch (e) {
      developer.log('Export failed: $e', name: _tag);
      rethrow;
    }
  }

  // ============================================
  // IMPORT BACKUP
  // ============================================

  /// Import backup from file with validation and merge options
  /// [filePath] - Path to backup file
  /// [merge] - If true, merge with existing data; if false, replace only new groups
  /// [validate] - Validate backup before importing
  static Future<BackupFile> importBackup(
    String filePath, {
    bool merge = true,
    bool validate = true,
  }) async {
    try {
      final backupFile = File(filePath);

      if (!await backupFile.exists()) {
        throw BackupException('Backup file not found: $filePath');
      }

      // Validate file format
      if (!filePath.endsWith('.json')) {
        throw BackupException('Invalid backup format. Expected .json file');
      }

      developer.log('Importing backup: $filePath', name: _tag);

      // Read and parse JSON
      final jsonString = await backupFile.readAsString();

      if (jsonString.isEmpty) {
        throw BackupException('Backup file is empty');
      }

      late Map<String, dynamic> backupData;
      try {
        backupData = jsonDecode(jsonString);
      } catch (e) {
        throw BackupException('Invalid JSON format: $e');
      }

      // Validate backup structure
      _validateBackupStructure(backupData);

      // Validate backup integrity if requested
      if (validate) {
        final isValid = await _validateBackup(filePath);
        if (!isValid) {
          throw BackupException('Backup validation failed');
        }
      }

      final box = Hive.box<GroupModel>("groups");
      int importedGroups = 0;
      int skippedGroups = 0;
      int mergedContacts = 0;

      // Import groups
      final groups = backupData['groups'] as List? ?? [];

      for (var groupData in groups) {
        try {
          final groupName = groupData['name']?.toString() ?? 'Unknown';
          final contactsList = groupData['contacts'] as List? ?? [];

          final contacts = contactsList
              .map(
                (c) => ContactModel(
                  name: c['name']?.toString() ?? 'Unknown',
                  phone: c['phone']?.toString() ?? '',
                ),
              )
              .toList();

          final group = GroupModel(name: groupName, contacts: contacts);

          // Check if group already exists
          final existingIndex = box.values.toList().indexWhere(
            (g) => g.name.toLowerCase() == groupName.toLowerCase(),
          );

          if (existingIndex != -1) {
            if (merge) {
              // Merge mode: add only new contacts
              final existingGroup = box.getAt(existingIndex)!;
              int newContacts = 0;

              for (var contact in contacts) {
                final contactExists = existingGroup.contacts.any(
                  (c) => c.phone == contact.phone,
                );
                if (!contactExists) {
                  existingGroup.contacts.add(contact);
                  newContacts++;
                }
              }

              if (newContacts > 0) {
                await existingGroup.save();
                importedGroups++;
                mergedContacts += newContacts;
              } else {
                skippedGroups++;
              }
            } else {
              skippedGroups++;
            }
          } else {
            // New group - add it
            await box.add(group);
            importedGroups++;
          }
        } catch (e) {
          developer.log('Error importing group: $e', name: _tag);
          skippedGroups++;
          continue;
        }
      }

      final backup = BackupFile(
        path: filePath,
        name: backupFile.uri.pathSegments.last,
        fileSize: await backupFile.length(),
        modified: backupFile.statSync().modified,
        groupCount: importedGroups,
        contactCount: mergedContacts,
        status: 'imported',
      );

      developer.log(
        'Backup imported: $importedGroups groups, $mergedContacts contacts merged, $skippedGroups skipped',
        name: _tag,
      );

      return backup;
    } catch (e) {
      developer.log('Import failed: $e', name: _tag);
      rethrow;
    }
  }

  // ============================================
  // BACKUP MANAGEMENT
  // ============================================

  /// Get list of available backups sorted by date (newest first)
  static Future<List<BackupFile>> getAvailableBackups() async {
    try {
      final backupDirPath = await _getBackupDirectory();
      final backupDir = Directory(backupDirPath);

      if (!await backupDir.exists()) {
        return [];
      }

      final files = backupDir.listSync();
      final backupFiles = <BackupFile>[];

      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          final stat = file.statSync();
          backupFiles.add(
            BackupFile(
              path: file.path,
              name: file.uri.pathSegments.last,
              fileSize: stat.size,
              modified: stat.modified,
            ),
          );
        }
      }

      // Sort by modified date (newest first)
      backupFiles.sort((a, b) => b.modified.compareTo(a.modified));
      return backupFiles;
    } catch (e) {
      developer.log('Error getting backups: $e', name: _tag);
      return [];
    }
  }

  /// Delete a backup file
  /// Returns true if deletion successful
  static Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        developer.log('Backup deleted: $filePath', name: _tag);

        // Update metadata
        await _removeBackupMetadata(filePath);

        return true;
      }
      return false;
    } catch (e) {
      developer.log('Delete failed: $e', name: _tag);
      throw BackupException('Failed to delete backup: $e');
    }
  }

  /// Delete all backups
  static Future<int> deleteAllBackups() async {
    try {
      final backups = await getAvailableBackups();
      int deleted = 0;

      for (var backup in backups) {
        try {
          await deleteBackup(backup.path);
          deleted++;
        } catch (e) {
          developer.log('Error deleting backup: $e', name: _tag);
        }
      }

      return deleted;
    } catch (e) {
      developer.log('Error deleting all backups: $e', name: _tag);
      throw BackupException('Failed to delete backups: $e');
    }
  }

  /// Get backup statistics
  static Future<BackupStats> getBackupStats() async {
    try {
      final backups = await getAvailableBackups();

      if (backups.isEmpty) {
        return BackupStats(
          totalBackups: 0,
          totalSize: 0,
          totalGroups: 0,
          totalContacts: 0,
        );
      }

      int totalSize = 0;
      int totalGroups = 0;
      int totalContacts = 0;

      for (var backup in backups) {
        totalSize += backup.fileSize;
        totalGroups += backup.groupCount;
        totalContacts += backup.contactCount;
      }

      return BackupStats(
        totalBackups: backups.length,
        totalSize: totalSize,
        totalGroups: totalGroups,
        totalContacts: totalContacts,
        oldestBackup: backups.isNotEmpty ? backups.last.modified : null,
        newestBackup: backups.isNotEmpty ? backups.first.modified : null,
      );
    } catch (e) {
      developer.log('Error getting backup stats: $e', name: _tag);
      throw BackupException('Failed to get backup stats: $e');
    }
  }

  // ============================================
  // PRIVATE HELPER METHODS
  // ============================================

  /// Get backup directory path, create if doesn't exist
  static Future<String> _getBackupDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final backupDirPath = '${documentsDir.path}/$_backupDir';
    final backupDir = Directory(backupDirPath);

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
      developer.log('Backup directory created: $backupDirPath', name: _tag);
    }

    return backupDirPath;
  }

  /// Generate timestamp for backup filename
  static String _generateTimestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  /// Validate backup structure
  static void _validateBackupStructure(Map<String, dynamic> data) {
    if (!data.containsKey('groups')) {
      throw BackupException('Invalid backup format: missing "groups" field');
    }

    if (!data.containsKey('timestamp')) {
      throw BackupException('Invalid backup format: missing "timestamp" field');
    }

    if (data['groups'] is! List) {
      throw BackupException('Invalid backup format: "groups" must be a list');
    }

    for (var group in data['groups'] as List) {
      if (group is! Map) {
        throw BackupException('Invalid backup format: group must be a map');
      }

      if (!group.containsKey('name') || !group.containsKey('contacts')) {
        throw BackupException(
          'Invalid backup format: group missing "name" or "contacts"',
        );
      }

      if (group['contacts'] is! List) {
        throw BackupException('Invalid backup format: contacts must be a list');
      }
    }
  }

  /// Validate backup file integrity
  static Future<bool> _validateBackup(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();

      if (jsonString.isEmpty) return false;

      // Try to decode JSON
      final data = jsonDecode(jsonString);

      // Validate structure
      _validateBackupStructure(data as Map<String, dynamic>);

      return true;
    } catch (e) {
      developer.log('Backup validation failed: $e', name: _tag);
      return false;
    }
  }

  /// Save backup metadata
  static Future<void> _saveBackupMetadata(BackupFile backup) async {
    try {
      final backupDirPath = await _getBackupDirectory();
      final metadataFile = File('$backupDirPath/$_metadataFile');

      List<Map<String, dynamic>> metadataList = [];

      // Load existing metadata
      if (await metadataFile.exists()) {
        final jsonString = await metadataFile.readAsString();
        final data = jsonDecode(jsonString) as List?;
        metadataList = data?.cast<Map<String, dynamic>>() ?? [];
      }

      // Add new metadata
      metadataList.add({
        'name': backup.name,
        'path': backup.path,
        'fileSize': backup.fileSize,
        'modified': backup.modified.toIso8601String(),
        'groupCount': backup.groupCount,
        'contactCount': backup.contactCount,
        'checksum': backup.checksum,
        'status': backup.status,
      });

      // Save metadata
      await metadataFile.writeAsString(jsonEncode(metadataList));
      developer.log('Backup metadata saved', name: _tag);
    } catch (e) {
      developer.log('Error saving metadata: $e', name: _tag);
    }
  }

  /// Remove backup from metadata
  static Future<void> _removeBackupMetadata(String filePath) async {
    try {
      final backupDirPath = await _getBackupDirectory();
      final metadataFile = File('$backupDirPath/$_metadataFile');

      if (!await metadataFile.exists()) return;

      final jsonString = await metadataFile.readAsString();
      final data = jsonDecode(jsonString) as List?;
      final metadataList = data?.cast<Map<String, dynamic>>() ?? [];

      // Remove backup from metadata
      metadataList.removeWhere((m) => m['path'] == filePath);

      // Save updated metadata
      if (metadataList.isEmpty) {
        await metadataFile.delete();
      } else {
        await metadataFile.writeAsString(jsonEncode(metadataList));
      }
    } catch (e) {
      developer.log('Error removing metadata: $e', name: _tag);
    }
  }

  /// Cleanup old backups if count exceeds max
  static Future<void> _cleanupOldBackups() async {
    try {
      final backups = await getAvailableBackups();

      if (backups.length > _maxBackups) {
        final toDelete = backups.sublist(_maxBackups);
        int deleted = 0;

        for (var backup in toDelete) {
          try {
            final file = File(backup.path);
            if (await file.exists()) {
              await file.delete();
              await _removeBackupMetadata(backup.path);
              deleted++;
            }
          } catch (e) {
            developer.log('Error deleting old backup: $e', name: _tag);
          }
        }

        developer.log('Cleaned up $deleted old backups', name: _tag);
      }
    } catch (e) {
      developer.log('Error during cleanup: $e', name: _tag);
    }
  }

  /// Format file size in human-readable format
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // ============================================
  // PUBLIC UTILITY METHODS
  // ============================================

  /// Format file size in human-readable format
  static String formatFileSize(int bytes) {
    return _formatFileSize(bytes);
  }

  /// Get formatted date string
  static String getFormattedDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ============================================
// MODELS
// ============================================

/// Model for backup file information
class BackupFile {
  final String path;
  final String name;
  final int fileSize;
  final DateTime modified;
  final int groupCount;
  final int contactCount;
  final String? checksum;
  String? status;

  BackupFile({
    required this.path,
    required this.name,
    required this.fileSize,
    required this.modified,
    this.groupCount = 0,
    this.contactCount = 0,
    this.checksum,
    this.status,
  });

  @override
  String toString() =>
      'BackupFile($name - $groupCount groups, $contactCount contacts, ${BackupService._formatFileSize(fileSize)})';
}

/// Model for backup statistics
class BackupStats {
  final int totalBackups;
  final int totalSize;
  final int totalGroups;
  final int totalContacts;
  final DateTime? oldestBackup;
  final DateTime? newestBackup;

  BackupStats({
    required this.totalBackups,
    required this.totalSize,
    required this.totalGroups,
    required this.totalContacts,
    this.oldestBackup,
    this.newestBackup,
  });

  @override
  String toString() =>
      'BackupStats($totalBackups backups, ${BackupService._formatFileSize(totalSize)}, '
      '$totalGroups groups, $totalContacts contacts)';
}

/// Custom exception for backup operations
class BackupException implements Exception {
  final String message;
  BackupException(this.message);

  @override
  String toString() => 'BackupException: $message';
}
