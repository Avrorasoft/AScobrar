import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan_model.dart';
import '../models/user_model.dart';
import '../repositories/loan_repository.dart';
import '../services/data_service.dart';
import 'auth_provider.dart';

final loanRepositoryProvider = Provider<ILoanRepository>((ref) {
  return LoanRepository();
});

final loansStreamProvider = StreamProvider<List<Loan>>((ref) {
  // Obtenemos el usuario de la sesión activa Riverpod o de DataService
  final currentUser = ref.watch(currentUserProvider) ?? DataService.getCurrentUserSession();

  return FirebaseFirestore.instance
      .collection('loans')
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Loan.fromMap(data);
    }).toList();

    // Sincronizar en segundo plano con Hive local
    for (final loan in list) {
      DataService.loans.put(loan.id, loan.toMap());
    }

    // Si es Administrador / Dueño, ve absolutamente todos los préstamos
    if (currentUser == null || currentUser.isOwner) {
      return list;
    }

    // Si es Cobrador, ve los préstamos que tiene asignados o generales sin asignar
    return list.where((loan) {
      return loan.collectorId == currentUser.id ||
          loan.collectorId.isEmpty ||
          loan.collectorId == 'sin_asignar' ||
          loan.collectorId == 'admin';
    }).toList();
  });
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
