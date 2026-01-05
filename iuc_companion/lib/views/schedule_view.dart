import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../viewmodels/schedule_viewmodel.dart';

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ScheduleViewModel>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Bugünün Programı", style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              // Manuel yenileme butonu (İsteğe bağlı)
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.gold),
                onPressed: () {
                   // Kullanıcı ID'sini AuthViewModel'den almak gerekir normalde
                   // Şimdilik test için hardcoded ID veriyoruz
                   context.read<ScheduleViewModel>().init("user_123");
                }, 
              )
            ],
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: viewModel.schedule.isEmpty
            ? const Center(child: Text("Bugün için ders bulunamadı.", style: TextStyle(color: Colors.grey)))
            : ListView.builder(
              itemCount: viewModel.schedule.length,
              itemBuilder: (context, index) {
                final item = viewModel.schedule[index];
                // TimeOfDay'i String'e çevirme (Örn: 9:00 AM -> 09:00)
                final startStr = item.startTime.format(context);
                final endStr = item.endTime.format(context);

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.surface, // Varsayılan renk
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Row(
                    children: [
                      // Saat Sütunu
                      Column(
                        children: [
                          Text(startStr, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(endStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.grey, margin: const EdgeInsets.symmetric(horizontal: 15)),
                      
                      // Ders Detayı
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.courseName, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(item.location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(width: 10),
                                Text(item.day, style: const TextStyle(color: AppColors.goldAccent, fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}