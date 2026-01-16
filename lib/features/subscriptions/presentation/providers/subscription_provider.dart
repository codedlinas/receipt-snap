import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/subscription_repository.dart';
import '../../../../shared/models/subscription.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository();
});

final subscriptionsProvider = FutureProvider<List<Subscription>>((ref) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getSubscriptions();
});

final subscriptionsStreamProvider = StreamProvider<List<Subscription>>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.subscriptionsStream();
});

final upcomingRenewalsProvider = FutureProvider<List<Subscription>>((ref) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getUpcomingRenewals();
});

final subscriptionByIdProvider =
    FutureProvider.family<Subscription?, String>((ref, id) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getSubscriptionById(id);
});

final monthlySpendingProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getMonthlySpending();
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<List<Subscription>>> {
  final SubscriptionRepository _repository;
  final Ref _ref;

  SubscriptionNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadSubscriptions();
  }

  Future<void> loadSubscriptions() async {
    state = const AsyncValue.loading();
    try {
      final subscriptions = await _repository.getSubscriptions();
      state = AsyncValue.data(subscriptions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadSubscriptions();
    _ref.invalidate(monthlySpendingProvider);
  }

  Future<bool> updateSubscription(Subscription subscription) async {
    try {
      final updated = await _repository.updateSubscription(subscription);
      if (updated != null) {
        await refresh();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSubscription(String id) async {
    try {
      final success = await _repository.deleteSubscription(id);
      if (success) {
        await refresh();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelSubscription(String id) async {
    try {
      final updated = await _repository.cancelSubscription(id);
      if (updated != null) {
        await refresh();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifySubscription(String id) async {
    try {
      final updated = await _repository.verifySubscription(id);
      if (updated != null) {
        await refresh();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final subscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<List<Subscription>>>(
        (ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return SubscriptionNotifier(repository, ref);
});
