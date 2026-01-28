// import 'package:another_flushbar/flushbar.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../models/Expense Model.dart';
import 'Controllers.dart';

class Shifter {
  dynamic route; // can be enum or String
  String? title;

  Shifter({this.route, this.title});
}

double height = Get.height;
double width = Get.width;
final navigatorKey = GlobalKey<NavigatorState>();
String checkTimeline(TimeOfDay t) => t.hour < 12 ? 'AM' : 'PM';
String monthName(DateTime d) => DateFormat.MMMM().format(d);
String monthDate(DateTime d) => DateFormat.d().format(d);
String monthDateName(DateTime d) => DateFormat('MMMM d').format(d);
String formatDate(DateTime d, {type = 'dd/MM/yyyy'}) => DateFormat(type).format(d);
String formatTime(DateTime d, {type = 'hh:mm a'}) => DateFormat(type).format(d);
DateTime dayKey(DateTime d) => DateUtils.dateOnly(d);
String formatCardNo(String s) {
  final d = s.replaceAll(RegExp(r'[^0-9]'), '');
  return List.generate((d.length / 4).ceil(), (i) {
    final start = i * 4;
    final end = (start + 4 > d.length) ? d.length : start + 4;
    return d.substring(start, end);
  }).join(' ');
}
String money(double v) {
  final n = v.round();
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final pos = s.length - i;
    buf.write(s[i]);
    if (pos > 1 && pos % 3 == 1) buf.write(',');
  }
  return '\$$buf';
}

String money2(double v) {
  final x = v.isNaN ? 0.0 : v;
  return "\$${x.toStringAsFixed(2)}";
}

String diffHoursMinutesDT(DateTime start, DateTime end, {int breakMin = 0}) {
  // cross-midnight (end next day)
  if (end.isBefore(start)) end = end.add(const Duration(days: 1));

  var mins = end.difference(start).inMinutes - breakMin;
  if (mins < 0) mins = 0;

  final h = mins ~/ 60;
  final m = mins % 60;
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

void showSnackBar(String? title, String? subtitle, {Duration duration = const Duration(seconds: 2)}) {
  Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    title: title,
    message: subtitle,
    backgroundColor: title!.contains("Error") || title.contains("Oops") ? ProjectColors.errorColor : ProjectColors.greenColor,
    duration: duration,
    borderRadius: BorderRadius.circular(20),
    maxWidth: width * 0.9,
  ).show(navigatorKey.currentContext!);
}

void callPopup(body) {
  showModalBottomSheet(
    context: navigatorKey.currentContext!,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => body,
  );
}

enum ButtonState {
  init,
  loading,
  done,
}

double? toDouble(String? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return double.tryParse(s.replaceAll(',', ''));
}

// double sumWhere(bool Function(ExpenseItem e) test) {
//   return expense.expenses // optional
//       .where(test)
//       .fold(0.0, (s, e) => s + e.amount);
// }



class ProjectColors {
  static const blackColor = Color(0xff1c1b1b);
  static const pureBlackColor = Colors.black;
  static const errorColor = Color(0xffff3737);
  static const brownColor = Color(0xffefe5d7);
  static const greenColor = Color(0xFF26CB26);
  static const lightGreenColor = Color(0xff36ff16);
  static const yellowColor = Color(0xfffffb16);
  static const purpleColor = Color(0xff662d61);
  static const whiteColor = Colors.white;

  // ✅ NEW (palette inspired by your screenshot)
  static const loginTop = Color(0xFF0E1A2B); // deep navy
  static const loginMid = Color(0xFF0A1220); // darker navy
  static const loginBottom = Color(0xFF070A12); // near-black
  static const loginAccentBlue = Color(0xFF3E5BFF); // button blue
  static const glassFill = Color(0x1AFFFFFF); // white @ 10%
  static const glassStroke = Color(0x26FFFFFF); // white @ 15%
  static const hintWhite = Color(0x99FFFFFF); // white @ 60%
  static const navyTop = Color(0xFF24344D); // top glow
  static const navyMid = Color(0xFF111722); // mid
  static const navyBottom = Color(0xFF07080A); // bottom
  static const accentBlue = Color(0xFF3F5F8E);
  static const backgroundColor = Color(0xff1c1c1c); // 15% white
  static const softText = Color(0xB3FFFFFF);
}

// class Methods {
//   static const loginUser = 'v1/user/login';
//   static const logoutUser = 'v1/user/logout';
//   static const emailVerify = 'v1/user/emailVerify';
//   static const resendVerificationCode = '/v1/user/resendVerificationCode';
//   static const signUpUser = 'v1/user/signUp';
//   static const categories = 'v1/user/getAllCategories?skip=0&limit=10';
//   static const subCategory = 'v1/user/getAllSubCategories?categoryId=';
//   static const products = 'v1/user/designs?subCategoryId=';
//   static const getProfile = 'v1/user/profile';
//   static const createAddress = 'v1/user/deliveryAddress';
//   static const address = 'v1/user/deliveryAddress';
//   static const updateAddress = 'v1/user/deliveryAddress';
//   static const updateProfile = 'v1/user/updateProfile';
//   static const designStatus = 'v1/user/designs';
//   static const cart = 'v1/user/getCart';
//   static const addToCart = 'v1/user/addToCart';
//   static const removeFromCart = 'v1/user/removeFromCart';
//   static const createOrder = 'v1/user/createOrder';
//   static const size = 'v1/user/size';
//   static const favorite = 'v1/user/getAllFavDesigns';
//   static const getOrders = 'v1/user/getOrders';
//   static const returnOrder = 'v1/user/returnOrder';
//   static const cancelOrder = 'v1/user/cancelOrder';
//   static const setFavorite = 'v1/user/favUnfavDesigns';
//   static const updatePassword = 'v1/user/updatePassword';
//   static const forgotPassword = 'v1/user/forgotPassword';
//   static const resetPassword = 'v1/user/resetPassword';
//   static const addAppReview = 'v1/user/addAppReview';
//   static const saveTransaction = 'v1/user/saveTransaction';
//   static const uploadImage = 'v1/upload';
// }
//
// class Params {
//   static const email = "email";
//   static const password = "password";
//   static const fcmToken = "fcmToken";
//   static const firstName = "firstName";
//   static const id = "_id";
//   static const otp = "otp";
//   static const lastName = "lastName";
//   static const countryCode = "countryCode";
//   static const mobileNumber = "mobileNumber";
//   static const dateOfBirth = 'dateOfBirth';
//   static const profileImage = 'profileImage';
//   static const pinCode = 'pinCode';
//   static const city = "city";
//   static const state = "state";
//   static const area = "area";
//   static const landmark = "landmark";
//   static const streetAddress = "streetAddress";
//   static const isDefault = "isDefault";
//   static const deliveryAddressId = "deliveryAddressId";
//   static const latitude = 'latitude';
//   static const longitude = 'longitude';
//   static const shoulderSize = "shoulderSize";
//   static const bustSize = "bustSize";
//   static const waistSize = "waistSize";
//   static const hipSize = "hipSize";
//   static const thighSize = "thighSize";
//   static const hipToToeSize = "hipToToeSize";
//   static const upperGarmentSize = "upperGarmentSize";
//   static const lowerGarmentSize = "lowerGarmentSize";
//   static const weight = "bodyWeight";
//   static const topPreference = "topPreference";
//   static const bodyShape = "bodyShape";
//   static const height = "height";
//   static const product = "product";
//   static const designId = "designId";
//   static const status = "status";
//   static const cartId = "cartId";
//   static const designerId = "designerId";
//   static const price = "price";
//   static const size = "size";
//   static const designImages = "designImages";
//   static const images = "images";
//   static const colors = "colors";
//   static const colorCode = "colorCode";
//   static const colorName = "colorName";
//   static const oldPassword = 'oldPassword';
//   static const newPassword = 'newPassword';
//   static const currency = 'currency';
//   static const amount = 'amount';
//   static const notes = 'notes';
//   static const description = 'description';
//   static const receipt = 'receipt';
//   static const type = 'type';
//   static const transactionId = 'transactionId';
//   static const orderId = 'orderId';
//   static const returnReason = 'returnReason';
//   static const cancelReason = 'cancelReason';
//   static const productIds = 'productIds';
// }
//
// class DeliveryStatusCode {
//   static const pending = 0;
//   static const accepted = 1;
//   static const onTheWay = 2;
//   static const delivered = 3;
//   static const cancel = 4;
// }
//
// class ReturnStatusCode {
//   static const returnPlaced = 1;
//   static const packagePicked = 2;
//   static const received = 3;
//   static const refundInitiate = 4;
//   static const refunded = 5;
// }
//
// class CancelStatusCode {
//   static const CancelInitiated = 1;
//   static const refundInitiate = 2;
//   static const refunded = 3;
// }
//

Widget divider() {
  return Container(
    height: height * .0012,
    margin: EdgeInsets.symmetric(vertical: height * .006),
    color: ProjectColors.whiteColor.withOpacity(.06),
  );
}
Widget loader({animationType = LoadingAnimationWidget.staggeredDotsWave, size = .04}) {
  return Center(
    child: animationType(
      color: ProjectColors.whiteColor,
      size: height * size,
    ),
  );
}

//
// void popupLoader() {
//   Get.dialog(
//     WillPopScope(
//       onWillPop: () async {
//         return false;
//       },
//       child: AlertDialog(
//         content: Container(
//           height: height * .1,
//           decoration: BoxDecoration(
//             color: ProjectColors.whiteColor,
//             borderRadius: BorderRadius.circular(height * .02),
//           ),
//           alignment: Alignment.center,
//           child: loader(invertColor: false),
//         ),
//         insetPadding: EdgeInsets.symmetric(horizontal: width * .3),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//     ),
//   );
// }
//
Widget circularButton({
  double? btnRadius = .05,
  double? iconRadius = .05,
  VoidCallback? callback,
  bool? invertColor = false,
  String? image = '',
}) {
  return GestureDetector(
    onTap: callback,
    child: Container(
      height: height * btnRadius!,
      width: height * btnRadius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: invertColor! ? ProjectColors.whiteColor : ProjectColors.blackColor,
      ),
      alignment: Alignment.center,
      child: Image.asset(
        image!,
        height: height * (iconRadius! - .02),
        width: height * (iconRadius - .02),
        color: invertColor ? ProjectColors.blackColor : ProjectColors.whiteColor,
        fit: BoxFit.cover,
      ),
    ),
  );
}

//
// Widget squareButton({
//   String? title = "",
//   VoidCallback? callback,
//   double? cHeight = .05,
//   double? cWidth = .8,
//   bool? loading = false,
// }) {
//   return GestureDetector(
//     onTap: callback,
//     child: Container(
//       height: height * cHeight!,
//       width: width * cWidth!,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(height * .01),
//         color: ProjectColors.blackColor,
//       ),
//       alignment: Alignment.center,
//       child: loading!
//           ? loader(invertColor: true)
//           : textWidget(
//         text: title,
//         fontSize: .018,
//         fontWeight: FontWeight.w600,
//         color: ProjectColors.whiteColor,
//       ),
//     ),
//   );
// }
//
// Widget divider(){
//   return Container(
//     height: height * .001,
//     color: ProjectColors.pureBlackColor.withOpacity(0.3),
//   );
// }
//
Widget outLinedButton({
  String? title = "",
  VoidCallback? callback,
  double? cHeight = .045,
  double? fontSize = .018,
  double? cWidth = .8,
  bool? loading = false,
  Color? color = ProjectColors.pureBlackColor,
}) {
  return GestureDetector(
    onTap: callback,
    child: Container(
      height: height * cHeight!,
      width: width * cWidth!,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color!),
      ),
      alignment: Alignment.center,
      child: loading!
          ? loader()
          : textWidget(
              text: title,
              fontSize: fontSize,
              fontFamily: 'bestlineSans',
              color: color,
            ),
    ),
  );
}

//
Widget normalButton({
  String? title = "",
  bool? needIcon = false,
  bool? needIconText = false,
  bool? invertColors = false,
  VoidCallback? callback,
  double? cHeight = .05,
  double? fSize = .02,
  String? image = "",
  double? paddingWidth = .05,
  double? cWidth = 1.0,
  bool? loading = false,
  Color? bColor = ProjectColors.whiteColor,
  // ButtonState buttonState = ButtonState.init,
}) {
  bColor = bColor != ProjectColors.whiteColor
      ? bColor
      : invertColors! == false
          ? ProjectColors.pureBlackColor
          : ProjectColors.whiteColor;
  return GestureDetector(
    onTap: callback,
    child: Container(
      height: height * cHeight!,
      width: width * cWidth!,
      // padding: EdgeInsets.symmetric(horizontal: width * paddingWidth!),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height * .04),
        color: bColor,
      ),
      // alignment: Alignment.center,
      child: loading == true
          ? loader(size: .03)
          : needIcon == true
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/arrow.png',
                      fit: BoxFit.contain,
                      height: height * .025,
                      width: height * .025,
                      color: invertColors == false ? ProjectColors.whiteColor : ProjectColors.blackColor,
                    ),
                  ],
                )
              : needIconText == true
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          image!,
                          fit: BoxFit.contain,
                          height: height * .025,
                          width: height * .025,
                          color: invertColors == false ? ProjectColors.whiteColor : ProjectColors.blackColor,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: width * .03),
                          child: textWidget(
                            text: title!,
                            fontFamily: "poppins",
                            color: invertColors == false ? ProjectColors.whiteColor : ProjectColors.blackColor,
                            fontSize: fSize!,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        textWidget(
                          text: title!,
                          fontFamily: "poppins",
                          color: invertColors == false ? ProjectColors.whiteColor : ProjectColors.pureBlackColor,
                          fontSize: fSize!,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
    ),
  );
}

//
// Widget animatedButton({
//   double? cWidth = .25,
//   double? cHeight = .05,
//   String? title = "",
//   bool? needIcon = false,
//   bool? needIconText = true,
//   bool? visibleText = true,
//   bool? invertColors = false,
//   VoidCallback? callback,
//   ButtonState buttonState = ButtonState.init,
// }) {
//   return GestureDetector(
//     onTap: callback,
//     child: AnimatedContainer(
//       duration: const Duration(milliseconds: 500),
//       alignment: Alignment.center,
//       height: height * cHeight!,
//       width: buttonState == ButtonState.loading || buttonState == ButtonState.done ? width * .11 : width * cWidth!,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(height * .06),
//         color: buttonState == ButtonState.done
//             ? ProjectColors.greenColor
//             : invertColors! == false
//             ? ProjectColors.blackColor
//             : ProjectColors.whiteColor,
//       ),
//       child: buttonState == ButtonState.init
//           ? needIcon == true
//           ? Image.asset(
//         'assets/arrow.png',
//         fit: BoxFit.contain,
//         height: height * .025,
//         width: width * .1,
//         color: invertColors == false ? ProjectColors.whiteColor : ProjectColors.blackColor,
//       )
//           : needIconText == true
//           ? Visibility(
//         visible: visibleText!,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Padding(
//               padding: EdgeInsets.only(right: width * .02),
//               child: textWidget(
//                 text: title!,
//                 color: invertColors == false ? ProjectColors.whiteColor : ProjectColors.blackColor,
//                 fontSize: .02,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             Image.asset(
//               'assets/arrow.png',
//               fit: BoxFit.contain,
//               height: height * .025,
//               width: width * .04,
//               color: invertColors == false ? ProjectColors.whiteColor : ProjectColors.blackColor,
//             ),
//           ],
//         ),
//       )
//           : textWidget(
//         text: title!,
//         color: invertColors == false ? ProjectColors.whiteColor : ProjectColors.blackColor,
//         fontSize: .02,
//         fontWeight: FontWeight.w600,
//       )
//           : buttonState == ButtonState.loading
//           ? SizedBox(
//         height: height * .038,
//         width: width * .08,
//         child: CircularProgressIndicator(
//           color: ProjectColors.backgroundColor,
//           strokeWidth: height * .0015,
//         ),
//       )
//           : Icon(
//         Icons.done_all,
//         color: Colors.white,
//         size: height * .03,
//       ),
//     ),
//   );
// }
//
// Widget dividerButton({VoidCallback? callback, title}) {
//   return Padding(
//     padding: EdgeInsets.only(left: width * .2),
//     child: GestureDetector(
//       onTap: callback,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           textWidget(
//             text: title,
//             fontSize: .025,
//           ),
//           Divider(
//             thickness: height * .001,
//             color: ProjectColors.purpleColor,
//           ),
//         ],
//       ),
//     ),
//   );
// }
//
Widget textWidget({
  String? text,
  double? fontSize = .015,
  Color? color = ProjectColors.pureBlackColor,
  FontWeight? fontWeight = FontWeight.w400,
  bool? needContainer = false,
  double? cHeight,
  double? cWidth,
  TextAlign? textAlign,
  String? fontFamily = 'poppins',
  FontStyle? fontStyle = FontStyle.normal,
}) {
  return needContainer == false
      ? Text(
          text!,
          style: TextStyle(
            fontSize: height * fontSize!,
            color: color,
            fontFamily: fontFamily,
            fontStyle: fontStyle,
            fontWeight: fontWeight,
          ),
          textAlign: textAlign,
        )
      : Container(
          color: Colors.transparent,
          width: width * cWidth!,
          child: Text(
            text!,
            style: TextStyle(
              fontSize: height * fontSize!,
              color: color,
              fontFamily: fontFamily,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
            ),
            textAlign: textAlign,
          ),
        );
}
//
// Widget reloadData({VoidCallback? callback}) {
//   return Center(
//     child: Container(
//       width: width,
//       color: Colors.transparent,
//       margin: EdgeInsets.symmetric(horizontal: width * .05),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisAlignment: MainAxisAlignment.start,
//         // mainAxisSize: MainAxisSize.min,
//         children: [
//           textWidget(
//             text: "Oops! it looks like some error has occurred. Please try to reload again",
//             fontSize: .022,
//             fontWeight: FontWeight.w400,
//             textAlign: TextAlign.center,
//             color: ProjectColors.blackColor,
//           ),
//           SizedBox(height: height * .04),
//           GestureDetector(
//             onTap: callback,
//             child: Container(
//               height: height * .05,
//               width: width,
//               color: ProjectColors.blackColor,
//               alignment: Alignment.center,
//               child: textWidget(
//                 text: "Refresh",
//                 fontSize: .02,
//                 fontWeight: FontWeight.w600,
//                 color: ProjectColors.whiteColor,
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
//
// Widget loadImage({imgUrl, cHeight = .21, cWidth = .3, BorderRadius? borderRadius}) {
//   RxBool? loading = false.obs;
//   return Obx(() => loading == true
//       ? Container(
//     color: ProjectColors.backgroundColor,
//     height: height * cHeight,
//     width: width * cWidth,
//     child: Center(
//       child: Shimmer.fromColors(
//         baseColor: ProjectColors.blackColor,
//         highlightColor: ProjectColors.whiteColor,
//         child: Image.asset(
//           "assets/icon.png",
//           height: height * .05,
//           width: height * .05,
//           fit: BoxFit.cover,
//           color: ProjectColors.blackColor,
//         ),
//       ),
//     ),
//   )
//       : CachedNetworkImage(
//     imageUrl: imgUrl.toString(),
//     imageBuilder: (context, imageProvider) => Container(
//       height: height * cHeight,
//       width: width * cWidth,
//       decoration: BoxDecoration(
//         image: DecorationImage(
//           image: imageProvider,
//           fit: BoxFit.cover,
//         ),
//         borderRadius: borderRadius,
//         color: ProjectColors.whiteColor,
//       ),
//     ),
//     placeholder: (context, url) => Container(
//       decoration: BoxDecoration(
//         color: ProjectColors.whiteColor,
//       ),
//       height: height * cHeight,
//       width: width * cWidth,
//       child: Center(
//         child: Shimmer.fromColors(
//           baseColor: ProjectColors.blackColor,
//           highlightColor: ProjectColors.whiteColor,
//           child: Image.asset(
//             "assets/icon.png",
//             height: height * .05,
//             width: height * .05,
//             fit: BoxFit.cover,
//             color: ProjectColors.blackColor,
//           ),
//         ),
//       ),
//     ),
//     errorWidget: (context, url, error) => Container(
//       color: ProjectColors.backgroundColor,
//       height: height * cHeight,
//       width: width * cWidth,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           const Icon(Icons.error),
//           SizedBox(height: height * .01),
//           normalButton(
//               title: "Reload",
//               cWidth: .3,
//               callback: () {
//                 loading.value = true;
//                 Future.delayed(const Duration(milliseconds: 500), () {
//                   loading.value = false;
//                 });
//               }),
//         ],
//       ),
//     ),
//   ));
// }
//
// class LoadingAnimation extends GetxController with GetSingleTickerProviderStateMixin {
//   AnimationController? controller;
//   Animation? tween;
//
//   @override
//   void onInit() {
//     controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
//     tween = Tween(begin: 0.2, end: 1.0).animate(CurvedAnimation(parent: controller!, curve: Curves.easeInOut));
//     super.onInit();
//   }
//
//   Future refreshData() async {
//     controller!.stop();
//     controller!.reset();
//   }
//
//   void animateLoader({state = true}) {
//     if (state) {
//       controller!.repeat(reverse: true);
//     } else {
//       controller!.stop();
//     }
//   }
//
//   Widget showLoading() {
//     return AnimatedBuilder(
//         animation: tween!,
//         builder: (BuildContext context, _) {
//           return Opacity(
//             opacity: tween!.value,
//             child: Image.asset(
//               "assets/icon.png",
//               height: height * .08,
//               width: height * .08,
//               fit: BoxFit.contain,
//             ),
//           );
//         });
//   }
// }
