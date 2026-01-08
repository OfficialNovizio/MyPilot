import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:onboarding/onboarding.dart';

import '../Constants.dart';
import '../Shared Preferences.dart';
import 'Login User.dart';

enum _OnIconType { tasks, shifts, expenses, debt }

class AppOnboardingScreen extends StatefulWidget {
  const AppOnboardingScreen({super.key, this.onDone});

  /// Use this if you want to decide where onboarding ends (Login/Home).
  final VoidCallback? onDone;

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen> {
  final _pages = <Map<String, dynamic>>[
    {
      "title": "Create prioritizer tasks",
      "subtitle": "Sort your day into Must-do, At-risk, If-time and Done automatically.",
      "icon": _OnIconType.tasks,
    },
    {
      "title": "Manage shifts",
      "subtitle": "Track hours, pay, and patterns so you always know what’s coming.",
      "icon": _OnIconType.shifts,
    },
    {
      "title": "Manage expenses with insights",
      "subtitle": "See where money leaks, what’s essential, and what actually changed this month.",
      "icon": _OnIconType.expenses,
    },
    {
      "title": "Manage debt with a better strategy",
      "subtitle": "Pay with intent: reduce interest faster, target utilization, and see the impact before you pay.",
      "icon": _OnIconType.debt,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final pagesLength = _pages.length;

    final activePainter = Paint()
      ..color = ProjectColors.whiteColor
      ..strokeWidth = height * 0.004
      ..strokeCap = StrokeCap.round;

    final inactivePainter = Paint()
      ..color = ProjectColors.whiteColor.withOpacity(0.25)
      ..strokeWidth = height * 0.003
      ..strokeCap = StrokeCap.round;

    return Scaffold(
      backgroundColor: ProjectColors.pureBlackColor,
      extendBodyBehindAppBar: true,
      body: Onboarding(
        startIndex: 0,
        animationInMilliseconds: 300,
        swipeableBody: List.generate(
          pagesLength,
          (i) => _OnboardPage(
            title: _pages[i]["title"],
            subtitle: _pages[i]["subtitle"],
            iconType: _pages[i]["icon"],
          ),
        ),

        // Footer: indicator left, next button right
        buildFooter: (context, dragPercent, pagesLen, currentIndex, setIndex, slideDirection) {
          final isLast = currentIndex == pagesLen - 1;

          void goNext() {
            if (isLast) {
              if (widget.onDone != null) {
                widget.onDone!.call();
                return;
              } else {
                Get.off(() => LoginScreen());
                saveLocalData('Onboarding', 'Completed');
              }
              Get.back();
              return;
            }
            setIndex(currentIndex + 1);
          }

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(width * 0.06, 0, width * 0.06, height * 0.035),
              child: Row(
                children: [
                  ...List.generate(
                      _pages.length,
                      (a) => Padding(
                            padding: EdgeInsets.only(right: width * .01),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              height: height * .005,
                              width: currentIndex == a ? width * .15 : width * .02,
                              decoration: BoxDecoration(
                                color: currentIndex == a ? ProjectColors.greenColor : ProjectColors.whiteColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          )).toList(),
                  Spacer(),
                  GestureDetector(
                    onTap: goNext,
                    child: Container(
                      height: height * 0.07,
                      width: isLast ? width * 0.34 : height * 0.07,
                      decoration: BoxDecoration(
                        color: ProjectColors.greenColor, // NEW constant
                        borderRadius: BorderRadius.circular(isLast ? height * 0.06 : 999),
                      ),
                      alignment: Alignment.center,
                      child: isLast
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                textWidget(
                                  text: "Get started",
                                  fontSize: 0.018,
                                  color: ProjectColors.whiteColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                SizedBox(width: width * 0.02),
                                Icon(MaterialCommunityIcons.arrow_top_right, color: ProjectColors.whiteColor.withOpacity(0.8), size: height * 0.028),
                              ],
                            )
                          : Icon(MaterialCommunityIcons.arrow_top_right, color: ProjectColors.whiteColor.withOpacity(0.8), size: height * 0.035),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.iconType,
  });

  final String title;
  final String subtitle;
  final _OnIconType iconType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
          image: DecorationImage(
        image: AssetImage('Assets/Images/onboarding.png'),
        fit: BoxFit.fitWidth,
      )),
      child: Stack(
        children: [
          Positioned(
            left: width * .06,
            right: width * .1,
            bottom: height * .1, // keep room for footer
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textWidget(
                  text: title.toUpperCase(),
                  fontSize: 0.055,
                  fontFamily: 'helsinki', // same vibe as your other UI
                  color: ProjectColors.whiteColor,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: height * 0.014),
                textWidget(
                  text: subtitle,
                  fontSize: 0.018,
                  color: ProjectColors.softText, // NEW constant
                  fontWeight: FontWeight.w400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
