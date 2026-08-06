import 'package:equatable/equatable.dart';
import '../../../models/models.dart';

abstract class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final ClientModel client;
  final List<TransactionModel> transactions;
  const WalletLoaded({required this.client, required this.transactions});
  @override
  List<Object?> get props => [client, transactions];
}

class TopUpSuccess extends WalletState {
  final double newBalance;
  const TopUpSuccess({required this.newBalance});
  @override
  List<Object?> get props => [newBalance];
}

class WalletError extends WalletState {
  final String message;
  const WalletError({required this.message});
  @override
  List<Object?> get props => [message];
}
