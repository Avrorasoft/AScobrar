import 'dart:async';
import '../models/payment_model.dart';
import '../services/data_service.dart';

abstract class IPaymentRepository {
  Stream<List<Payment>> getPaymentsByLoan(String loanId);
  Stream<List<Payment>> getPaymentsByCollectorToday(String collectorId);
  Stream<List<Payment>> getAllPaymentsToday();
  Future<String> registerPayment({
    required Payment payment,
    required double newLoanBalance,
    required int updatedPaidInstallments,
    required List<int> affectedInstallmentNumbers,
  });
}

class PaymentRepository implements IPaymentRepository {
  List<Payment> _getAllFromHive() {
    final raw = DataService.payments.values.toList();
    final List<Payment> list = [];
    for (var p in raw) {
      if (p is Map) {
        try {
          list.add(Payment.fromMap(Map<String, dynamic>.from(p)));
        } catch (_) {}
      }
    }
    return list;
  }

  @override
  Stream<List<Payment>> getPaymentsByLoan(String loanId) async* {
    yield _getAllFromHive().where((p) => p.loanId == loanId).toList();
    yield* DataService.payments.watch().map((_) {
      return _getAllFromHive().where((p) => p.loanId == loanId).toList();
    });
  }

  @override
  Stream<List<Payment>> getPaymentsByCollectorToday(String collectorId) async* {
    List<Payment> filter(List<Payment> all) {
      final now = DateTime.now();
      return all.where((p) {
        final sameCollector = collectorId.isEmpty || p.collectorId == collectorId;
        final sameDay = p.paidAt.year == now.year &&
            p.paidAt.month == now.month &&
            p.paidAt.day == now.day;
        return sameCollector && sameDay;
      }).toList();
    }

    yield filter(_getAllFromHive());
    yield* DataService.payments.watch().map((_) => filter(_getAllFromHive()));
  }

  @override
  Stream<List<Payment>> getAllPaymentsToday() async* {
    List<Payment> filter(List<Payment> all) {
      final now = DateTime.now();
      return all.where((p) {
        return p.paidAt.year == now.year &&
            p.paidAt.month == now.month &&
            p.paidAt.day == now.day;
      }).toList();
    }

    yield filter(_getAllFromHive());
    yield* DataService.payments.watch().map((_) => filter(_getAllFromHive()));
  }

  @override
  Future<String> registerPayment({
    required Payment payment,
    required double newLoanBalance,
    required int updatedPaidInstallments,
    required List<int> affectedInstallmentNumbers,
  }) async {
    await DataService.registerPayment(payment);
    return payment.id;
  }
}
