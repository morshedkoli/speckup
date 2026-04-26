import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
sealed class Failure with _$Failure {
  const factory Failure.network([@Default('No internet connection') String message]) = _NetworkFailure;
  const factory Failure.server(String message) = _ServerFailure;
  const factory Failure.auth(String message) = _AuthFailure;
  const factory Failure.cache(String message) = _CacheFailure;
  const factory Failure.unknown([@Default('An unknown error occurred') String message]) = _UnknownFailure;
}
