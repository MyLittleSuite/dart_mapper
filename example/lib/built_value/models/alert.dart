import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert.freezed.dart';

@freezed
class Alert with _$Alert {
  const Alert._();

  const factory Alert({
    String? title,
    String? subtitle,
    DateTime? date,
    int? rank,
    bool? warning,
    int? actionType,
    String? payload,
  }) = _Alert;
}
