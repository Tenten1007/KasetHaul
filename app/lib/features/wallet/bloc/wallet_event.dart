import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class LoadWalletEvent extends WalletEvent {
  final String clientId;
  const LoadWalletEvent({required this.clientId});
  @override
  List<Object?> get props => [clientId];
}

class TopUpEvent extends WalletEvent {
  final String clientId;
  final double amount;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String referenceNo;
  final String? slipUrl;
  const TopUpEvent({
    required this.clientId,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.referenceNo,
    this.slipUrl,
  });
  @override
  List<Object?> get props => [clientId, amount, referenceNo];
}
