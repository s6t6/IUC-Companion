import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/theme_viewmodel.dart';
import '../../../viewmodels/simulation_viewmodel.dart';

class AcademicSummaryCard extends StatelessWidget {
  const AcademicSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final simulationViewModel = Provider.of<SimulationViewModel>(context);

    return Row(
      children: [
        Expanded(child: _buildStatusCard(
            context,
            icon: Icons.school,
            label: "Ortalama",
            value: simulationViewModel.isLoading
                ? "..."
                : simulationViewModel.realGPA.toStringAsFixed(2),
            iconColor: Colors.orange
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatusCard(
            context,
            icon: Icons.check_circle,
            label: "Kredi",
            value: simulationViewModel.isLoading
                ? "..."
                : "${simulationViewModel.realTotalCredits} Tamamlandı",
            iconColor: Colors.blue
        )),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = theme.extension<SemanticColors>();

    final actualIconColor = label == "Ortalama"
        ? (semantics?.warning ?? iconColor)
        : (semantics?.info ?? iconColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: actualIconColor, size: 20),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500
              )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              )
          ),
        ],
      ),
    );
  }
}