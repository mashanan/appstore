/// Shared demo accounts so reviewers can try the app without signing up.
///
/// These credentials are public on purpose. The accounts are pre-verified, and
/// Firestore rules stop any admin (including the demo admin) from changing roles.
class DemoAccount {
  const DemoAccount({required this.label, required this.description, required this.email, required this.password});

  final String label;
  final String description;
  final String email;
  final String password;
}

const demoAccounts = [
  DemoAccount(
    label: 'Demo shopper',
    description: 'Browse, add to cart and place orders',
    email: 'demo.shopper@example.com',
    password: 'DemoShopper!2026',
  ),
  DemoAccount(
    label: 'Demo admin',
    description: 'Manage products and process orders',
    email: 'demo.admin@example.com',
    password: 'DemoAdmin!2026',
  ),
];
