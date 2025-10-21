import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: ProjectColors.blackColor,
        body: SafeArea(child: home.currentScreen!.value),
        bottomNavigationBar: Container(
          height: height * .07,
          decoration: BoxDecoration(color: ProjectColors.blackColor),
          padding: EdgeInsets.only(bottom: height * .01),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: home.bottomIcons
                .map(
                  (d) => GestureDetector(
                    onTap: () {
                      home.changeCurrentScreen(d['Route']);
                      home.bottomIcons.refresh();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        textWidget(
                          text: d['Title'],
                          fontSize: .018,
                          fontWeight: FontWeight.bold,
                          color: ProjectColors.whiteColor,
                        ),
                        SizedBox(height: height * .005),
                        Visibility(
                          visible: d['Title'] == home.activeIcon!.value ? true : false,
                          child: Container(
                            color: ProjectColors.greenColor,
                            height: height * .001,
                            width: width * .08,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
