import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_repository.dart';
import '../domain/address.dart';

/// The signed-in user's address book. The default address is tracked by
/// `defaultAddressId` on the user document.
class AddressRepository {
  AddressRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final AuthRepository _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc => _firestore.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> _addresses(String uid) =>
      _firestore.collection('users').doc(uid).collection('addresses');

  Stream<List<SavedAddress>> watchAddresses(String uid) {
    return _addresses(uid).orderBy('createdAt').snapshots().map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              SavedAddress(
                id: doc.id,
                label: doc.data()['label'] as String? ?? '',
                address: addressFromMap(doc.data()),
              ),
          ],
        );
  }

  /// Saves a new address and returns its id.
  Future<String> add({required String label, required ShippingAddress address, bool makeDefault = false}) async {
    final ref = _addresses(_uid).doc();
    final batch = _firestore.batch()
      ..set(ref, {
        'label': label,
        ...addressToMap(address),
        'createdAt': FieldValue.serverTimestamp(),
      });
    if (makeDefault) batch.update(_userDoc, {'defaultAddressId': ref.id});
    await batch.commit();
    return ref.id;
  }

  Future<void> update(
    String id, {
    required String label,
    required ShippingAddress address,
    bool makeDefault = false,
  }) async {
    final batch = _firestore.batch()..update(_addresses(_uid).doc(id), {'label': label, ...addressToMap(address)});
    if (makeDefault) batch.update(_userDoc, {'defaultAddressId': id});
    await batch.commit();
  }

  Future<void> setDefault(String id) => _userDoc.update({'defaultAddressId': id});

  Future<void> delete(String id, {required bool isDefault}) async {
    final batch = _firestore.batch()..delete(_addresses(_uid).doc(id));
    if (isDefault) batch.update(_userDoc, {'defaultAddressId': FieldValue.delete()});
    await batch.commit();
  }

  static ShippingAddress addressFromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      street: map['street'] as String? ?? '',
      city: map['city'] as String? ?? '',
      postalCode: map['postalCode'] as String? ?? '',
      country: map['country'] as String? ?? '',
    );
  }

  static Map<String, dynamic> addressToMap(ShippingAddress address) {
    return {
      'fullName': address.fullName,
      'phone': address.phone,
      'street': address.street,
      'city': address.city,
      'postalCode': address.postalCode,
      'country': address.country,
    };
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(firestoreProvider), ref.watch(authRepositoryProvider));
});

final addressesProvider = StreamProvider<List<SavedAddress>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(addressRepositoryProvider).watchAddresses(uid);
});

/// The user's default address, falling back to the oldest one when no default is set.
final defaultAddressProvider = Provider<SavedAddress?>((ref) {
  final addresses = ref.watch(addressesProvider).value ?? const [];
  if (addresses.isEmpty) return null;
  final defaultId = ref.watch(currentUserProvider).value?.defaultAddressId;
  return addresses.where((a) => a.id == defaultId).firstOrNull ?? addresses.first;
});
