import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/receipt_repository.dart';
import '../../../../shared/models/extraction_result.dart';
import '../../../../shared/models/subscription.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository();
});

enum CaptureState {
  idle,
  capturing,
  processing,
  success,
  error,
}

class CaptureStateData {
  final CaptureState state;
  final String? imageData;
  final String? error;
  final ProcessReceiptResponse? result;

  const CaptureStateData({
    this.state = CaptureState.idle,
    this.imageData,
    this.error,
    this.result,
  });

  CaptureStateData copyWith({
    CaptureState? state,
    String? imageData,
    String? error,
    ProcessReceiptResponse? result,
  }) {
    return CaptureStateData(
      state: state ?? this.state,
      imageData: imageData ?? this.imageData,
      error: error,
      result: result ?? this.result,
    );
  }
}

class CaptureNotifier extends StateNotifier<CaptureStateData> {
  final ReceiptRepository _repository;
  final Ref _ref;

  CaptureNotifier(this._repository, this._ref)
      : super(const CaptureStateData());

  void setImage(String imageData) {
    state = state.copyWith(
      state: CaptureState.capturing,
      imageData: imageData,
    );
  }

  Future<ProcessReceiptResponse> processImage({
    required String imageBase64,
    String? filename,
    String? mimeType,
  }) async {
    state = state.copyWith(
      state: CaptureState.processing,
      imageData: imageBase64,
    );

    final response = await _repository.processReceipt(
      imageBase64: imageBase64,
      filename: filename,
      mimeType: mimeType,
    );

    if (response.success) {
      state = state.copyWith(
        state: CaptureState.success,
        result: response,
      );
      // Refresh subscriptions list
      _ref.read(subscriptionNotifierProvider.notifier).refresh();
    } else {
      state = state.copyWith(
        state: CaptureState.error,
        error: response.error,
      );
    }

    return response;
  }

  Future<Subscription?> saveWithEdits(ExtractionResult extraction) async {
    final result = state.result;
    
    if (result?.subscription != null) {
      // Update existing subscription
      final updated = await _repository.updateSubscriptionFromExtraction(
        result!.subscription!.id,
        extraction,
      );
      if (updated != null) {
        _ref.read(subscriptionNotifierProvider.notifier).refresh();
      }
      return updated;
    } else {
      // Create new subscription
      final created = await _repository.createSubscriptionFromExtraction(extraction);
      if (created != null) {
        _ref.read(subscriptionNotifierProvider.notifier).refresh();
      }
      return created;
    }
  }

  void reset() {
    state = const CaptureStateData();
  }
}

final captureNotifierProvider =
    StateNotifierProvider<CaptureNotifier, CaptureStateData>((ref) {
  final repository = ref.watch(receiptRepositoryProvider);
  return CaptureNotifier(repository, ref);
});
