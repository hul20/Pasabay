/// User roles in the Pasabay system
enum UserRole {
  TRAVELER,
  REQUESTER,
  VERIFIER,
  ADMIN;

  String get displayName {
    switch (this) {
      case UserRole.TRAVELER:
        return 'Traveler';
      case UserRole.REQUESTER:
        return 'Requester';
      case UserRole.VERIFIER:
        return 'Verifier';
      case UserRole.ADMIN:
        return 'Admin';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toUpperCase()) {
      case 'TRAVELER':
        return UserRole.TRAVELER;
      case 'REQUESTER':
        return UserRole.REQUESTER;
      case 'VERIFIER':
        return UserRole.VERIFIER;
      case 'ADMIN':
        return UserRole.ADMIN;
      default:
        return UserRole.TRAVELER;
    }
  }
}
