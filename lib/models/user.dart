class AppUser {
  final int id;
  final String fullName;
  final String employeeId;
  final String email;
  final String role; // 'admin' or 'kasir'
  final bool isActive;
  final String initials;

  AppUser({
    required this.id,
    required this.fullName,
    required this.employeeId,
    required this.email,
    required this.role,
    this.isActive = true,
    String? initials,
  }) : initials = initials ?? _makeInitials(fullName);

  static String _makeInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as int,
    fullName: j['name'] as String,
    employeeId: j['employee_id'] as String? ?? '',
    email: j['email'] as String? ?? '',
    role: j['role'] as String? ?? 'kasir',
    isActive: j['is_active'] as bool? ?? true,
    initials: j['initials'] as String?,
  );
}
