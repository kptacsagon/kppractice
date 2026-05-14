class AgrisenseAlert {
  final String? id;
  final String farmerId;
  final String module;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final String? ctaLabel;
  final String? ctaAction;
  final DateTime triggeredAt;
  final DateTime? readAt;

  AgrisenseAlert({
    this.id,
    required this.farmerId,
    required this.module,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.ctaAction,
    required this.triggeredAt,
    this.readAt,
  });

  factory AgrisenseAlert.fromJson(Map<String, dynamic> json) {
    return AgrisenseAlert(
      id: json['id'],
      farmerId: json['farmer_id'],
      module: json['module'],
      alertType: json['alert_type'],
      severity: json['severity'],
      title: json['title'],
      message: json['message'],
      ctaLabel: json['cta_label'],
      ctaAction: json['cta_action'],
      triggeredAt: DateTime.parse(json['triggered_at']),
      readAt: json['read_at'] == null ? null : DateTime.parse(json['read_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'module': module,
      'alert_type': alertType,
      'severity': severity,
      'title': title,
      'message': message,
      'cta_label': ctaLabel,
      'cta_action': ctaAction,
      'triggered_at': triggeredAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }
}
