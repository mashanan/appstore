/// Who receives a delivery and where. Orders keep their own copy, so editing
/// a saved address never changes past orders.
class ShippingAddress {
  const ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String postalCode;
  final String country;

  String get singleLine => '$street, $city $postalCode, $country';
}

/// An entry in the user's address book, stored in `users/{uid}/addresses/{id}`.
class SavedAddress {
  const SavedAddress({required this.id, required this.label, required this.address});

  final String id;

  /// e.g. "Home" or "Work".
  final String label;
  final ShippingAddress address;
}
