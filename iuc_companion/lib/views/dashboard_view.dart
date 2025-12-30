import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Icon(Icons.verified_user, size: 100, color: AppColors.gold), // Logo yerine icon koydum hata vermesin diye
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Text("Hoş Geldin, ${user?.name}", style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(user?.department ?? "", textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white)),
                const SizedBox(height: 20),
                const Text("Derslerinde başarılar dileriz.", style: TextStyle(color: AppColors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}