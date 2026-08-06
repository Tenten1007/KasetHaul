class TransactionModel {
  final String transactionId;
  final String transactionType;
  final double amount;
  final double? feeAmount;
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? referenceNo;
  final String? slipImageUrl;
  final DateTime transactionDate;
  final String transactionStatus;
  final String? biddingId;
  final String? clientId;
  final String? contractorId;

  const TransactionModel({
    required this.transactionId,
    required this.transactionType,
    required this.amount,
    this.feeAmount,
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.referenceNo,
    this.slipImageUrl,
    required this.transactionDate,
    required this.transactionStatus,
    this.biddingId,
    this.clientId,
    this.contractorId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        transactionId: json['transactionId'] as String,
        transactionType: json['transactionType'] as String,
        amount: (json['amount'] as num).toDouble(),
        feeAmount: (json['feeAmount'] as num?)?.toDouble(),
        bankName: json['bankName'] as String?,
        accountName: json['accountName'] as String?,
        accountNumber: json['accountNumber'] as String?,
        referenceNo: json['referenceNo'] as String?,
        slipImageUrl: json['slipImageUrl'] as String?,
        transactionDate: DateTime.parse(json['transactionDate'] as String),
        transactionStatus: json['transactionStatus'] as String,
        biddingId: json['biddingId'] as String?,
        clientId: json['clientId'] as String?,
        contractorId: json['contractorId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'transactionId': transactionId,
        'transactionType': transactionType,
        'amount': amount,
        if (feeAmount != null) 'feeAmount': feeAmount,
        if (bankName != null) 'bankName': bankName,
        if (accountName != null) 'accountName': accountName,
        if (accountNumber != null) 'accountNumber': accountNumber,
        if (referenceNo != null) 'referenceNo': referenceNo,
        if (slipImageUrl != null) 'slipImageUrl': slipImageUrl,
        'transactionDate': transactionDate.toIso8601String(),
        'transactionStatus': transactionStatus,
        if (biddingId != null) 'biddingId': biddingId,
        if (clientId != null) 'clientId': clientId,
        if (contractorId != null) 'contractorId': contractorId,
      };
}
