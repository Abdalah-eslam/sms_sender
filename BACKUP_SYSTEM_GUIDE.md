# SMS Sender Backup System - Complete Guide

## 📋 Overview

The SMS Sender app now has an **advanced backup and restore system** with the following features:

- ✅ **Local Storage** - Backups saved to device's Documents folder
- ✅ **Data Compression** - Backups are stored in JSON format (optimized)
- ✅ **Integrity Validation** - MD5 checksums verify data integrity
- ✅ **Metadata Tracking** - Detailed backup information stored
- ✅ **Auto-Cleanup** - Automatically removes old backups (keeps last 10)
- ✅ **Merge Support** - Intelligently merge backups with existing data
- ✅ **Error Handling** - Detailed error messages for troubleshooting
- ✅ **Statistics** - Track total backups, size, groups, and contacts

---

## 🗂️ Local Storage Structure

```
Documents/
└── sms_backups/                    # Backup directory
    ├── backup_20260330_102530.json # Backup file (with timestamp)
    ├── backup_20260329_153245.json
    └── backup_metadata.json        # Metadata file
```

**Storage Location:**
- **Android:** `/data/data/[app]/files/sms_backups/`
- **iOS:** `Documents/sms_backups/`

---

## 📦 Backup File Format

Backup files are JSON files with the following structure:

```json
{
  "timestamp": "2026-03-30T10:25:35.123456",
  "app_version": "1.0.0",
  "data_count": {
    "groups": 5,
    "total_contacts": 42
  },
  "groups": [
    {
      "name": "Family",
      "contacts": [
        {
          "name": "Mom",
          "phone": "+1234567890"
        },
        {
          "name": "Dad",
          "phone": "+0987654321"
        }
      ]
    },
    {
      "name": "Work",
      "contacts": [...]
    }
  ]
}
```

---

## 🔄 Backup Operations

### 1. Create Backup

**From UI:**
```
Home Screen → Backup Icon (⬆️) → Create Backup Now
```

**Programmatically:**
```dart
try {
  final backup = await BackupService.exportBackup(
    autoCleanup: true,   // Remove old backups
    validate: true,      // Validate after creation
  );
  print('Backup created: ${backup.name}');
} catch (e) {
  print('Error: $e');
}
```

**What Happens:**
1. Reads all groups and contacts from Hive database
2. Converts to JSON format
3. Calculates MD5 checksum
4. Saves to `Documents/sms_backups/backup_TIMESTAMP.json`
5. Validates data integrity
6. Saves metadata
7. Auto-cleans old backups (keeps last 10)

### 2. Restore Backup

**From UI:**
```
Home Screen → Backup Icon (⬆️) → Select Backup → Tap Menu (⋮) → Restore
```

**Programmatically:**
```dart
try {
  final backup = await BackupService.importBackup(
    filePath,
    merge: true,      // Merge with existing data
    validate: true,   // Validate before restore
  );
  print('Restored ${backup.groupCount} groups');
} catch (e) {
  print('Error: $e');
}
```

**Merge Mode (merge: true):**
- Existing groups preserved
- New contacts add to existing groups
- Duplicate phone numbers skipped
- Recommended for incremental backups

**Replace Mode (merge: false):**
- Only adds new groups
- Skips existing groups
- Good for clean imports

### 3. Delete Backup

**From UI:**
```
Home Screen → Backup Icon (⬆️) → Select Backup → Tap Menu (⋮) → Delete
```

**Programmatically:**
```dart
try {
  final deleted = await BackupService.deleteBackup(filePath);
  print('Deleted: $deleted');
} catch (e) {
  print('Error: $e');
}
```

---

## 📊 Backup Statistics

Get detailed statistics about all backups:

```dart
try {
  final stats = await BackupService.getBackupStats();
  print('Total Backups: ${stats.totalBackups}');
  print('Total Size: ${BackupService.formatFileSize(stats.totalSize)}');
  print('Total Groups: ${stats.totalGroups}');
  print('Total Contacts: ${stats.totalContacts}');
  print('Oldest: ${stats.oldestBackup}');
  print('Newest: ${stats.newestBackup}');
} catch (e) {
  print('Error: $e');
}
```

---

## 🔍 Available Methods

### Backup Service Methods

```dart
// Create backup
Future<BackupFile> exportBackup({
  bool autoCleanup = true,
  bool validate = true,
})

// Import backup
Future<BackupFile> importBackup(
  String filePath, {
  bool merge = true,
  bool validate = true,
})

// Get list of backups
Future<List<BackupFile>> getAvailableBackups()

// Delete backup
Future<bool> deleteBackup(String filePath)

// Delete all backups
Future<int> deleteAllBackups()

// Get statistics
Future<BackupStats> getBackupStats()

// Format utilities
static String formatFileSize(int bytes)
static String getFormattedDate(DateTime date)
```

---

## 📋 BackupFile Model

```dart
class BackupFile {
  final String path;              // Full file path
  final String name;              // Filename
  final int fileSize;             // Size in bytes
  final DateTime modified;        // Creation/modification time
  final int groupCount;           // Number of groups
  final int contactCount;         // Number of contacts
  final String? checksum;         // MD5 checksum
  final String? status;           // 'completed', 'pending', etc.
}
```

---

## 📈 BackupStats Model

```dart
class BackupStats {
  final int totalBackups;         // Total number of backups
  final int totalSize;            // Combined size in bytes
  final int totalGroups;          // Total groups across all backups
  final int totalContacts;        // Total contacts across all backups
  final DateTime? oldestBackup;   // Oldest backup date
  final DateTime? newestBackup;   // Newest backup date
}
```

---

## ⚙️ Configuration

Configuration is set in `lib/core/config/backup_config.dart`:

```dart
class BackupConfig {
  // Backup settings
  static const String backupDirName = 'sms_backups';
  static const String backupFileExtension = '.json';
  static const String backupFilePrefix = 'backup_';
  
  // Auto backup settings
  static const bool enableAutoBackup = false;
  static const int autoBackupIntervalDays = 7;
  
  // Backup limits
  static const int maxBackupsToKeep = 10;
  static const int maxBackupSizeMB = 50;
}
```

---

## 🛡️ Data Integrity

### Validation Checks

The backup system validates:

1. **JSON Format** - Ensures valid JSON syntax
2. **Structure Validation** - Checks required fields
3. **Data Integrity** - Verifies all groups and contacts
4. **Checksum Verification** - MD5 hash validation

### Error Handling

Custom `BackupException` provides detailed error messages:

```dart
try {
  await BackupService.importBackup(filePath);
} on BackupException catch (e) {
  print('Backup error: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

---

## 💾 Storage Information

### Approximate Sizes

- Empty backup: ~200 bytes
- 5 groups with 50 contacts: ~3-5 KB
- 20 groups with 200 contacts: ~15-20 KB
- 100 groups with 1000 contacts: ~80-100 KB

### Auto-Cleanup

- Keeps last 10 backups by default
- Older backups deleted automatically
- Configurable in `BackupConfig`

---

## 🔄 Auto-Backup Feature (Future)

To enable automatic backups on app startup:

```dart
// In main.dart
await _ensureAutomaticBackup();

Future<void> _ensureAutomaticBackup() async {
  final prefs = await SharedPreferences.getInstance();
  final lastBackupTime = prefs.getInt('last_backup_time') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  
  // Backup if 7 days passed
  if (now - lastBackupTime > Duration(days: 7).inMilliseconds) {
    try {
      await BackupService.exportBackup();
      await prefs.setInt('last_backup_time', now);
    } catch (e) {
      developer.log('Auto backup failed: $e');
    }
  }
}
```

---

## 🚀 Usage Examples

### Example 1: Create and Share Backup

```dart
try {
  final backup = await BackupService.exportBackup();
  final file = File(backup.path);
  
  // Share backup file
  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'SMS Sender Backup - ${backup.name}',
  );
} catch (e) {
  print('Error: $e');
}
```

### Example 2: Backup on App Exit

```dart
@override
void dispose() {
  // Create backup when closing app
  BackupService.exportBackup();
  super.dispose();
}
```

### Example 3: Scheduled Backups

```dart
// Create backup silently every hour
Timer.periodic(Duration(hours: 1), (_) async {
  try {
    await BackupService.exportBackup(autoCleanup: true);
    developer.log('Scheduled backup created');
  } catch (e) {
    developer.log('Scheduled backup failed: $e');
  }
});
```

---

## ❌ Troubleshooting

### Backup Creation Fails

**Error:** `"No groups to backup"`
- **Solution:** Create at least one group before backup

**Error:** `"Backup validation failed"`
- **Solution:** Check device storage space, try again

### Restore Fails

**Error:** `"Backup file not found"`
- **Solution:** File may have been moved, check path

**Error:** `"Invalid JSON format"`
- **Solution:** Backup file corrupted, try another backup

### Storage Issues

**Problem:** Low storage space
- **Solution:** Delete old backups, increase device storage

---

## 🔐 Security Considerations

### Current Implementation
- JSON files stored locally only
- No encryption by default
- MD5 checksum for integrity

### Enhanced Security (Optional)

To add encryption:
```dart
import 'package:encrypt/encrypt.dart' as encrypt;

// Encrypt backup before saving
final key = encrypt.Key.fromLength(32);
final iv = encrypt.IV.fromLength(16);
final encrypter = encrypt.Encrypter(encrypt.AES(key));
final encrypted = encrypter.encrypt(jsonString, iv: iv);
```

---

## 📞 Support

If you encounter issues with backups:

1. Check error message in logs
2. Verify storage permissions
3. Ensure sufficient device storage
4. Try creating new backup
5. Check backup file exists in Documents/sms_backups/

---

## 🎯 Best Practices

✅ **Do:**
- Create backups regularly (weekly)
- Test restore functionality periodically
- Keep multiple backup versions
- Export backups to cloud occasionally
- Monitor backup statistics

❌ **Don't:**
- Manually edit backup JSON files
- Delete backups while app is running
- Restore corrupted backup files
- Store backups on unreliable devices

---

**Version:** 1.0.0  
**Last Updated:** March 30, 2026
