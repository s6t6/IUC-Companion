import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../viewmodels/calculator_viewmodel.dart';
import '../viewmodels/upload_viewmodel.dart';

class CalculatorView extends StatelessWidget {
  const CalculatorView({super.key});

  @override
  Widget build(BuildContext context) {
    final calcVm = context.watch<CalculatorViewModel>();
    
    // Transkript seçimi için UploadViewModel'e erişim
    final uploadVm = context.read<UploadViewModel>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Transkripten Çek Butonu
          InkWell(
            onTap: () {
                // Basit bir dialog ile dosya seçtirelim
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text("Transkript Seç", style: TextStyle(color: AppColors.white)),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: uploadVm.uploadedFiles.length,
                      itemBuilder: (c, i) => ListTile(
                        title: Text(uploadVm.uploadedFiles[i].name, style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          calcVm.loadFromTranscript(uploadVm.uploadedFiles[i].id);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ),
                ));
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.gold)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.gold),
                  SizedBox(width: 10),
                  Text("Transkriptten Notları Getir", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Ortalama Göstergesi
          Text(calcVm.currentGpa.toStringAsFixed(2), style: const TextStyle(color: AppColors.white, fontSize: 40, fontWeight: FontWeight.bold)),
          const Text("Genel Ortalama", style: TextStyle(color: AppColors.grey)),
          
          const Divider(color: Colors.grey),
          
          // Ders Listesi
          Expanded(
            child: calcVm.isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView.builder(
              itemCount: calcVm.courses.length,
              itemBuilder: (context, index) {
                final course = calcVm.courses[index];
                return ListTile(
                  title: Text(course.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text("${course.credit} Kredi", style: const TextStyle(color: Colors.grey)),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(5)),
                    child: Text(course.grade, style: const TextStyle(fontWeight: FontWeight.bold)),
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