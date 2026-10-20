import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';
import '../repositories/payment_repository.dart';
import 'auth_provider.dart';

final paymentRepositoryProvider = Provider<IPaymentRepository>((ref) {
  return PaymentRepository();
});

final todayPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  final user = ref.watch(currentUserProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);

  // Si es Administrador o Dueño, ve los cobros de TODOS los cobradores
  if (user == null || user.role == UserRole.owner || user.isOwner) {
    return paymentRepo.getAllPaymentsToday();
  }

  // Si es cobrador, ve únicamente su cartera
  return paymentRepo.getPaymentsByCollectorToday(user.id);
});

final todayTotalCollectedProvider = Provider<double>((ref) {
  final paymentsAsync = ref.watch(todayPaymentsProvider);
  return paymentsAsync.maybeWhen(
    data: (payments) => payments.fold(0.0, (sum, p) => sum + p.amount),
    orElse: () => 0.0,
  );
});

class PaymentController extends StateNotifier<AsyncValue<void>> {
  final IPaymentRepository _repository;
  PaymentController(this._repository) : super(const AsyncValue.data(null));

  Future<void> submitPayment({
    required Payment payment,
    required double newLoanBalance,
    required int updatedPaidInstallments,
    required List<int> affectedInstallmentNumbers,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.registerPayment(
        payment: payment,
        newLoanBalance: newLoanBalance,
        updatedPaidInstallments: updatedPaidInstallments,
        affectedInstallmentNumbers: affectedInstallmentNumbers,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, AsyncValue<void>>((ref) {
  return PaymentController(ref.watch(paymentRepositoryProvider));
});
