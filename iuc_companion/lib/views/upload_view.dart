import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Tarih formatı için
import '../core/constants/app_colors.dart';
import '../viewmodels/upload_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class UploadView extends StatelessWidget {
  const UploadView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UploadViewModel>();
    final user = context.watch<AuthViewModel>().currentUser;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dosya Yükle", style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // Yükleme Alanı
          GestureDetector(
            onTap: () {
              if (user != null) {
                viewModel.uploadFile(user.id);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen önce giriş yapın")));
              }
            },
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold, style: BorderStyle.solid, width: 1),
              ),
              child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 50, color: AppColors.gold),
                      SizedBox(height: 10),
                      Text("PDF Seçmek İçin Dokun", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
            ),
          ),
          
          const SizedBox(height: 30),
          const Text("Yüklenen Belgeler", style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // Dosya Listesi
          Expanded(
            child: viewModel.uploadedFiles.isEmpty
            ? const Center(child: Text("Henüz dosya yüklenmedi.", style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                itemCount: viewModel.uploadedFiles.length,
                itemBuilder: (context, index) {
                  final file = viewModel.uploadedFiles[index];
                  // Tarihi formatla (örn: 30.12.2024)
                  final dateStr = DateFormat('dd.MM.yyyy').format(file.uploadDate);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.picture_as_pdf, color: AppColors.gold),
                    ),
                    title: Text(file.name, style: const TextStyle(color: AppColors.white)),
                    // Boyut yerine Tarih ve Tür gösteriyoruz
                    subtitle: Text("$dateStr • ${file.type}", style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                    trailing: const Icon(Icons.check_circle, color: AppColors.green, size: 20),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }
}