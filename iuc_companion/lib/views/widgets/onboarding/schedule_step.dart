import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/onboarding_viewmodel.dart';

class ScheduleStep extends StatelessWidget {
  const ScheduleStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<OnboardingViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(Icons.calendar_month_outlined,
            size: 64, color: colorScheme.primary),
        const SizedBox(height: 16),
        Text("Ders Programı Yükle", style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          "Ders programı PDF'ini yükleyerek takvimini otomatik oluşturabilirsin.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 24),

        if (viewModel.errorMessage != null)
          _buildErrorBox(context, viewModel.errorMessage!),

        if (viewModel.isLoading)
          const CircularProgressIndicator()
        else if (viewModel.hasSchedule)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.check, color: colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  "Program başarıyla okundu!",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(viewModel.uploadedScheduleName ?? "",
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8))),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () => viewModel.pickAndProcessSchedule(),
            icon: const Icon(Icons.upload_file),
            label: const Text("Program PDF'i Seç"),
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