import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/app_user.dart';
import 'auth_repository.dart';

class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<AppUser?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return AppUser(
        uid: snapshot.id,
        email: data['email'] as String? ?? '',
        displayName: data['displayName'] as String? ?? '',
        phone: data['phone'] as String?,
        role: UserRole.values.asNameMap()[data['role']] ?? UserRole.customer,
        photoImageId: data['photoImageId'] as String?,
        defaultAddressId: data['defaultAddressId'] as String?,
      );
    });
  }

  Future<void> updateProfile(String uid, {required String displayName, String? phone}) {
    return _firestore.collection('users').doc(uid).update({
      'displayName': displayName,
      'phone': (phone == null || phone.isEmpty) ? FieldValue.delete() : phone,
    });
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreProvider));
});

/// Profile of the signed-in user, or null when signed out.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(user.uid);
});
