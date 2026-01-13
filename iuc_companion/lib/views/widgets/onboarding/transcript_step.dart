import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/onboarding_viewmodel.dart';

class TranscriptStep extends StatelessWidget {
  const TranscriptStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<OnboardingViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(Icons.description_outlined, size: 64, color: colorScheme.primary),
        const SizedBox(height: 16),
        Text("Transkript Yükle", style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          "PDF transkriptinizi yükleyerek geçmiş derslerinizi ve notlarınızı otomatik aktarabilirsiniz.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 24),

        if (viewModel.errorMessage != null)
          _buildErrorBox(context, viewModel.errorMessage!),

        if (viewModel.isLoading)
          const CircularProgressIndicator()
        else if (viewModel.extractedCourseCount > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle,
                    color: colorScheme.primary, size: 32),
                const SizedBox(height: 8),
                Text(
                  "Başarılı! ${viewModel.extractedCourseCount} ders notu alındı. Eksik veya yanlış aktarılmış dersleri profil>profil ayarları "
                      "sayfasından düzeltebilirsiniz.",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(viewModel.uploadedTranscriptName ?? "",
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8))),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () async {
              await viewModel.pickAndProcessTranscript();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              side: BorderSide(color: colorScheme.primary),
              foregroundColor: colorScheme.primary,
            ),
            icon: const Icon(Icons.upload_file),
            label: const Text("PDF Transkript Seç"),
          ),
      ],
    );
  }

  Widget _buildErrorBox(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: colorScheme.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}