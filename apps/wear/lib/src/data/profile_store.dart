import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:wear_studio_core/wear_studio_core.dart';

/// The last profile the watch accepted, with the revision it arrived at.
class StoredProfile {
  const StoredProfile(this.profile, this.revision);

  final WatchProfile profile;
  final int revision;
}

/// Local persistence of the active profile, so the watch keeps working
/// after restarts and without the phone (PRD FR-001, NFR-003).
abstract interface class ProfileStore {
  /// Returns null when nothing valid is stored.
  Future<StoredProfile?> load();

  Future<void> save(StoredProfile stored);
}

/// Stores one JSON file in the app support directory.
///
/// Phase 1 keeps a single profile, so a plain file is enough; the storage
/// engine for multiple profiles and assets is chosen in Phase 2/3.
class FileProfileStore implements ProfileStore {
  FileProfileStore({Future<Directory> Function()? directory})
      : _directory = directory ?? getApplicationSupportDirectory;

  static const _fileName = 'active_profile.json';

  final Future<Directory> Function() _directory;

  Future<File> get _file async =>
      File('${(await _directory()).path}/$_fileName');

  @override
  Future<StoredProfile?> load() async {
    final file = await _file;
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, Object?>) return null;
      final revision = json['revision'];
      final profile = json['profile'];
      if (revision is! int || profile is! Map<String, Object?>) return null;
      return StoredProfile(WatchProfile.fromJson(profile), revision);
    } on Exception {
      // Corrupt or from an incompatible version: start clean rather than
      // crash (NFR-003). The phone will resend the active profile.
      return null;
    }
  }

  @override
  Future<void> save(StoredProfile stored) async {
    final file = await _file;
    await file.parent.create(recursive: true);
    // Write-then-rename so a crash mid-write never leaves a half file.
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      jsonEncode({
        'revision': stored.revision,
        'profile': stored.profile.toJson(),
      }),
      flush: true,
    );
    await temp.rename(file.path);
  }
}

/// In-memory store for tests and previews.
class MemoryProfileStore implements ProfileStore {
  MemoryProfileStore([this.stored]);

  StoredProfile? stored;

  @override
  Future<StoredProfile?> load() async => stored;

  @override
  Future<void> save(StoredProfile stored) async => this.stored = stored;
}
