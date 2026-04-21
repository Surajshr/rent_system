import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_system/core/errors/app_exception.dart';
import 'package:rent_system/core/utils/auth_validators.dart';
import 'package:rent_system/features/auth/domain/auth_repository.dart';
import 'package:rent_system/features/auth/domain/user_role.dart';

class _Unset {
  const _Unset();
}

const Object _unset = _Unset();

class LoginState extends Equatable {
  const LoginState({
    required this.role,
    this.identifier = '',
    this.password = '',
    this.identifierError,
    this.passwordError,
    this.formError,
    this.obscurePassword = true,
    this.submitting = false,
    this.success = false,
  });

  final UserRole role;
  final String identifier;
  final String password;
  final String? identifierError;
  final String? passwordError;
  final String? formError;
  final bool obscurePassword;
  final bool submitting;
  final bool success;

  LoginState copyWith({
    String? identifier,
    String? password,
    Object? identifierError = _unset,
    Object? passwordError = _unset,
    Object? formError = _unset,
    bool? obscurePassword,
    bool? submitting,
    bool? success,
  }) {
    return LoginState(
      role: role,
      identifier: identifier ?? this.identifier,
      password: password ?? this.password,
      identifierError: identical(identifierError, _unset)
          ? this.identifierError
          : identifierError as String?,
      passwordError: identical(passwordError, _unset)
          ? this.passwordError
          : passwordError as String?,
      formError:
          identical(formError, _unset) ? this.formError : formError as String?,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      submitting: submitting ?? this.submitting,
      success: success ?? this.success,
    );
  }

  @override
  List<Object?> get props => [
        role,
        identifier,
        password,
        identifierError,
        passwordError,
        formError,
        obscurePassword,
        submitting,
        success,
      ];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._auth, this.role) : super(LoginState(role: role));

  final AuthRepository _auth;
  final UserRole role;

  void identifierChanged(String value) {
    emit(
      state.copyWith(
        identifier: value,
        identifierError: null,
        passwordError: null,
        formError: null,
      ),
    );
  }

  void passwordChanged(String value) {
    emit(
      state.copyWith(
        password: value,
        identifierError: null,
        passwordError: null,
        formError: null,
      ),
    );
  }

  void toggleObscure() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  Future<void> submit() async {
    final idErr = AuthValidators.identifierError(state.identifier);
    final passErr = AuthValidators.required(
      state.password,
      message: 'This field is required',
    );
    if (idErr != null || passErr != null) {
      emit(state.copyWith(identifierError: idErr, passwordError: passErr));
      return;
    }
    emit(state.copyWith(submitting: true, formError: null));
    try {
      await _auth.signIn(
        identifier: state.identifier.trim(),
        password: state.password,
        role: role,
      );
      emit(state.copyWith(submitting: false, success: true));
    } on AppException catch (e) {
      emit(state.copyWith(submitting: false, formError: e.message));
    } on Exception {
      emit(
        state.copyWith(
          submitting: false,
          formError: 'Something went wrong. Please try again.',
        ),
      );
    }
  }
}
