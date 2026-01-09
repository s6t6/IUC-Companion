import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../views/widgets/onboarding/profie_step.dart';
import '../views/widgets/onboarding/schedule_step.dart';
import '../views/widgets/onboarding/transcript_step.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../viewmodels/simulation_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/schedule_viewmodel.dart';
import '../viewmodels/transcript_viewmodel.dart';
import 'main_screen.dart';


class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<OnboardingViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kurulum Sihirbazı"),
        centerTitle: true,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: viewModel.currentStep,

        onStepTapped: (step) {},

        onStepContinue: () async {
          if (viewModel.currentStep == 0) {
            if (viewModel.isStep1Valid) {
              viewModel.nextStep();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                      "Lütfen profil ismi, fakülte ve bölümü eksiksiz giriniz."),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          }
          else if (viewModel.currentStep == 1) {
            viewModel.nextStep();
          }
          else {
            bool success = await viewModel.completeOnboarding();

            if (success && context.mounted) {
              final homeViewModel =
              Provider.of<HomeViewModel>(context, listen: false);
              await homeViewModel.loadCourses();

              final simViewModel =
              Provider.of<SimulationViewModel>(context, listen: false);
              await simViewModel.initialize();

              final schedViewModel =
              Provider.of<ScheduleViewModel>(context, listen: false);
              schedViewModel.loadScheduleForActiveProfile();

              final transcriptViewModel =
              Provider.of<TranscriptViewModel>(context, listen: false);
              transcriptViewModel.loadData();

              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const MainScreen()));
            }
          }
        },

        onStepCancel: () {
          if (viewModel.currentStep > 0) {
            viewModel.prevStep();
          }
        },

        controlsBuilder: (context, details) {
          final isLastStep = viewModel.currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: viewModel.isLoading
                        ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: colorScheme.onPrimary, strokeWidth: 2))
                        : Text(
                      isLastStep ? "Kurulumu Tamamla" : "Devam Et",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (viewModel.currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                    ),
                    child: const Text("Geri"),
                  ),
                ],
              ],
            ),
          );
        },

        steps: [
          Step(
            title: const Text("Profil"),
            isActive: viewModel.currentStep >= 0,
            state: viewModel.currentStep > 0
                ? StepState.complete
                : StepState.indexed,
            content: const ProfileStep(),
          ),
          Step(
            title: const Text("Notlar"),
            isActive: viewModel.currentStep >= 1,
            state: viewModel.currentStep > 1
                ? StepState.complete
                : StepState.indexed,
            content: const TranscriptStep(),
          ),
          Step(
            title: const Text("Program"),
            isActive: viewModel.currentStep >= 2,
            content: const ScheduleStep(),
          ),
        ],
      ),
    );
  }
}