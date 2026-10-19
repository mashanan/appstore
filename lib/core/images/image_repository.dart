import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../firebase/firebase_providers.dart';

class ImageTooLargeException implements Exception {
  const ImageTooLargeException();

  @override
  String toString() => 'This photo is too large. Please choose a smaller one.';
}

/// Stores photos as Base64 in `images/{id}`, so the app stays on Firebase's free
/// plan (Cloud Storage needs a paid plan). Images are referenced elsewhere as
/// `image:<id>`, alongside regular `https://` URLs.
class ImageRepository {
  ImageRepository(this._firestore, this._auth);

  static const _scheme = 'image:';

  /// Stays under Firestore's 1 MiB document limit, matching firestore.rules.
  static const _maxBase64Length = 900000;

  final FirebaseFirestore _firestore;
  final AuthRepository _auth;

  static bool isStoredImage(String reference) => reference.startsWith(_scheme);

  static String idOf(String reference) => reference.substring(_scheme.length);

  /// Saves [bytes] (already resized and compressed) and returns its `image:<id>` reference.
  Future<String> upload(Uint8List bytes, {String contentType = 'image/jpeg'}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user');

    final data = base64Encode(bytes);
    if (data.length >= _maxBase64Length) throw const ImageTooLargeException();

    final ref = _firestore.collection('images').doc();
    await ref.set({
      'ownerId': uid,
      'contentType': contentType,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return '$_scheme${ref.id}';
  }

  Future<Uint8List?> load(String id) async {
    final snapshot = await _firestore.collection('images').doc(id).get();
    final data = snapshot.data()?['data'] as String?;
    return data == null ? null : base64Decode(data);
  }
}

final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  return ImageRepository(ref.watch(firestoreProvider), ref.watch(authRepositoryProvider));
});

/// Image bytes by id, kept in memory so each photo is downloaded once per session.
final storedImageProvider = FutureProvider.family<Uint8List?, String>((ref, id) {
  return ref.watch(imageRepositoryProvider).load(id);
});
