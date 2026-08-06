class BiddingModel {
  final String biddingId;
  final int bidPrice;
  final String? messageToClient;
  final String biddingStatus;
  final DateTime biddingDate;
  final String jobId;
  final String contractorId;
  final String truckId;

  const BiddingModel({
    required this.biddingId,
    required this.bidPrice,
    this.messageToClient,
    required this.biddingStatus,
    required this.biddingDate,
    required this.jobId,
    required this.contractorId,
    required this.truckId,
  });

  factory BiddingModel.fromJson(Map<String, dynamic> json) => BiddingModel(
        biddingId: json['biddingId'] as String,
        bidPrice: (json['bidPrice'] as num).toInt(),
        messageToClient: json['messageToClient'] as String?,
        biddingStatus: json['biddingStatus'] as String,
        biddingDate: DateTime.parse(json['biddingDate'] as String),
        jobId: json['jobId'] as String,
        contractorId: json['contractorId'] as String,
        truckId: json['truckId'] as String,
      );

  Map<String, dynamic> toJson() => {
        'biddingId': biddingId,
        'bidPrice': bidPrice,
        if (messageToClient != null) 'messageToClient': messageToClient,
        'biddingStatus': biddingStatus,
        'biddingDate': biddingDate.toIso8601String(),
        'jobId': jobId,
        'contractorId': contractorId,
        'truckId': truckId,
      };
}
