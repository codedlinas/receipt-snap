import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';
import '../../../../shared/models/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getUserProfile();
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.signInWithEmail(email: email, password: password);
      if (response.session != null) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error('No session returned', StackTrace.current);
        return false;
      }
    } catch (e, st) {
      debugPrint('Sign in error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.signUpWithEmail(email: email, password: password);
      // Supabase returns user even if email confirmation is required
      if (response.user != null) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error('Signup failed', StackTrace.current);
        return false;
      }
    } catch (e, st) {
      debugPrint('Sign up error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.signInWithGoogle();
      state = const AsyncValue.data(null);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repository.resetPassword(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
