import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final BiddingRepository _biddingRepository;
  final JobRepository _jobRepository;
  final ClientRepository _clientRepository;
  final TransactionRepository _transactionRepository;
  final NotificationRepository _notificationRepository;

  PaymentBloc({
    required BiddingRepository biddingRepository,
    required JobRepository jobRepository,
    required ClientRepository clientRepository,
    required TransactionRepository transactionRepository,
    NotificationRepository? notificationRepository,
  })  : _biddingRepository = biddingRepository,
        _jobRepository = jobRepository,
        _clientRepository = clientRepository,
        _transactionRepository = transactionRepository,
        _notificationRepository =
            notificationRepository ?? NotificationRepository(),
        super(PaymentInitial()) {
    on<AcceptBiddingEvent>(_onAcceptBidding);
  }

  Future<void> _onAcceptBidding(
      AcceptBiddingEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());

    // ค่าธรรมเนียม = bidPrice × AppConfig.platformFeePerSide (1.5%)
    final fee = event.bidPrice * AppConfig.platformFeePerSide;
    final total = event.bidPrice + fee;

    // ตรวจสอบยอดเงินใน walletBalance ว่าเพียงพอหรือไม่
    if (event.clientWalletBalance < total) {
      emit(InsufficientBalance(
          required: total, current: event.clientWalletBalance));
      return;
    }

    try {
      const uuid = Uuid();

      // 1. เปลี่ยน biddingStatus ของ bidding ที่เลือก → 'ได้รับเลือก'
      await _biddingRepository.updateStatus(event.biddingId, 'ได้รับเลือก');

      // 2. เปลี่ยน biddingStatus ของ bidding อื่นๆ ในงานเดียวกัน → 'ยกเลิก'
      for (final id in event.otherBiddingIds) {
        await _biddingRepository.updateStatus(id, 'ยกเลิก');
      }

      // 3. เปลี่ยน jobStatus → 'มอบหมายแล้ว' (stage 1 ตาม SRS 3.1.8)
      await _jobRepository.updateStatus(event.jobId, 'มอบหมายแล้ว');
      await _jobRepository.updateAgreedPrice(event.jobId, event.bidPrice);

      // 4. หักเงิน client: walletBalance -= (bidPrice + fee), pendingBalance += bidPrice
      final newWallet = event.clientWalletBalance - total;
      final newPending = event.clientPendingBalance + event.bidPrice;
      await _clientRepository.updateBalance(
          event.clientId, newWallet, newPending);

      // 5. สร้าง Transaction บันทึกการจ่ายค่างาน
      final tx = TransactionModel(
        transactionId: uuid.v4(),
        transactionType: 'จ่ายค่างาน',
        amount: event.bidPrice.toDouble(),
        feeAmount: fee,
        transactionDate: DateTime.now(),
        transactionStatus: 'รอดำเนินการ',
        biddingId: event.biddingId,
        clientId: event.clientId,
      );
      await _transactionRepository.save(tx);

      // 6. ส่งแจ้งเตือนถึงผู้รับจ้างที่ถูกเลือก (UC 3.1.8)
      await _notificationRepository.save(NotificationModel(
        notificationId: uuid.v4(),
        recipientId: event.contractorId,
        recipientRole: 'contractor',
        title: 'งานของคุณถูกมอบหมาย',
        body: 'คุณได้รับเลือกให้ขนส่งงาน "${event.jobTitle}"',
        type: 'งานถูกมอบหมาย',
        relatedId: event.jobId,
        createdDate: DateTime.now(),
      ));

      emit(AcceptBiddingSuccess());
    } catch (e) {
      emit(const PaymentError(message: 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'));
    }
  }
}
