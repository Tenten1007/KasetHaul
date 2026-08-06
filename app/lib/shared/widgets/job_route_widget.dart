import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class JobRouteWidget extends StatelessWidget {
  final String from;
  final String to;

  const JobRouteWidget({
    super.key,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppConfig.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            from,
            style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            height: 2,
            color: const Color(0xFFE0E0E0),
          ),
        ),
        Flexible(
          child: Text(
            to,
            style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppConfig.secondaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
