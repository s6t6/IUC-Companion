import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/simulation_viewmodel.dart';
import '../viewmodels/schedule_viewmodel.dart';
import '../viewmodels/transcript_viewmodel.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../data/models/profile.dart';
import 'transcript_view.dart';
import 'onboarding_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final homeViewModel = Provider.of<HomeViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Profile? activeProfile;
    try {
      activeProfile = homeViewModel.savedProfiles.firstWhere(
            (p) => p.id == homeViewModel.activeProfileId,
      );
    } catch (_) {
      activeProfile = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profil Detayı")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.person, size: 50, color: colorScheme.onPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              homeViewModel.departmentName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (activeProfile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  activeProfile.profileName,
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
            const SizedBox(height: 32),

            _buildProfileItem(context, "Bölüm", homeViewModel.departmentName),
            _buildProfileItem(context, "Durum", "Aktif Öğrenci"),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TranscriptView()),
                  ).then((_) {
                    if (context.mounted) {
                      Provider.of<SimulationViewModel>(context, listen: false).initialize();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit_note),
                label: const Text("Transkripti / Notları Düzenle"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
              child: Text(
                "Eğer notlarınızda eksik veya hata varsa buradan manuel olarak düzeltebilirsiniz.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Divider(),
            const SizedBox(height: 16),

            if (activeProfile != null)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmDelete(context, homeViewModel, activeProfile!),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                    ),
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Bu Profili Sil"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        title: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, HomeViewModel homeVM, Profile profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Profili Sil"),
        content: Text(
            "${profile.profileName} profilini silmek istediğinize emin misiniz? \n\nBu işlem geri alınamaz ve tüm ders/not verileriniz silinir."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);

              final scheduleVM = Provider.of<ScheduleViewModel>(context, listen: false);
              final transcriptVM = Provider.of<TranscriptViewModel>(context, listen: false);
              final simulationVM = Provider.of<SimulationViewModel>(context, listen: false);

              await homeVM.deleteProfileAndRefresh(
                profile: profile,
                scheduleVM: scheduleVM,
                transcriptVM: transcriptVM,
                simulationVM: simulationVM,
              );

              if (context.mounted) {
                if (homeVM.savedProfiles.isEmpty) {
                  Provider.of<OnboardingViewModel>(context, listen: false).reset();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const OnboardingView()),
                        (route) => false,
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profil silindi.")),
                  );
                }
              }
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }
}