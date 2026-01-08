import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import '../Constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProjectColors.pureBlackColor,
      body: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ProjectColors.loginTop,
              ProjectColors.pureBlackColor,
              ProjectColors.pureBlackColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: width * .07),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // top subtle line icons vibe (simple grid strokes)
                _BlueprintGrid(),

                textWidget(
                  text: "Welcome Back",
                  fontFamily: "bestlineSans",
                  fontSize: .04,
                  color: ProjectColors.whiteColor,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: height * .01),
                textWidget(
                  text: "Log in to get back on track with your daily tasks.",
                  fontSize: .017,
                  color: ProjectColors.hintWhite,
                  fontWeight: FontWeight.w400,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: height * .05),

                _GlassCard(
                  child: Column(
                    children: [
                      _AuthField(
                        controller: login.email,
                        hint: "Email",
                        prefix: Icons.mail_outline_rounded,
                        textInputType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: height * .018),
                      Obx(
                        () => _AuthField(
                          controller: login.password,
                          hint: "Password",
                          prefix: Icons.lock_outline_rounded,
                          obscureText: login.obscure.value,
                          suffix: GestureDetector(
                            onTap: () => login.obscure.value = !login.obscure.value,
                            child: Icon(
                              login.obscure.value ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: ProjectColors.hintWhite,
                              size: height * .024,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: height * .012),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: login.onForgot,
                          child: Padding(
                            padding: EdgeInsets.only(top: height * .006),
                            child: textWidget(
                              text: "Forgot password?",
                              fontSize: .015,
                              color: ProjectColors.loginAccentBlue.withOpacity(.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: height * .025),

                      // Primary login button (uses your normalButton)
                      Obx(
                        () => normalButton(
                          title: "Log In",
                          cWidth: 1.0,
                          cHeight: .06,
                          fSize: .02,
                          bColor: ProjectColors.greenColor,
                          loading: login.isLoading.value,
                          callback: login.isLoading.value ? null : login.onLogin,
                        ),
                      ),

                      SizedBox(height: height * .03),
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: ProjectColors.glassStroke)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: width * .04),
                            child: textWidget(
                              text: "Or",
                              fontSize: .016,
                              color: ProjectColors.hintWhite,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: ProjectColors.glassStroke)),
                        ],
                      ),
                      SizedBox(height: height * .02),

                      // Social buttons (clean + matching palette)
                      _SocialButton(
                        label: "Continue with Apple",
                        icon: Icons.apple,
                        onTap: login.onApple,
                        bg: const Color(0xFF0B0E14),
                      ),
                      SizedBox(height: height * .015),
                      _SocialButton(
                        label: "Continue with Google",
                        icon: MaterialCommunityIcons.gmail, // placeholder look
                        onTap: login.onGoogle,
                        bg: const Color(0xFF0B0E14),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: height * .03),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    textWidget(
                      text: "Don’t have an account? ",
                      fontSize: .016,
                      color: ProjectColors.hintWhite,
                      fontWeight: FontWeight.w400,
                    ),
                    GestureDetector(
                      onTap: login.onSignUp,
                      child: textWidget(
                        text: "Sign Up",
                        fontSize: .016,
                        color: ProjectColors.loginAccentBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: height * .05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------- UI PARTS ----------------------------------------

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: width * .05, vertical: height * .03),
      decoration: BoxDecoration(
        color: ProjectColors.glassFill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ProjectColors.glassStroke),
      ),
      child: child,
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefix;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? textInputType;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.prefix,
    this.obscureText = false,
    this.suffix,
    this.textInputType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height * .062,
      decoration: BoxDecoration(
        color: const Color(0x12000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProjectColors.glassStroke),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: textInputType,
        style: TextStyle(
          color: ProjectColors.whiteColor,
          fontFamily: "poppins",
          fontSize: height * .018,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: ProjectColors.loginAccentBlue,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: width * .04, vertical: height * .017),
          hintText: hint,
          hintStyle: TextStyle(
            color: ProjectColors.hintWhite,
            fontFamily: "poppins",
            fontSize: height * .017,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(prefix, color: ProjectColors.hintWhite, size: height * .024),
          suffixIcon: suffix == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(right: width * .03),
                  child: suffix,
                ),
          suffixIconConstraints: BoxConstraints(minHeight: height * .03, minWidth: height * .03),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height * .058,
        width: width,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ProjectColors.glassStroke),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ProjectColors.whiteColor, size: height * .028),
            SizedBox(width: width * .03),
            textWidget(
              text: label,
              fontSize: .018,
              color: ProjectColors.whiteColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlueprintGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height * .16,
      width: width,
      child: CustomPaint(
        painter: _GridPainter(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;

    // grid
    const cols = 6;
    const rows = 3;
    for (int i = 1; i < cols; i++) {
      final x = size.width * (i / cols);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int j = 1; j < rows; j++) {
      final y = size.height * (j / rows);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // tiny sketch icons vibe (simple strokes)
    final iconPaint = Paint()
      ..color = const Color(0x2BFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // clock
    final clockC = Offset(size.width * .42, size.height * .5);
    canvas.drawCircle(clockC, size.height * .16, iconPaint);
    canvas.drawLine(clockC, Offset(clockC.dx, clockC.dy - size.height * .08), iconPaint);
    canvas.drawLine(clockC, Offset(clockC.dx + size.width * .03, clockC.dy), iconPaint);

    // target
    final tC = Offset(size.width * .72, size.height * .5);
    canvas.drawCircle(tC, size.height * .15, iconPaint);
    canvas.drawCircle(tC, size.height * .10, iconPaint);
    canvas.drawCircle(tC, size.height * .05, iconPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
