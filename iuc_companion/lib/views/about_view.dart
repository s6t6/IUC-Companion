import 'package:flutter/material.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Hakkında")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 64,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "İÜC Asistan",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Versiyon 1.0.0",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "İstanbul Üniversitesi-Cerrahpaşa öğrencileri için geliştirilmiş; "
                    "ders programı takibi, not hesaplama ve akademik takvim görüntüleme gibi işlemleri kolaylaştıran "
                    "açık kaynaklı bir yardımcı uygulamadır.",
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: () {
                  showLicensePage(
                    context: context,
                    applicationName: "İÜC Asistan",
                    applicationVersion: "1.0.0",
                    applicationIcon: const Icon(Icons.school_rounded),
                  );
                },
                icon: const Icon(Icons.description_outlined),
                label: const Text("Lisanslar"),
              ),
              const Spacer(),
              Text(
                "Akademik hayatınızda yardımcı olması dileğiyle\nFlutter kullanılarak geliştirildi.",
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}