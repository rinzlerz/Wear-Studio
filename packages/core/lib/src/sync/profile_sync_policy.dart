import '../model/watch_profile.dart';
import '../schema.dart';
import '../validation/profile_validator.dart';
import 'sync_envelope.dart';

sealed class ProfileSyncDecision {
  const ProfileSyncDecision();
}

/// Apply and persist [profile] at [revision].
final class AcceptProfile extends ProfileSyncDecision {
  const AcceptProfile(this.profile, this.revision, this.validation);

  final WatchProfile profile;
  final int revision;
  final ValidationResult validation;
}

/// Already applied (redelivery) or older than what is applied.
final class IgnoreStaleProfile extends ProfileSyncDecision {
  const IgnoreStaleProfile(this.incomingRevision, this.currentRevision);

  final int incomingRevision;
  final int currentRevision;
}

/// Could not be parsed or failed validation; keep the current profile.
final class RejectProfile extends ProfileSyncDecision {
  const RejectProfile(this.reason);

  final String reason;
}

/// Decides whether an incoming profile envelope should replace the current
/// one. Pure, so it is unit-tested and shared by every receiver.
ProfileSyncDecision decideIncomingProfile({
  required SyncEnvelope envelope,
  required int? currentRevision,
  ProfileValidator validator = const ProfileValidator(),
}) {
  if (envelope.type != SyncPayloadType.profile) {
    return RejectProfile('expected a profile, got ${envelope.type.wireName}');
  }
  if (currentRevision != null && envelope.revision <= currentRevision) {
    return IgnoreStaleProfile(envelope.revision, currentRevision);
  }

  final WatchProfile profile;
  try {
    profile = envelope.profile;
  } on FormatException catch (e) {
    return RejectProfile('malformed profile: ${e.message}');
  } on UnsupportedSchemaVersionException catch (e) {
    return RejectProfile(e.toString());
  }

  final validation = validator.validate(profile);
  if (!validation.isValid) {
    return RejectProfile('invalid profile:\n${validation.errors.join('\n')}');
  }
  return AcceptProfile(profile, envelope.revision, validation);
}
