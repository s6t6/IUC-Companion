import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/onboarding_viewmodel.dart';
import '../../../../data/models/faculty.dart';
import '../../../../data/models/department.dart';

class ProfileStep extends StatelessWidget {
  const ProfileStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<OnboardingViewModel>(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Devam etmek için profil bilgilerinizi girin.",
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 20),

        if (viewModel.errorMessage != null)
          _buildErrorBox(context, viewModel.errorMessage!),

        TextFormField(
          decoration: const InputDecoration(
            labelText: "Profil İsmi",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
            hintText: "Profilinize bir isim verin",
          ),
          initialValue: viewModel.profileName,
          onChanged: viewModel.setProfileName,
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<Faculty>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "Fakülte",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.school),
          ),
          value: viewModel.selectedFaculty,
          items: viewModel.faculties.map((Faculty faculty) {
            return DropdownMenuItem<Faculty>(
              value: faculty,
              child: Text(faculty.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: viewModel.isLoading ? null : viewModel.selectFaculty,
          hint: const Text("Fakülte Seçiniz"),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<Department>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "Bölüm",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.class_),
          ),
          value: viewModel.selectedDepartment,
          items: viewModel.departments.map((Department dept) {
            return DropdownMenuItem<Department>(
              value: dept,
              child: Text(dept.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: viewModel.selectDepartment,
          hint: const Text("Bölüm Seçiniz"),
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