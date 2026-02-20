/// User model matching the backend's auth response format.
///
/// The backend returns flat JSON:
/// ```json
/// { "id": 1, "name": "John", "email": "john@test.com", "role": "patient",
///   "password": "...", "phone": null, "token": "..." }
/// ```
enum UserRole { patient, doctor, pharmacist, admin, nurse }

class User {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  /// Parse from backend auth response (flat JSON with extra fields).
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.patient,
      ),
      phone: json['phone'] as String?,
    );
  }

  /// Construct from decoded JWT payload: { id, email, role, iat, exp }.
  /// JWT does not contain `name`, so we fall back to the email prefix.
  factory User.fromJwt(Map<String, dynamic> payload, {String? storedName}) {
    final email = (payload['email'] as String?) ?? '';
    return User(
      id: (payload['id'] ?? payload['user_id'] ?? 0) as int,
      name: storedName ?? email.split('@').first, // best effort from JWT
      email: email,
      role: UserRole.values.firstWhere(
        (r) => r.name == payload['role'],
        orElse: () => UserRole.patient,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        if (phone != null) 'phone': phone,
      };
}
