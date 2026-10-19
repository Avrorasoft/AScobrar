import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';
import 'auth_provider.dart';

final paymentRepositoryProvider = Provider<IPaymentRepository>((ref) {
  return PaymentRepository();
});

final todayPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return paymentRepo.getPaymentsByCollectorToday(user.id);
});

final todayTotalCollectedProvider = Provider<double>((ref) {
  final paymentsAsync = ref.watch(todayPaymentsProvider);
  return paymentsAsync.maybeWhen(
    data: (payments) => payments.fold(0.0, (sum, p) => sum + p.amount),
    orElse: () => 0.0,
  );
});

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, AsyncValue<void>>((ref) {
  return PaymentController(ref.watch(paymentRepositoryProvider));
});

class PaymentController extends StateNotifier<AsyncValue<void>> {
  final IPaymentRepository _paymentRepository;

  PaymentController(this._paymentRepository) : super(const AsyncValue.data(null));

  Future<String?> recordPayment({
    required Payment payment,
    required double newLoanBalance,
    required int updatedPaidInstallments,
    required List<int> affectedInstallmentNumbers,
  }) async {
    state = const AsyncValue.loading();
    try {
      final paymentId = await _paymentRepository.registerPayment(
        payment: payment,
        newLoanBalance: newLoanBalance,
        updatedPaidInstallments: updatedPaidInstallments,
        affectedInstallmentNumbers: affectedInstallmentNumbers,
      );
      state = const AsyncValue.data(null);
      return paymentId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }
}
