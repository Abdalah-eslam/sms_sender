# Backup System - Quick Reference

## 📱 User Interface Features

### Backup Screen
**Location:** Home Screen → Backup Icon (⬆️)

**Features:**
1. **Backup Statistics Card**
   - Total Backups Count
   - Total Size (formatted)
   - Total Groups
   - Total Contacts

2. **Create Backup Button**
   - One-click backup creation
   - Shows success/error messages
   - Auto-loads backup list after creation

3. **Backups List**
   - Newest backups first
   - Shows filename, date, size, groups, contacts
   - Menu with Restore/Delete options

---

## 💾 Storage Info

**Saved Locally At:**
```
Documents/sms_backups/
├── backup_20260330_102530.json
├── backup_20260329_153245.json
└── backup_metadata.json
```

**Auto-Cleanup:**
- Keeps last 10 backups (configurable)
- Deletes oldest automatically when limit exceeded

**File Naming:**
- Format: `backup_YYYYMMDD_HHMMSS.json`
- Example: `backup_20260330_102530.json`

---

## 🚀 Quick Start

### Create Backup
1. Tap backup icon (⬆️) in Home Screen
2. Click "Create Backup Now"
3. Wait for confirmation
4. Backup saved automatically

### Restore Backup
1. Tap backup icon (⬆️) in Home Screen
2. Find backup in list
3. Tap menu (⋮) → Restore
4. Confirm in dialog
5. Groups and contacts imported

### Delete Backup
1. Tap backup icon (⬆️) in Home Screen
2. Find backup in list
3. Tap menu (⋮) → Delete
4. Confirm deletion

---

## 🔧 Advanced Features

### Merge vs Replace Mode
**Merge Mode (Default):**
- Keeps existing groups
- Adds new contacts only
- Skips duplicate phones
- Best for incremental backups

**Replace Mode:**
- Skips existing groups
- Only imports new groups
- Good for clean slate

### Data Validation
- **Auto-Validates on Create** - Ensures data integrity
- **Auto-Validates on Restore** - Prevents corrupted restores
- **Checksum Verification** - MD5 hashes backup content
- **Structure Validation** - Checks all required fields

### Error Recovery
- Clear error messages shown
- Detailed error descriptions
- Graceful failure handling
- No data corruption on errors

---

## 📊 Backup Statistics

```dart
// Get backup statistics
final stats = await BackupService.getBackupStats();

// Shows:
// - totalBackups: 7
// - totalSize: 45KB
// - totalGroups: 12
// - totalContacts: 89
// - oldestBackup: Date
// - newestBackup: Date
```

---

## 🔍 Supported Scenarios

### ✅ Scenario 1: Regular Backups
```
Week 1: Create backup 1
Week 2: Create backup 2
Week 3: Create backup 3
Result: All 3 backups kept, accessible for restore
```

### ✅ Scenario 2: Merge Data
```
Backup A: Groups=[Family, Work], Contacts=50
Restore A in device with Contacts=30
Result: Merge mode adds new contacts to existing groups
```

### ✅ Scenario 3: Emergency Restore
```
Device corrupted
Restore from backup created yesterday
Result: All data recovered successfully
```

### ✅ Scenario 4: Auto-Cleanup
```
Create 15 backups
System keeps last 10 automatically
Result: Oldest 5 deleted, storage saved
```

---

## 🚨 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "No groups to backup" | Create at least one group first |
| "Backup validation failed" | Check device storage, try again |
| "Backup file not found" | File moved/deleted, check Documents folder |
| "Invalid JSON format" | Backup corrupted, use another backup |
| Low storage space | Delete old backups, free up space |

---

## 📈 Performance Impact

**Backup Size Examples:**
- 5 groups, 50 contacts: ~3-5 KB
- 10 groups, 100 contacts: ~8-12 KB
- 20 groups, 250 contacts: ~20-30 KB
- 50 groups, 1000 contacts: ~100-150 KB

**Backup Time:**
- Small backup (<10 KB): ~100-300ms
- Medium backup (10-50 KB): ~300-800ms
- Large backup (50+ KB): ~800-2000ms

**Restore Time:**
- Small restore (<10 KB): ~150-400ms
- Medium restore (10-50 KB): ~400-1000ms
- Large restore (50+ KB): ~1000-2500ms

---

## 🔐 Data Safety

**Integrity Checks:**
✅ MD5 checksum validation
✅ JSON structure validation
✅ Required field validation
✅ Data type validation

**Backup Safety:**
✅ Non-destructive restore (merge mode default)
✅ Automatic backup validation
✅ Clear error messages
✅ No data loss on failed restore

**Local Storage:**
✅ Saved to device Documents folder
✅ Not uploaded anywhere
✅ Complete control over backups
✅ Can be moved/shared manually

---

## 🎯 Best Practices

**✅ DO:**
- Create backups weekly
- Test restore periodically
- Keep multiple backup versions
- Monitor backup statistics
- Delete old backups to save space

**❌ DON'T:**
- Edit backup JSON files manually
- Delete backups while app running
- Share backup files insecurely
- Restore drastically old backups without checking
- Ignore validation errors

---

## 🔗 Related Files

- **Service:** `lib/core/service/backupService.dart`
- **UI:** `lib/feature/backupScreen/backup_screen.dart`
- **Config:** `lib/core/config/backup_config.dart`
- **Guide:** `BACKUP_SYSTEM_GUIDE.md` (detailed documentation)

---

## 📞 Support

For detailed information, see `BACKUP_SYSTEM_GUIDE.md`

For implementation examples, check comments in `backupService.dart`

For UI reference, check `backup_screen.dart`

---

**Version:** 1.0.0 (Improved)  
**Status:** Production Ready ✅
