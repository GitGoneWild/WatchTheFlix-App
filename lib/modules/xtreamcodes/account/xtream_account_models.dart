// XtreamAccountModels
// Typed models for Xtream Codes account information.
// Maps raw API responses to strongly typed domain models.

import 'package:equatable/equatable.dart';

/// Xtream user information model
class XtreamUserInfo extends Equatable {
  final String username;
  final String password;
  final String message;
  final int auth;
  final String status;
  final DateTime? expDate;
  final bool isTrial;
  final int activeConnections;
  final DateTime? createdAt;
  final int maxConnections;
  final List<String> allowedOutputFormats;

  const XtreamUserInfo({
    required this.username,
    required this.password,
    required this.message,
    required this.auth,
    required this.status,
    this.expDate,
    this.isTrial = false,
    this.activeConnections = 0,
    this.createdAt,
    this.maxConnections = 1,
    this.allowedOutputFormats = const [],
  });

  /// Check if user is authenticated
  bool get isAuthenticated => auth == 1;

  /// Check if account is active
  bool get isActive => status.toLowerCase() == 'active';

  /// Check if account is expired
  bool get isExpired {
    if (expDate == null) return false;
    return DateTime.now().isAfter(expDate!);
  }

  /// Get days until expiration (negative if expired)
  int? get daysUntilExpiry {
    if (expDate == null) return null;
    return expDate!.difference(DateTime.now()).inDays;
  }

  /// Get account status type for UI display
  AccountStatus get accountStatus {
    if (!isAuthenticated) return AccountStatus.disabled;
    if (isExpired) return AccountStatus.expired;
    if (isTrial) return AccountStatus.trial;
    if (isActive) return AccountStatus.active;
    return AccountStatus.disabled;
  }

  factory XtreamUserInfo.fromJson(Map<String, dynamic> json) {
    return XtreamUserInfo(
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      auth: _parseInt(json['auth']),
      status: json['status']?.toString() ?? '',
      expDate: _parseDateTime(json['exp_date']),
      isTrial: json['is_trial'] == '1' || json['is_trial'] == true,
      activeConnections: _parseInt(json['active_cons']),
      createdAt: _parseDateTime(json['created_at']),
      maxConnections: _parseInt(json['max_connections'], defaultValue: 1),
      allowedOutputFormats: _parseStringList(json['allowed_output_formats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'message': message,
      'auth': auth,
      'status': status,
      'exp_date': expDate?.millisecondsSinceEpoch,
      'is_trial': isTrial,
      'active_cons': activeConnections,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'max_connections': maxConnections,
      'allowed_output_formats': allowedOutputFormats,
    };
  }

  @override
  List<Object?> get props => [
        username,
        password,
        message,
        auth,
        status,
        expDate,
        isTrial,
        activeConnections,
        createdAt,
        maxConnections,
        allowedOutputFormats,
      ];
}

/// Xtream server information model
class XtreamServerInfo extends Equatable {
  final String url;
  final String port;
  final String httpsPort;
  final String serverProtocol;
  final String rtmpPort;
  final String timezone;
  final DateTime? timestampNow;
  final String timeNow;
  final bool process;

  const XtreamServerInfo({
    required this.url,
    required this.port,
    required this.httpsPort,
    required this.serverProtocol,
    required this.rtmpPort,
    required this.timezone,
    this.timestampNow,
    required this.timeNow,
    this.process = true,
  });

  /// Get full server URL with protocol
  String get fullUrl {
    final protocol = serverProtocol.isNotEmpty ? serverProtocol : 'http';
    final effectivePort = protocol == 'https' ? httpsPort : port;
    if (effectivePort.isEmpty || effectivePort == '80' || effectivePort == '443') {
      return '$protocol://$url';
    }
    return '$protocol://$url:$effectivePort';
  }

  /// Check if HTTPS is available
  bool get hasHttps => httpsPort.isNotEmpty && httpsPort != '0';

  /// Check if RTMP is available
  bool get hasRtmp => rtmpPort.isNotEmpty && rtmpPort != '0';

  factory XtreamServerInfo.fromJson(Map<String, dynamic> json) {
    return XtreamServerInfo(
      url: json['url']?.toString() ?? '',
      port: json['port']?.toString() ?? '80',
      httpsPort: json['https_port']?.toString() ?? '443',
      serverProtocol: json['server_protocol']?.toString() ?? 'http',
      rtmpPort: json['rtmp_port']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? 'UTC',
      timestampNow: _parseDateTime(json['timestamp_now']),
      timeNow: json['time_now']?.toString() ?? '',
      process: json['process'] == true || json['process'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'port': port,
      'https_port': httpsPort,
      'server_protocol': serverProtocol,
      'rtmp_port': rtmpPort,
      'timezone': timezone,
      'timestamp_now': timestampNow?.millisecondsSinceEpoch,
      'time_now': timeNow,
      'process': process,
    };
  }

  @override
  List<Object?> get props => [
        url,
        port,
        httpsPort,
        serverProtocol,
        rtmpPort,
        timezone,
        timestampNow,
        timeNow,
        process,
      ];
}

/// Xtream account overview combining user and server info
class XtreamAccountOverview extends Equatable {
  final XtreamUserInfo userInfo;
  final XtreamServerInfo serverInfo;

  const XtreamAccountOverview({
    required this.userInfo,
    required this.serverInfo,
  });

  /// Convenience getter for authentication status
  bool get isAuthenticated => userInfo.isAuthenticated;

  /// Convenience getter for account status
  AccountStatus get status => userInfo.accountStatus;

  factory XtreamAccountOverview.fromJson(Map<String, dynamic> json) {
    return XtreamAccountOverview(
      userInfo: XtreamUserInfo.fromJson(json['user_info'] ?? {}),
      serverInfo: XtreamServerInfo.fromJson(json['server_info'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_info': userInfo.toJson(),
      'server_info': serverInfo.toJson(),
    };
  }

  @override
  List<Object?> get props => [userInfo, serverInfo];
}

/// Account status enumeration for UI display
enum AccountStatus {
  active,
  trial,
  expired,
  disabled,
}

/// Extension to provide UI-friendly properties for AccountStatus
extension AccountStatusExtension on AccountStatus {
  String get displayName {
    switch (this) {
      case AccountStatus.active:
        return 'Active';
      case AccountStatus.trial:
        return 'Trial';
      case AccountStatus.expired:
        return 'Expired';
      case AccountStatus.disabled:
        return 'Disabled';
    }
  }

  bool get isGood => this == AccountStatus.active;
  bool get isWarning => this == AccountStatus.trial;
  bool get isBad => this == AccountStatus.expired || this == AccountStatus.disabled;
}

// Helper functions for parsing
int _parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) {
    // Unix timestamp (seconds)
    return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }
  if (value is String) {
    // Try Unix timestamp first
    final timestamp = int.tryParse(value);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }
    // Try ISO format
    return DateTime.tryParse(value);
  }
  return null;
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return [];
}
