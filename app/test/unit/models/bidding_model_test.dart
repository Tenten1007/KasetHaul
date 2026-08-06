import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/bidding_model.dart';

void main() {
  group('BiddingModel.fromJson', () {
    final Map<String, dynamic> validJson = {
      'biddingId': 'bid-001',
      'bidPrice': 2500,
      'biddingStatus': 'รอการตอบรับ',
      'biddingDate': '2026-05-14T09:00:00.000',
      'jobId': 'job-001',
      'contractorId': 'contractor-001',
      'truckId': 'truck-001',
    };

    test('parses required fields correctly', () {
      final bid = BiddingModel.fromJson(validJson);

      expect(bid.biddingId, 'bid-001');
      expect(bid.bidPrice, 2500);
      expect(bid.biddingStatus, 'รอการตอบรับ');
      expect(bid.jobId, 'job-001');
      expect(bid.contractorId, 'contractor-001');
      expect(bid.truckId, 'truck-001');
    });

    test('parses biddingDate from ISO string', () {
      final bid = BiddingModel.fromJson(validJson);
      expect(bid.biddingDate, DateTime.parse('2026-05-14T09:00:00.000'));
    });

    test('messageToClient is null when not present', () {
      final bid = BiddingModel.fromJson(validJson);
      expect(bid.messageToClient, isNull);
    });

    test('messageToClient is parsed when present', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['messageToClient'] = 'มีรถว่างพร้อมรับงาน';
      final bid = BiddingModel.fromJson(json);
      expect(bid.messageToClient, 'มีรถว่างพร้อมรับงาน');
    });

    test('bidPrice accepts numeric types', () {
      final json = Map<String, dynamic>.from(validJson)..['bidPrice'] = 2500.0;
      final bid = BiddingModel.fromJson(json);
      expect(bid.bidPrice, 2500);
    });

    test('throws on invalid date string', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['biddingDate'] = 'invalid-date';
      expect(() => BiddingModel.fromJson(json), throwsA(isA<FormatException>()));
    });
  });

  group('BiddingModel.toJson', () {
    final bid = BiddingModel(
      biddingId: 'bid-999',
      bidPrice: 3000,
      messageToClient: 'ราคานี้รวมค่าน้ำมันแล้ว',
      biddingStatus: 'รอการตอบรับ',
      biddingDate: DateTime(2026, 5, 14, 9, 30),
      jobId: 'job-999',
      contractorId: 'contractor-999',
      truckId: 'truck-999',
    );

    test('toJson includes all required fields', () {
      final json = bid.toJson();

      expect(json['biddingId'], 'bid-999');
      expect(json['bidPrice'], 3000);
      expect(json['biddingStatus'], 'รอการตอบรับ');
      expect(json['jobId'], 'job-999');
      expect(json['contractorId'], 'contractor-999');
      expect(json['truckId'], 'truck-999');
    });

    test('toJson includes messageToClient when present', () {
      final json = bid.toJson();
      expect(json['messageToClient'], 'ราคานี้รวมค่าน้ำมันแล้ว');
    });

    test('toJson omits messageToClient when null', () {
      final bidNoMsg = BiddingModel(
        biddingId: 'bid-998',
        bidPrice: 2000,
        biddingStatus: 'รอการตอบรับ',
        biddingDate: DateTime(2026, 5, 14),
        jobId: 'job-998',
        contractorId: 'contractor-998',
        truckId: 'truck-998',
      );
      final json = bidNoMsg.toJson();
      expect(json.containsKey('messageToClient'), isFalse);
    });

    test('fromJson(toJson()) roundtrip preserves data', () {
      final json = bid.toJson();
      final restored = BiddingModel.fromJson(json);

      expect(restored.biddingId, bid.biddingId);
      expect(restored.bidPrice, bid.bidPrice);
      expect(restored.messageToClient, bid.messageToClient);
      expect(restored.biddingStatus, bid.biddingStatus);
      expect(restored.jobId, bid.jobId);
      expect(restored.contractorId, bid.contractorId);
      expect(restored.truckId, bid.truckId);
    });
  });
}
