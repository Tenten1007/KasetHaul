class AppRoutes {
  AppRoutes._();

  // ============================================================
  // Root
  // ============================================================
  static const String splash = '/';
  static const String roleSelect = '/role-select';

  // ============================================================
  // Client Auth (UC 3.1.1–3.1.2)
  // ============================================================
  static const String clientLogin = '/client/login';
  static const String clientRegister = '/client/register';

  // ============================================================
  // Client Main
  // ============================================================
  static const String clientHome = '/client/home';

  // ============================================================
  // Client — Job (UC 3.1.4–3.1.13)
  // ============================================================
  static const String clientPostJob = '/client/post-job';
  static const String clientListJob = '/client/list-job';
  static const String clientViewJobDetail = '/client/job-detail';
  static const String clientEditJob = '/client/edit-job';
  static const String clientCancelJob = '/client/cancel-job';
  static const String clientListBidding = '/client/list-bidding';
  static const String clientViewBidding = '/client/view-bidding';
  static const String clientAssignContractor = '/client/assign-contractor';
  static const String clientInternalPayment = '/client/internal-payment';
  static const String clientReviewContractor = '/client/review-contractor';
  static const String clientTrackGPS = '/client/track-gps';

  // ============================================================
  // Client — Wallet (UC 3.1.15–3.1.16)
  // ============================================================
  static const String clientDepositMoney = '/client/deposit';
  static const String clientViewStatistics = '/client/statistics';

  // ============================================================
  // Client — Profile (UC 3.1.3)
  // ============================================================
  static const String clientEditProfile = '/client/edit-profile';

  // ============================================================
  // Contractor Auth (UC 3.1.17–3.1.18)
  // ============================================================
  static const String contractorLogin = '/contractor/login';
  static const String contractorRegister = '/contractor/register';

  // ============================================================
  // Contractor Main
  // ============================================================
  static const String contractorHome = '/contractor/home';

  // ============================================================
  // Contractor — Identity (UC 3.1.19)
  // ============================================================
  static const String contractorVerifyIdentity = '/contractor/verify-identity';

  // ============================================================
  // Contractor — Profile (UC 3.1.20)
  // ============================================================
  static const String contractorEditProfile = '/contractor/edit-profile';

  // ============================================================
  // Contractor — Truck (UC 3.1.21–3.1.25)
  // ============================================================
  static const String contractorAddTruck = '/contractor/add-truck';
  static const String contractorListTruck = '/contractor/list-truck';
  static const String contractorViewTruck = '/contractor/view-truck';
  static const String contractorEditTruck = '/contractor/edit-truck';
  static const String contractorRemoveTruck = '/contractor/remove-truck';

  // ============================================================
  // Contractor — Job (UC 3.1.26–3.1.33)
  // ============================================================
  static const String contractorSearchJob = '/contractor/search-job';
  static const String contractorViewJobDetail = '/contractor/job-detail';
  static const String contractorSubmitBidding = '/contractor/submit-bidding';
  static const String contractorEditBidding = '/contractor/edit-bidding';
  static const String contractorCancelBidding = '/contractor/cancel-bidding';
  static const String contractorListMyJob = '/contractor/my-jobs';
  static const String contractorUpdateJobStatus = '/contractor/update-status';
  static const String contractorReviewClient = '/contractor/review-client';

  // ============================================================
  // Contractor — Wallet (UC 3.1.34–3.1.35)
  // ============================================================
  static const String contractorWithdrawMoney = '/contractor/withdraw';
  static const String contractorViewEarnings = '/contractor/earnings';

  // ============================================================
  // Admin Auth (UC 3.1.36)
  // ============================================================
  static const String adminLogin = '/admin/login';

  // ============================================================
  // Admin Main
  // ============================================================
  static const String adminHome = '/admin/home';

  // ============================================================
  // Admin — Truck (UC 3.1.37–3.1.39)
  // ============================================================
  static const String adminListTruck = '/admin/list-truck';
  static const String adminViewTruckDetail = '/admin/truck-detail';
  static const String adminApproveTruck = '/admin/approve-truck';

  // ============================================================
  // Admin — Dashboard
  // ============================================================
  static const String adminDashboard = '/admin/dashboard';
}
