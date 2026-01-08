import 'package:emptyproject/Working%20UI/Dashboard/Dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Constants.dart';

class LoginGetx extends GetxController {
  final email = TextEditingController();
  final password = TextEditingController();

  final isLoading = false.obs;
  final obscure = true.obs;

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }

  bool _isValidEmail(String v) {
    final s = v.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
  }

  Future<void> onLogin() async {
    Get.off(() => DashboardScreen());
    // final e = email.text.trim();
    // final p = password.text;
    //
    // if (!_isValidEmail(e)) {
    //   showSnackBar("Oops", "Enter a valid email.");
    //   return;
    // }
    // if (p.trim().length < 6) {
    //   showSnackBar("Oops", "Password must be at least 6 characters.");
    //   return;
    // }
    //
    // isLoading.value = true;
    // try {
    //   // TODO: Replace with your auth call
    //   await Future.delayed(const Duration(milliseconds: 900));
    //   showSnackBar("Done", "Logged in successfully.");
    // } catch (err) {
    //   showSnackBar("Error", "Login failed. Try again.");
    // } finally {
    //   isLoading.value = false;
    // }
  }

  void onApple() {
    // TODO: integrate sign_in_with_apple
    showSnackBar("Info", "Apple login tapped.");
  }

  void onGoogle() {
    // TODO: integrate google_sign_in
    showSnackBar("Info", "Google login tapped.");
  }

  void onForgot() {
    showSnackBar("Info", "Forgot password tapped.");
  }

  void onSignUp() {
    showSnackBar("Info", "Sign up tapped.");
  }
}
