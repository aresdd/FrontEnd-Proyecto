/// Frontend-only checks for registration (no backend validation).
bool isValidRegistrationEmail(String raw) {
  final email = raw.trim().toLowerCase();
  if (email.isEmpty) return false;

  // usuario@gmail.com, nombre@outlook.es, etc.
  final pattern = RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$');
  return pattern.hasMatch(email);
}

String? registrationEmailError(String raw) {
  final email = raw.trim();
  if (email.isEmpty) return 'Introduce tu email';
  if (!email.contains('@')) {
    return 'El email debe incluir @ (ej. nombre@gmail.com)';
  }
  if (!isValidRegistrationEmail(email)) {
    return 'Email no válido. Usa un formato como nombre@gmail.com';
  }
  return null;
}
