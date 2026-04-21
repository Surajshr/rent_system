part of 'splash_cubit.dart';

enum SplashTarget { none, landing, ownerHome, renterHome }

class SplashState extends Equatable {
  const SplashState({
    this.loading = true,
    this.target = SplashTarget.none,
  });

  final bool loading;
  final SplashTarget target;

  SplashState copyWith({
    bool? loading,
    SplashTarget? target,
  }) {
    return SplashState(
      loading: loading ?? this.loading,
      target: target ?? this.target,
    );
  }

  @override
  List<Object?> get props => [loading, target];
}
