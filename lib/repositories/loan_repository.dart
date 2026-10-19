import 'dart:async';
import '../models/loan_model.dart';
import '../services/data_service.dart';

abstract class ILoanRepository {
  Stream<List<Loan>> getLoans();
  Stream<List<Loan>> getLoansByCollector(String collectorId);
  Stream<List<Loan>> getLoansByClient(String clientId);
  Future<Loan?> getLoanById(String loanId);
  Future<String> createLoan(Loan loan, List<Map<String, dynamic>> cuotas);
  Future<void> updateLoanStatus(String loanId, String status);
  Future<void> updateLoanBalance(String loanId, double remainingBalance, int paidInstallments);
  Future<void> deleteLoan(String loanId);
}

class LoanRepository implements ILoanRepository {
  static final StreamController<List<Loan>> _loansStreamController =
      StreamController<List<Loan>>.broadcast();

  LoanRepository() {
    notify();
  }

  static void notify() {
    if (!_loansStreamController.isClosed) {
      _loansStreamController.add(DataService.allLoans());
    }
  }

  @override
  Stream<List<Loan>> getLoans() async* {
    yield DataService.allLoans();
    yield* _loansStreamController.stream;
  }

  @override
  Stream<List<Loan>> getLoansByCollector(String collectorId) async* {
    yield DataService.allLoans()
        .where((l) => l.collectorId == collectorId)
        .toList();
    yield* _loansStreamController.stream.map(
      (list) => list.where((l) => l.collectorId == collectorId).toList(),
    );
  }

  @override
  Stream<List<Loan>> getLoansByClient(String clientId) async* {
    yield DataService.loansOfClient(clientId);
    yield* _loansStreamController.stream.map(
      (list) => list.where((l) => l.clientId == clientId).toList(),
    );
  }

  @override
  Future<Loan?> getLoanById(String loanId) async {
    return DataService.getLoan(loanId);
  }

  @override
  Future<String> createLoan(Loan loan, List<Map<String, dynamic>> cuotas) async {
    final id = await DataService.createLoan(loan);
    notify();
    return id;
  }

  @override
  Future<void> updateLoanStatus(String loanId, String status) async {
    final loan = DataService.getLoan(loanId);
    if (loan != null) {
      final updated = loan.copyWith(status: LoanStatus.values.firstWhere((e) => e.name == status, orElse: () => loan.status));
      await DataService.loans.put(loanId, updated.toMap());
      notify();
    }
  }

  @override
  Future<void> updateLoanBalance(String loanId, double remainingBalance, int paidInstallments) async {
    await DataService.syncLoanFinancials(loanId);
    notify();
  }

  @override
  Future<void> deleteLoan(String loanId) async {
    await DataService.loans.delete(loanId);
    notify();
  }
}
