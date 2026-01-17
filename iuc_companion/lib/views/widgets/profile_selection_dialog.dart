import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/schedule_viewmodel.dart';
import '../../viewmodels/transcript_viewmodel.dart';
import '../../viewmodels/simulation_viewmodel.dart';
import '../../viewmodels/onboarding_viewmodel.dart';
import '../onboarding_view.dart';
import '../profile_view.dart';

class ProfileSelectionDialog extends StatelessWidget {
  const ProfileSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final homeVM = Provider.of<HomeViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Profil Seç",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: "Profil Ayarları",
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileView()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (homeVM.savedProfiles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text("Kayıtlı başka profil bulunamadı."),
                      )
                    else
                      ...homeVM.savedProfiles.map((profile) {
                        final isActive = profile.id == homeVM.activeProfileId;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.person,
                              color: isActive
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(
                            profile.profileName,
                            style: TextStyle(
                              fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(profile.departmentName),
                          trailing: isActive
                              ? Icon(Icons.check_circle, color: colorScheme.primary)
                              : null,
                          onTap: () async {
                            if (!isActive) {
                              final scheduleVM = Provider.of<ScheduleViewModel>(context, listen: false);
                              final transcriptVM = Provider.of<TranscriptViewModel>(context, listen: false);
                              final simulationVM = Provider.of<SimulationViewModel>(context, listen: false);

                              await homeVM.switchProfileAndRefresh(
                                profile: profile,
                                scheduleVM: scheduleVM,
                                transcriptVM: transcriptVM,
                                simulationVM: simulationVM,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                        );
                      }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(Icons.add, color: colorScheme.onSecondaryContainer),
              ),
              title: const Text("Yeni Profil Oluştur"),
              onTap: () {
                Navigator.pop(context);
                Provider.of<OnboardingViewModel>(context, listen: false).reset();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OnboardingView()),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Kapat"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}