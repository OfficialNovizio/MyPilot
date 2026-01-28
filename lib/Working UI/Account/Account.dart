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
            Glass(
              body: Padding(
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
                        text: "Hello User !",
                        fontSize: .04,
                        color: ProjectColors.whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textWidget(
                        text: "xyz.@gmail.com",
                        color: ProjectColors.whiteColor,
                      ),
                      SizedBox(height: height * .015),
                      normalButton(
                        title: 'Remove Account',
                        callback: () {},
                        cWidth: .35,
                        fSize: .015,
                        bColor: ProjectColors.greenColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: height * .04),
            ...account.columns!
                .map(
                  (t) => Padding(
                    padding: EdgeInsets.symmetric(vertical: height * .01),
                    child: GestureDetector(
                      onTap: () {
                        account.changeScreen(t['title']);
                      },
                      child: Row(
                        children: [
                          DarkCard(child: Icon(t['icon'], color: ProjectColors.greenColor, size: height * .025)),
                          SizedBox(width: width * .02),
                          textWidget(
                            text: t['title'],
                            fontSize: .025,
                            color: ProjectColors.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }
}
