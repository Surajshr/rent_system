import 'package:equatable/equatable.dart';

class AppFailure extends Equatable {
  const AppFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
