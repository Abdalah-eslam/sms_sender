/// Backup configuration constants and utilities
class BackupConfig {
  // Backup settings
  static const String backupDirName = 'sms_backups';
  static const String backupFileExtension = '.json';
  static const String backupFilePrefix = 'backup_';

  // Auto backup settings (for future implementation)
  static const bool enableAutoBackup = false;
  static const int autoBackupIntervalDays = 7; // Auto-backup every 7 days

  // Backup limits
  static const int maxBackupsToKeep = 10; // Keep only last 10 backups
  static const int maxBackupSizeMB = 50; // Max file size in MB

  /// Get backup filename with timestamp
  static String generateBackupFilename() {
    final timestamp = DateTime.now().toString().replaceAll(
      RegExp(r'[:.(-)]'),
      '-',
    );
    return '$backupFilePrefix$timestamp$backupFileExtension';
  }
}
