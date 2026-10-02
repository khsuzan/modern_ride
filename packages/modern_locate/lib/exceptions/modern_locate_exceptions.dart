sealed class ModernLocateException implements Exception {
  final String message;
  const ModernLocateException(this.message);
}

class ModernLocatePermissionException extends ModernLocateException {
  const ModernLocatePermissionException([super.message = 'Location permission denied']);
}

class ModernLocateGpsDisabledException extends ModernLocateException {
  const ModernLocateGpsDisabledException([super.message = 'Location services are disabled']);
}

class ModernLocateTimeoutException extends ModernLocateException {
  const ModernLocateTimeoutException([super.message = 'Location request timed out']);
}

class ModernLocateGenericException extends ModernLocateException {
  const ModernLocateGenericException(super.message);
}