import '../../core/errors/errors.dart';
import '../models/models.dart';

abstract class ExpensesRepository {
  ResultFuture<List<ExpenseDto>> fetchByGroup(String groupId);

  ResultFuture<ExpenseDto> fetchById(String expenseId);

  ResultFuture<ExpenseDto> create({
    required String groupId,
    required String payerId,
    required String createdBy,
    required double amount,
    required String currency,
    required DateTime expenseDate,
    required List<ParticipantShare> participants,
    String? description,
  });

  ResultFuture<ExpenseDto> update({
    required String expenseId,
    double? amount,
    String? currency,
    DateTime? expenseDate,
    String? description,
    List<ParticipantShare>? participants,
  });

  ResultFuture<void> delete(String expenseId);
}
