import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../job/bloc/contractor_job_bloc.dart';
import '../../job/pages/contractor_my_jobs_page.dart';
import '../../job/pages/search_jobs_page.dart';
import '../../wallet/pages/earnings_page.dart';
import '../../profile/pages/contractor_profile_page.dart';

class ContractorHomePage extends StatefulWidget {
  final String contractorId;
  const ContractorHomePage({super.key, required this.contractorId});

  @override
  State<ContractorHomePage> createState() => _ContractorHomePageState();
}

class _ContractorHomePageState extends State<ContractorHomePage> {
  int _currentIndex = 0;

  late final ContractorJobBloc _contractorJobBloc;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _contractorJobBloc = ContractorJobBloc(
      jobRepository: JobRepository(),
      biddingRepository: BiddingRepository(),
      transactionRepository: TransactionRepository(),
      contractorRepository: ContractorRepository(),
    );

    _pages = [
      // แท็บ 1: ค้นหางาน — SearchJobsPage สร้าง BlocProvider ของตัวเอง
      SearchJobsPage(contractorId: widget.contractorId),
      // แท็บ 2: งานของฉัน — ใช้ ContractorJobBloc ที่สร้างไว้ข้างบน
      BlocProvider.value(
        value: _contractorJobBloc,
        child: ContractorMyJobsPage(contractorId: widget.contractorId),
      ),
      // แท็บ 3: รายได้ — ใช้ ContractorJobBloc เดียวกัน
      BlocProvider.value(
        value: _contractorJobBloc,
        child: EarningsPage(contractorId: widget.contractorId),
      ),
      // แท็บ 4: โปรไฟล์ (จัดการรถอยู่ใน profile)
      ContractorProfilePage(contractorId: widget.contractorId),
    ];
  }

  @override
  void dispose() {
    _contractorJobBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppConfig.primaryColor,
        unselectedItemColor: AppConfig.textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Text('🔍', style: TextStyle(fontSize: 24)), label: 'ค้นหางาน'),
          BottomNavigationBarItem(
              icon: Text('📋', style: TextStyle(fontSize: 24)), label: 'งานของฉัน'),
          BottomNavigationBarItem(
              icon: Text('💰', style: TextStyle(fontSize: 24)), label: 'รายได้'),
          BottomNavigationBarItem(
              icon: Text('👤', style: TextStyle(fontSize: 24)), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}
