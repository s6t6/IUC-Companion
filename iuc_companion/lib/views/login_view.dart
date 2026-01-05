import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final emailController = TextEditingController(text: "kubilay@ogr.iu.edu.tr");

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: AppColors.gold),
              const SizedBox(height: 20),
              const Text("COMPANION", style: TextStyle(color: AppColors.gold, fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 60),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email, color: AppColors.gold),
                  filled: true,
                  fillColor: AppColors.surface,
                  hintText: "E-Posta",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: AppColors.gold),
                  filled: true,
                  fillColor: AppColors.surface,
                  hintText: "Şifre (123456)",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authViewModel.isLoading ? null : () {
                    authViewModel.login(emailController.text, "123456");
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
                  child: authViewModel.isLoading 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Text("GİRİŞ YAP", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}