import 'package:equatable/equatable.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class AcceptBiddingSuccess extends PaymentState {}

class PaymentError extends PaymentState {
  final String message;
  const PaymentError({required this.message});
  @override
  List<Object?> get props => [message];
}

class InsufficientBalance extends PaymentState {
  final double required;
  final double current;
  const InsufficientBalance({required this.required, required this.current});
  @override
  List<Object?> get props => [required, current];
}
