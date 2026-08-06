import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/repositories.dart';

/// BLoC ใช้ซ้ำสำหรับ "การ์ดงาน" ที่ต้องโหลดข้อมูลเสริม:
///  - จำนวนข้อเสนอ (bidding count) — ใช้ทั้งใน MyJobs (ฝั่งผู้ว่าจ้าง) และ SearchJobs (ฝั่งผู้รับจ้าง)
///  - สถานะรีวิว + ผู้รับจ้างที่ได้รับเลือก (เฉพาะงาน "จัดส่งสำเร็จ" ฝั่งผู้ว่าจ้าง)
/// โหลดข้อมูลตอน load ครั้งเดียว เพื่อให้ตอนกดรีวิวไม่ต้องเรียก Repository ในหน้า

// ── State ───────────────────────────────────────────────────────────────────
class JobCardState extends Equatable {
  final int? biddingCount;
  final bool hasReviewed;
  final bool checkingReview;
  final String? acceptedContractorId; // ผู้รับจ้างที่ได้รับเลือก (สำหรับหน้ารีวิว)

  const JobCardState({
    this.biddingCount,
    this.hasReviewed = false,
    this.checkingReview = false,
    this.acceptedContractorId,
  });

  JobCardState copyWith({
    int? biddingCount,
    bool? hasReviewed,
    bool? checkingReview,
    String? acceptedContractorId,
  }) =>
      JobCardState(
        biddingCount: biddingCount ?? this.biddingCount,
        hasReviewed: hasReviewed ?? this.hasReviewed,
        checkingReview: checkingReview ?? this.checkingReview,
        acceptedContractorId: acceptedContractorId ?? this.acceptedContractorId,
      );

  @override
  List<Object?> get props =>
      [biddingCount, hasReviewed, checkingReview, acceptedContractorId];
}

// ── Events ──────────────────────────────────────────────────────────────────
abstract class JobCardEvent extends Equatable {
  const JobCardEvent();
  @override
  List<Object?> get props => [];
}

class LoadJobCard extends JobCardEvent {
  final String jobId;
  final bool loadBiddingCount;
  final bool loadReview;
  const LoadJobCard(
    this.jobId, {
    this.loadBiddingCount = false,
    this.loadReview = false,
  });
  @override
  List<Object?> get props => [jobId, loadBiddingCount, loadReview];
}

/// รีเฟรชสถานะรีวิวใหม่ (หลังกลับจากหน้าเขียนรีวิว)
class RefreshReviewStatus extends JobCardEvent {
  final String jobId;
  const RefreshReviewStatus(this.jobId);
  @override
  List<Object?> get props => [jobId];
}

// ── Bloc ────────────────────────────────────────────────────────────────────
class JobCardBloc extends Bloc<JobCardEvent, JobCardState> {
  final BiddingRepository _biddingRepo;
  final ReviewRepository _reviewRepo;

  JobCardBloc({
    BiddingRepository? biddingRepository,
    ReviewRepository? reviewRepository,
  })  : _biddingRepo = biddingRepository ?? BiddingRepository(),
        _reviewRepo = reviewRepository ?? ReviewRepository(),
        super(const JobCardState()) {
    on<LoadJobCard>(_onLoad);
    on<RefreshReviewStatus>(_onRefreshReview);
  }

  Future<void> _onLoad(LoadJobCard event, Emitter<JobCardState> emit) async {
    int? count = state.biddingCount;
    bool reviewed = state.hasReviewed;
    String? acceptedId = state.acceptedContractorId;
    try {
      if (event.loadBiddingCount) {
        final bids = await _biddingRepo.getByJobId(event.jobId);
        count = bids.length;
      }
      if (event.loadReview) {
        final reviews = await _reviewRepo.getByJobId(event.jobId);
        reviewed = reviews.isNotEmpty;
        final bids = await _biddingRepo.getByJobId(event.jobId);
        acceptedId = bids
            .where((b) => b.biddingStatus == 'ได้รับเลือก')
            .firstOrNull
            ?.contractorId;
      }
      emit(JobCardState(
        biddingCount: count,
        hasReviewed: reviewed,
        acceptedContractorId: acceptedId,
      ));
    } catch (_) {
      // เงียบไว้ (เดิมก็ swallow error) — คงค่า state เดิม
    }
  }

  Future<void> _onRefreshReview(
    RefreshReviewStatus event,
    Emitter<JobCardState> emit,
  ) async {
    emit(state.copyWith(checkingReview: true));
    try {
      final reviews = await _reviewRepo.getByJobId(event.jobId);
      emit(state.copyWith(hasReviewed: reviews.isNotEmpty, checkingReview: false));
    } catch (_) {
      emit(state.copyWith(checkingReview: false));
    }
  }
}
