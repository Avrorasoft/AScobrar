import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan_model.dart';
import '../models/user_model.dart';
import '../repositories/loan_repository.dart';
import 'auth_provider.dart';

final loanRepositoryProvider = Provider<ILoanRepository>((ref) {
  return LoanRepository();
});

final loansStreamProvider = StreamProvider<List<Loan>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final loanRepo = ref.watch(loanRepositoryProvider);

  if (user == null) return Stream.value([]);

  if (user.role == UserRole.owner) {
    return loanRepo.getLoans();
  } else {
    return loanRepo.getLoansByCollector(user.id);
  }
});

// Alias de retrocompatibilidad
final loansProvider = loansStreamProvider;

final loanByIdProvider = FutureProvider.family<Loan?, String>((ref, id) {
  final loanRepo = ref.watch(loanRepositoryProvider);
  return loanRepo.getLoanById(id);
});

final loanControllerProvider =
    StateNotifierProvider<LoanController, AsyncValue<void>>((ref) {
  return LoanController(ref.watch(loanRepositoryProvider));
});

class LoanController extends StateNotifier<AsyncValue<void>> {
  final ILoanRepository _loanRepository;

  LoanController(this._loanRepository) : super(const AsyncValue.data(null));

  Future<String?> createLoan({
    required Loan loan,
    required List<Map<String, dynamic>> cuotas,
  }) async {
    state = const AsyncValue.loading();
    try {
      final loanId = await _loanRepository.createLoan(loan, cuotas);
      state = const AsyncValue.data(null);
      return loanId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }
}
