import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/schedule_viewmodel.dart';
import '../../viewmodels/simulation_viewmodel.dart';
import '../../viewmodels/onboarding_viewmodel.dart';
import '../../viewmodels/transcript_viewmodel.dart';
import '../../data/models/profile.dart';
import '../profile_view.dart';
import '../onboarding_view.dart';

class ProfileSelectionDialog extends StatelessWidget {
  const ProfileSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = Provider.of<HomeViewModel>(context);

    return Dialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Profiller", style: theme.textTheme.titleLarge),
          ),
          const Divider(height: 1),

          if (vm.savedProfiles.isEmpty)
            Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Kayıtlı profil bulunamadı.", style: theme.textTheme.bodyMedium)
            ),

          ...vm.savedProfiles.map((Profile profile) {
            final isActive = profile.id == vm.activeProfileId;
            final tileColor = isActive
                ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                : Colors.transparent;

            return Container(
              color: tileColor,
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: isActive ? theme.colorScheme.primary : theme.disabledColor,
                    child: Icon(Icons.person, color: theme.colorScheme.onPrimary)
                ),
                title: Text(profile.profileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(profile.departmentName, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: isActive
                    ? IconButton(
                  icon: Icon(Icons.settings, color: theme.iconTheme.color),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileView()),
                    );
                  },
                )
                    : null,

                onTap: () async {
                  if (!isActive) {
                    await vm.switchProfile(profile);

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    Provider.of<SimulationViewModel>(context, listen: false).initialize();
                    Provider.of<ScheduleViewModel>(context, listen: false).loadScheduleForActiveProfile();
                    Provider.of<TranscriptViewModel>(context, listen: false).loadData();
                  }
                },
              ),
            );
          }).toList(),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Provider.of<OnboardingViewModel>(context, listen: false).reset();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OnboardingView()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Yeni Profil Ekle"),
              ),
            ),
          )
        ],
      ),
    );
  }
}