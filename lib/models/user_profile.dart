/// Lightweight profile extending auth.users. Maps to the [profiles] table.
class UserProfile {
  final String id;
  final String email;
  final String role;   // 'admin' | 'user'
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? fullName;
  final String? createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.fullName,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      status: json['status'] as String? ?? 'pending',
      fullName: json['full_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'status': status,
      'full_name': fullName,
      'created_at': createdAt,
    };
  }
}
