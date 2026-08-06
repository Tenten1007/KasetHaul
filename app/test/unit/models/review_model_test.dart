import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/review_model.dart';

void main() {
  // ─── JSON พื้นฐาน (client รีวิว contractor) ───────────────────────────

  final Map<String, dynamic> clientReviewJson = {
    'reviewId': 'review-001',
    'ratingScore': 5,
    'reviewDate': '2026-06-01T10:00:00.000',
    'jobId': 'job-001',
    'reviewerClientId': 'client-001',
    'revieweeContractorId': 'contractor-001',
  };

  // ─── JSON สำหรับ contractor รีวิว client ─────────────────────────────

  final Map<String, dynamic> contractorReviewJson = {
    'reviewId': 'review-002',
    'ratingScore': 4,
    'reviewDate': '2026-06-02T09:00:00.000',
    'jobId': 'job-002',
    'reviewerContractorId': 'contractor-002',
    'revieweeClientId': 'client-002',
  };

  group('ReviewModel.fromJson', () {
    test('parse required fields ถูกต้อง (client รีวิว contractor)', () {
      final review = ReviewModel.fromJson(clientReviewJson);

      expect(review.reviewId, equals('review-001'));
      expect(review.ratingScore, equals(5));
      expect(review.ratingScore, isA<int>());
      expect(review.jobId, equals('job-001'));
      expect(review.reviewDate, equals(DateTime.parse('2026-06-01T10:00:00.000')));
    });

    test('parse reviewer/reviewee สำหรับ client รีวิว contractor', () {
      final review = ReviewModel.fromJson(clientReviewJson);

      expect(review.reviewerClientId, equals('client-001'));
      expect(review.revieweeContractorId, equals('contractor-001'));
      expect(review.reviewerContractorId, isNull);
      expect(review.revieweeClientId, isNull);
    });

    test('parse reviewer/reviewee สำหรับ contractor รีวิว client', () {
      final review = ReviewModel.fromJson(contractorReviewJson);

      expect(review.reviewerContractorId, equals('contractor-002'));
      expect(review.revieweeClientId, equals('client-002'));
      expect(review.reviewerClientId, isNull);
      expect(review.revieweeContractorId, isNull);
    });

    test('optional fields เป็น null เมื่อไม่ได้ส่งมา', () {
      final review = ReviewModel.fromJson(clientReviewJson);

      expect(review.quickTags, isNull);
      expect(review.reviewComment, isNull);
    });

    test('parse optional quickTags และ reviewComment เมื่อมีค่า', () {
      final json = Map<String, dynamic>.from(clientReviewJson)
        ..addAll({
          'quickTags': 'ตรงเวลา,สุภาพ,ระวังสินค้า',
          'reviewComment': 'ผู้รับจ้างดีมาก ขนส่งตรงเวลา',
        });
      final review = ReviewModel.fromJson(json);

      expect(review.quickTags, equals('ตรงเวลา,สุภาพ,ระวังสินค้า'));
      expect(review.reviewComment, equals('ผู้รับจ้างดีมาก ขนส่งตรงเวลา'));
    });

    test('ratingScore รับ num ได้ (double → int)', () {
      final json = Map<String, dynamic>.from(clientReviewJson)
        ..['ratingScore'] = 4.0;
      final review = ReviewModel.fromJson(json);
      expect(review.ratingScore, equals(4));
      expect(review.ratingScore, isA<int>());
    });

    test('reviewDate parse จาก ISO string ถูกต้อง', () {
      final review = ReviewModel.fromJson(clientReviewJson);
      expect(review.reviewDate, isA<DateTime>());
      expect(review.reviewDate.year, equals(2026));
      expect(review.reviewDate.month, equals(6));
      expect(review.reviewDate.day, equals(1));
    });

    test('throws เมื่อขาด required field reviewId', () {
      final json = Map<String, dynamic>.from(clientReviewJson)..remove('reviewId');
      expect(() => ReviewModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด required field ratingScore', () {
      final json = Map<String, dynamic>.from(clientReviewJson)..remove('ratingScore');
      expect(() => ReviewModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อ reviewDate เป็น string ไม่ถูกรูปแบบ', () {
      final json = Map<String, dynamic>.from(clientReviewJson)
        ..['reviewDate'] = 'not-a-date';
      expect(() => ReviewModel.fromJson(json), throwsA(anything));
    });
  });

  group('ReviewModel.toJson', () {
    test('toJson มี required fields ครบ', () {
      final review = ReviewModel(
        reviewId: 'review-003',
        ratingScore: 5,
        reviewDate: DateTime(2026, 6, 3),
        jobId: 'job-003',
        reviewerClientId: 'client-003',
        revieweeContractorId: 'contractor-003',
      );
      final json = review.toJson();

      expect(json['reviewId'], equals('review-003'));
      expect(json['ratingScore'], equals(5));
      expect(json['jobId'], equals('job-003'));
      expect(json['reviewerClientId'], equals('client-003'));
      expect(json['revieweeContractorId'], equals('contractor-003'));
      expect(json['reviewDate'], isA<String>());
    });

    test('toJson ไม่มี optional fields เมื่อ null', () {
      final review = ReviewModel(
        reviewId: 'review-004',
        ratingScore: 3,
        reviewDate: DateTime(2026, 6, 4),
        jobId: 'job-004',
      );
      final json = review.toJson();

      expect(json.containsKey('quickTags'), isFalse);
      expect(json.containsKey('reviewComment'), isFalse);
      expect(json.containsKey('reviewerClientId'), isFalse);
      expect(json.containsKey('reviewerContractorId'), isFalse);
      expect(json.containsKey('revieweeClientId'), isFalse);
      expect(json.containsKey('revieweeContractorId'), isFalse);
    });

    test('toJson มี optional fields เมื่อมีค่า', () {
      final review = ReviewModel(
        reviewId: 'review-005',
        ratingScore: 4,
        quickTags: 'ตรงเวลา,สุภาพ',
        reviewComment: 'ขนส่งเรียบร้อย',
        reviewDate: DateTime(2026, 6, 5),
        jobId: 'job-005',
        reviewerClientId: 'client-005',
        revieweeContractorId: 'contractor-005',
      );
      final json = review.toJson();

      expect(json['quickTags'], equals('ตรงเวลา,สุภาพ'));
      expect(json['reviewComment'], equals('ขนส่งเรียบร้อย'));
    });

    test('toJson serialize reviewDate เป็น ISO string', () {
      final review = ReviewModel(
        reviewId: 'r-1',
        ratingScore: 5,
        reviewDate: DateTime(2026, 1, 15, 12, 30),
        jobId: 'j-1',
      );
      final json = review.toJson();
      expect(json['reviewDate'], isA<String>());
      expect(() => DateTime.parse(json['reviewDate'] as String), returnsNormally);
    });
  });

  group('ReviewModel roundtrip', () {
    test('fromJson(toJson()) ได้ค่าเดิม — client รีวิว contractor', () {
      final original = ReviewModel(
        reviewId: 'r-rt-1',
        ratingScore: 5,
        quickTags: 'ตรงเวลา,ระวังสินค้า',
        reviewComment: 'ดีมากครับ',
        reviewDate: DateTime(2026, 6, 10, 8, 0),
        jobId: 'job-rt-1',
        reviewerClientId: 'cli-rt-1',
        revieweeContractorId: 'con-rt-1',
      );

      final restored = ReviewModel.fromJson(original.toJson());

      expect(restored.reviewId, equals(original.reviewId));
      expect(restored.ratingScore, equals(original.ratingScore));
      expect(restored.quickTags, equals(original.quickTags));
      expect(restored.reviewComment, equals(original.reviewComment));
      expect(restored.reviewDate, equals(original.reviewDate));
      expect(restored.jobId, equals(original.jobId));
      expect(restored.reviewerClientId, equals(original.reviewerClientId));
      expect(restored.revieweeContractorId, equals(original.revieweeContractorId));
    });

    test('fromJson(toJson()) ได้ค่าเดิม — contractor รีวิว client', () {
      final original = ReviewModel(
        reviewId: 'r-rt-2',
        ratingScore: 4,
        reviewComment: 'ลูกค้าสุภาพ',
        reviewDate: DateTime(2026, 6, 11),
        jobId: 'job-rt-2',
        reviewerContractorId: 'con-rt-2',
        revieweeClientId: 'cli-rt-2',
      );

      final restored = ReviewModel.fromJson(original.toJson());

      expect(restored.reviewerContractorId, equals(original.reviewerContractorId));
      expect(restored.revieweeClientId, equals(original.revieweeClientId));
      expect(restored.reviewerClientId, isNull);
      expect(restored.revieweeContractorId, isNull);
    });
  });
}
