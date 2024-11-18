import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert.freezed.dart';

enum AlertType {
  missingPhoneNumber,
  missingEmail,
  goToAppointment,
  performQuickAcceptance,
}

@freezed
class Alert with _$Alert {
  const Alert._();

  const factory Alert({
    AlertType? type,
    String? title,
    String? subtitle,
    DateTime? date,
    int? rank,
    bool? warning,
    String? payload,
  }) = _Alert;
}
