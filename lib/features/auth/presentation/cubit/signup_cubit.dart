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

class SignupState extends Equatable {
  const SignupState({
    required this.role,
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.agreedToTerms = false,
    this.fullNameError,
    this.phoneError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.termsError,
    this.obscure = true,
    this.obscureConfirm = true,
    this.submitting = false,
    this.success = false,
    this.formError,
  });

  final UserRole role;
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final String confirmPassword;
  final bool agreedToTerms;
  final String? fullNameError;
  final String? phoneError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? termsError;
  final bool obscure;
  final bool obscureConfirm;
  final bool submitting;
  final bool success;
  final String? formError;

  SignupState copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
    bool? agreedToTerms,
    Object? fullNameError = _unset,
    Object? phoneError = _unset,
    Object? emailError = _unset,
    Object? passwordError = _unset,
    Object? confirmPasswordError = _unset,
    Object? termsError = _unset,
    bool? obscure,
    bool? obscureConfirm,
    bool? submitting,
    bool? success,
    Object? formError = _unset,
  }) {
    return SignupState(
      role: role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      fullNameError: identical(fullNameError, _unset)
          ? this.fullNameError
          : fullNameError as String?,
      phoneError:
          identical(phoneError, _unset) ? this.phoneError : phoneError as String?,
      emailError:
          identical(emailError, _unset) ? this.emailError : emailError as String?,
      passwordError: identical(passwordError, _unset)
          ? this.passwordError
          : passwordError as String?,
      confirmPasswordError: identical(confirmPasswordError, _unset)
          ? this.confirmPasswordError
          : confirmPasswordError as String?,
      termsError:
          identical(termsError, _unset) ? this.termsError : termsError as String?,
      obscure: obscure ?? this.obscure,
      obscureConfirm: obscureConfirm ?? this.obscureConfirm,
      submitting: submitting ?? this.submitting,
      success: success ?? this.success,
      formError:
          identical(formError, _unset) ? this.formError : formError as String?,
    );
  }

  @override
  List<Object?> get props => [
        role,
        fullName,
        phone,
        email,
        password,
        confirmPassword,
        agreedToTerms,
        fullNameError,
        phoneError,
        emailError,
        passwordError,
        confirmPasswordError,
        termsError,
        obscure,
        obscureConfirm,
        submitting,
        success,
        formError,
      ];
}

class SignupCubit extends Cubit<SignupState> {
  SignupCubit(this._auth, this.role) : super(SignupState(role: role));

  final AuthRepository _auth;
  final UserRole role;

  void fullNameChanged(String v) =>
      emit(state.copyWith(fullName: v, fullNameError: null));

  void phoneChanged(String v) => emit(state.copyWith(phone: v, phoneError: null));

  void emailChanged(String v) => emit(state.copyWith(email: v, emailError: null));

  void passwordChanged(String v) =>
      emit(state.copyWith(password: v, passwordError: null));

  void confirmChanged(String v) =>
      emit(state.copyWith(confirmPassword: v, confirmPasswordError: null));

  void termsChanged({required bool agreed}) =>
      emit(state.copyWith(agreedToTerms: agreed, termsError: null));

  void toggleObscure() => emit(state.copyWith(obscure: !state.obscure));

  void toggleObscureConfirm() =>
      emit(state.copyWith(obscureConfirm: !state.obscureConfirm));

  Future<void> submit() async {
    final fullNameErr = AuthValidators.required(state.fullName);

    // Email is required and must be a valid email address.
    final emailErr = state.email.trim().isEmpty
        ? 'This field is required'
        : (AuthValidators.looksLikeEmail(state.email)
            ? null
            : 'Please enter a valid email');

    // Phone is optional — validate format only if something is typed.
    final phoneErr = state.phone.trim().isEmpty
        ? null
        : (AuthValidators.looksLikePhone(state.phone)
            ? null
            : 'Please enter a valid phone number');

    final passErr = state.password.length < 8
        ? 'Password must be 8+ characters'
        : null;
    final confirmErr = state.password != state.confirmPassword
        ? 'Passwords do not match'
        : null;
    final termsErr = state.agreedToTerms ? null : 'Please accept Terms & Conditions';

    if (fullNameErr != null ||
        phoneErr != null ||
        emailErr != null ||
        passErr != null ||
        confirmErr != null ||
        termsErr != null) {
      emit(
        state.copyWith(
          fullNameError: fullNameErr,
          phoneError: phoneErr,
          emailError: emailErr,
          passwordError: passErr,
          confirmPasswordError: confirmErr,
          termsError: termsErr,
        ),
      );
      return;
    }

    emit(state.copyWith(submitting: true, formError: null));
    try {
      await _auth.signUp(
        fullName: state.fullName,
        phone: state.phone,
        email: state.email,
        password: state.password,
        confirmPassword: state.confirmPassword,
        agreedToTerms: state.agreedToTerms,
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

  PasswordStrength strength() => AuthValidators.passwordStrength(state.password);
}
