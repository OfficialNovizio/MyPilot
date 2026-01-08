import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';

import 'package:emptyproject/Working%20UI/Account/Account%20Getx.dart';
import 'package:emptyproject/Working%20UI/Constant%20UI.dart';
import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:emptyproject/models/TextForm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'Active Jobs.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0x66FFFFFF), // top highlight
                        Color(0x22FFFFFF), // mid
                        Color(0x11000000), // subtle dark edge
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: CircleAvatar(
                              radius: height * .03,
                            ),
                          ),
                          SizedBox(height: height * .01),
                          textWidget(
                            text: "Hello Siddharth !",
                            fontSize: .04,
                            color: ProjectColors.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textWidget(
                            text: "contact.novy1@gmail.com",
                            color: ProjectColors.whiteColor,
                          ),
                          SizedBox(height: height * .015),
                          Container(
                            height: height * .04,
                            width: width * .3,
                            decoration: BoxDecoration(
                              color: ProjectColors.greenColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: textWidget(
                              text: "Remove Account",
                              fontSize: .012,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: height * .02),
            AccountElements(
              title: 'Active Jobs',
              icon: Icons.work_outline_rounded,
              callback: () {
                Get.to(() => ActiveJobs());
              },
            ),
            AccountElements(
              title: 'Payment Accounts',
              icon: Icons.account_balance_outlined,
              callback: () {},
            ),
            AccountElements(
              title: 'Settings',
              icon: Icons.settings,
              callback: () {},
            ),
            AccountElements(
              title: 'Permissions',
              icon: Icons.perm_device_info_outlined,
              callback: () {},
            ),
            AccountElements(
              title: 'Privacy Policy',
              icon: Icons.policy_outlined,
              callback: () {},
            ),
            AccountElements(
              title: 'Logout',
              icon: Icons.logout_outlined,
              callback: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class AccountElements extends StatelessWidget {
  IconData? icon;
  String? title;
  VoidCallback? callback;

  AccountElements({this.icon, this.title, this.callback});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * .01),
      child: GestureDetector(
        onTap: callback,
        child: Row(
          children: [
            Container(
              width: height * .04,
              height: height * .04,
              decoration: BoxDecoration(
                color: ProjectColors.whiteColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ProjectColors.greenColor, size: height * .02),
            ),
            SizedBox(width: width * .02),
            textWidget(
              text: title,
              fontSize: .02,
              color: ProjectColors.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
    );
  }
}
