import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BaseScreen extends StatelessWidget {
  Widget? body;
  String? title;
  BaseScreen({this.body, this.title = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProjectColors.pureBlackColor,
      appBar: AppBar(
        backgroundColor: ProjectColors.pureBlackColor,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Center(
            child: Container(
              height: height * .045,
              width: height * .045,
              decoration: BoxDecoration(
                color: ProjectColors.whiteColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ProjectColors.blackColor.withOpacity(.06),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.chevron_left_rounded, color: ProjectColors.blackColor, size: height * .03),
            ),
          ),
        ),
        centerTitle: true,
        title: textWidget(
          text: title,
          fontSize: .03,
          fontWeight: FontWeight.bold,
          color: ProjectColors.whiteColor,
        ),
      ),
      body: SafeArea(
          child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * .02),
        child: body!,
      )),
    );
  }
}
