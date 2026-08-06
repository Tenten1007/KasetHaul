import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

class AcceptBiddingEvent extends PaymentEvent {
  final String biddingId;
  final String jobId;
  final String clientId;
  final String contractorId; // ผู้รับจ้างที่ถูกเลือก (สำหรับส่งแจ้งเตือน)
  final String jobTitle;
  final int bidPrice;
  final double clientWalletBalance;
  final double clientPendingBalance;
  final List<String> otherBiddingIds; // bidding IDs ที่ต้องยกเลิก

  const AcceptBiddingEvent({
    required this.biddingId,
    required this.jobId,
    required this.clientId,
    required this.contractorId,
    required this.jobTitle,
    required this.bidPrice,
    required this.clientWalletBalance,
    required this.clientPendingBalance,
    required this.otherBiddingIds,
  });

  @override
  List<Object?> get props => [biddingId, jobId];
}
