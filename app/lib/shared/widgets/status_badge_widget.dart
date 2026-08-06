import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class StatusBadgeWidget extends StatelessWidget {
  final String status;

  const StatusBadgeWidget({super.key, required this.status});

  Color get _bgColor {
    switch (status) {
      case 'เปิดรับข้อเสนอ':
      case 'รอผู้รับจ้าง':
        return const Color(0xFFE3F2FD);
      case 'มอบหมายแล้ว':
        return const Color(0xFFFFF3E0);
      case 'ถึงจุดรับสินค้า':
      case 'รับสินค้าเรียบร้อย':
        return const Color(0xFFE3F2FD);
      case 'กำลังขนส่ง':
        return const Color(0xFFE8F5E9);
      case 'ถึงจุดส่งสินค้า':
        return const Color(0xFFF3E5F5);
      case 'จัดส่งสำเร็จ':
        return const Color(0xFFE8F5E9);
      case 'ยกเลิก':
        return const Color(0xFFFFEBEE);
      default:
        return AppConfig.surfaceColor;
    }
  }

  Color get _textColor {
    switch (status) {
      case 'เปิดรับข้อเสนอ':
      case 'รอผู้รับจ้าง':
        return const Color(0xFF2196F3);
      case 'มอบหมายแล้ว':
        return const Color(0xFFE65100);
      case 'ถึงจุดรับสินค้า':
      case 'รับสินค้าเรียบร้อย':
        return const Color(0xFF1976D2);
      case 'กำลังขนส่ง':
        return AppConfig.primaryColor;
      case 'ถึงจุดส่งสินค้า':
        return const Color(0xFF7B1FA2);
      case 'จัดส่งสำเร็จ':
        return const Color(0xFF4CAF50);
      case 'ยกเลิก':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF757575);
    }
  }

  String get _displayText => status == 'รอผู้รับจ้าง' ? 'เปิดรับข้อเสนอ' : status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _displayText,
        style: TextStyle(
          color: _textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


