import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final ClientRepository _clientRepository;
  final TransactionRepository _transactionRepository;

  WalletBloc({
    required ClientRepository clientRepository,
    required TransactionRepository transactionRepository,
  })  : _clientRepository = clientRepository,
        _transactionRepository = transactionRepository,
        super(WalletInitial()) {
    on<LoadWalletEvent>(_onLoadWallet);
    on<TopUpEvent>(_onTopUp);
  }

  Future<void> _onLoadWallet(
      LoadWalletEvent event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    try {
      final client = await _clientRepository.getById(event.clientId);
      if (client == null) {
        emit(const WalletError(message: 'ไม่พบข้อมูลผู้ใช้'));
        return;
      }
      final transactions =
          await _transactionRepository.getByClientId(event.clientId);
      emit(WalletLoaded(client: client, transactions: transactions));
    } catch (e) {
      emit(const WalletError(message: 'โหลดข้อมูลกระเป๋าเงินไม่สำเร็จ'));
    }
  }

  Future<void> _onTopUp(TopUpEvent event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    try {
      const uuid = Uuid();
      final tx = TransactionModel(
        transactionId: uuid.v4(),
        transactionType: 'เติมเงิน',
        amount: event.amount,
        bankName: event.bankName,
        accountName: event.accountName,
        accountNumber: event.accountNumber,
        referenceNo: event.referenceNo,
        transactionDate: DateTime.now(),
        transactionStatus: 'สำเร็จ',
        clientId: event.clientId,
      );
      await _transactionRepository.save(tx);
      final client = await _clientRepository.getById(event.clientId);
      if (client == null) {
        emit(const WalletError(message: 'ไม่พบข้อมูลผู้ใช้'));
        return;
      }
      final newBalance = client.walletBalance + event.amount;
      await _clientRepository.updateBalance(
          event.clientId, newBalance, client.pendingBalance);
      emit(TopUpSuccess(newBalance: newBalance));
    } catch (e) {
      emit(const WalletError(message: 'เติมเงินไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }
}
