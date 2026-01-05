import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../viewmodels/schedule_builder_viewmodel.dart';

class ScheduleBuilderView extends StatelessWidget {
  const ScheduleBuilderView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScheduleBuilderViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ders Programı Oluşturucu", style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Üniversitenin ders programı PDF'ini ve kendi ders planını yükle, sana en uygun programı çıkaralım.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),

          // 1. Program Dosyası
          _buildUploadCard(
            title: "Genel Ders Programı",
            fileName: vm.programFileName,
            onTap: vm.pickProgramFile,
            icon: Icons.table_chart,
          ),
          
          const SizedBox(height: 20),

          // 2. Ders Planı Dosyası
          _buildUploadCard(
            title: "Ders Planın (Müfredat)",
            fileName: vm.syllabusFileName,
            onTap: vm.pickSyllabusFile,
            icon: Icons.list_alt,
          ),

          const SizedBox(height: 40),

          if (vm.isGenerating)
            const Center(child: CircularProgressIndicator(color: AppColors.gold))
          else if (vm.isSuccess)
             Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(color: AppColors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.green)),
               child: const Row(
                 children: [
                   Icon(Icons.check_circle, color: AppColors.green),
                   SizedBox(width: 10),
                   Expanded(child: Text("Program başarıyla oluşturuldu ve takvimine eklendi!", style: TextStyle(color: AppColors.white))),
                 ],
               ),
             )
          else
            ElevatedButton(
              onPressed: (vm.programFileName != null && vm.syllabusFileName != null) 
                ? vm.generateSchedule 
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold, 
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50)
              ),
              child: const Text("PROGRAMI OLUŞTUR", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({required String title, String? fileName, required VoidCallback onTap, required IconData icon}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: fileName != null ? AppColors.gold : Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: fileName != null ? AppColors.gold : Colors.grey, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(fileName ?? "Dosya Seçilmedi", style: TextStyle(color: fileName != null ? AppColors.goldAccent : Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (fileName != null) const Icon(Icons.check, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}