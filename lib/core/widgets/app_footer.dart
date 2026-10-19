import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../services/config_service.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final company = ConfigService.companyName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          '$company • AScobrar v2.0',
          style: TextStyle(
            color: AppColors.textMuted.withOpacity(0.65),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
