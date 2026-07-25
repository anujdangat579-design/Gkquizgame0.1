import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment_order.dart';
import '../repositories/payment_repository.dart';

class CreatePaymentOrderParams extends Equatable {
  final String competitionId;
  final String difficultyLevel;

  const CreatePaymentOrderParams({required this.competitionId, required this.difficultyLevel});

  @override
  List<Object?> get props => [competitionId, difficultyLevel];
}

class CreatePaymentOrder implements UseCase<PaymentOrder, CreatePaymentOrderParams> {
  final PaymentRepository repository;

  CreatePaymentOrder(this.repository);

  @override
  Future<Either<Failure, PaymentOrder>> call(CreatePaymentOrderParams params) {
    return repository.createOrder(
      competitionId: params.competitionId,
      difficultyLevel: params.difficultyLevel,
    );
  }
}
