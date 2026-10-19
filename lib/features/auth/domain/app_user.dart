enum UserRole { customer, admin }

/// A signed-in user's profile, stored in `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phone,
    this.role = UserRole.customer,
    this.photoImageId,
    this.defaultAddressId,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? phone;
  final UserRole role;

  /// Id of the profile photo in the `images` collection, if any.
  final String? photoImageId;

  /// Id of the default entry in `users/{uid}/addresses`, if any.
  final String? defaultAddressId;

  bool get isAdmin => role == UserRole.admin;
}
