import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Controllers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShiftBody extends StatefulWidget {
  const ShiftBody({super.key});
  @override
  State<ShiftBody> createState() => _ShiftBodyState();
}

class _ShiftBodyState extends State<ShiftBody> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        child: ColoredBox(
          color: ProjectColors.pureBlackColor,
          child: SizedBox(
            width: width,
            height: height,
            child: SingleChildScrollView(
              child: Column(children: [
                SizedBox(height: height * .02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: shift.shiftStats
                      .map(
                        (f) => GestureDetector(
                          onTap: () {
                            shift.changeShiftTabs(f["Route"]);
                            shift.activeShift!.refresh();
                          },
                          child: Container(
                            height: height * .02,
                            width: width * .18,
                            decoration: BoxDecoration(
                              color: f['Title'] == shift.activeShift!.value ? ProjectColors.greenColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: textWidget(
                              text: f['Title'],
                              fontSize: .015,
                              color: f['Title'] == shift.activeShift!.value ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                shift.shiftScreen!.value
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
