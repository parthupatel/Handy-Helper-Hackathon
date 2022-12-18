import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_detail_model.dart';
import 'package:booking_system_flutter/model/dashboard_model.dart';
import 'package:booking_system_flutter/screens/booking/component/price_common_widget.dart';
import 'package:booking_system_flutter/services/flutter_wave_services.dart';
import 'package:booking_system_flutter/services/razor_pay_services.dart';
import 'package:booking_system_flutter/services/stripe_services.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class PaymentScreen extends StatefulWidget {
  final BookingDetailResponse bookings;

  PaymentScreen({required this.bookings});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<PaymentSetting> paymentList = [];

  PaymentSetting? currentPaymentMethod;

  num totalAmount = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    paymentList = PaymentSetting.decode(getStringAsync(PAYMENT_LIST));

    currentPaymentMethod = paymentList.first;

    if (widget.bookings.bookingDetail!.isHourlyService.validate()) {
      totalAmount = getHourlyPrice(
        price: widget.bookings.bookingDetail!.totalAmount!.toInt(),
        secTime: widget.bookings.bookingDetail!.durationDiff.toInt(),
        date: widget.bookings.bookingDetail!.date.validate(),
      );

      log("Hourly Total Amount $totalAmount");
    } else {
      totalAmount = calculateTotalAmount(
        serviceDiscountPercent: widget.bookings.service!.discount.validate(),
        qty: widget.bookings.bookingDetail!.quantity!.toInt(),
        detail: widget.bookings.service,
        servicePrice: widget.bookings.bookingDetail!.amount.validate(),
        taxes: widget.bookings.bookingDetail!.taxes.validate(),
        couponData: widget.bookings.couponData,
        extraCharges: widget.bookings.bookingDetail!.extraCharges,
      );
      log("Fixed Total Amount $totalAmount");
    }
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _handleClick() async {
    if (currentPaymentMethod!.type == PAYMENT_METHOD_COD) {
      savePay(data: widget.bookings, paymentMethod: PAYMENT_METHOD_COD, totalAmount: totalAmount);
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_STRIPE) {
      if (currentPaymentMethod!.isTest == 1) {
        appStore.setLoading(true);

        await stripeServices.init(
          stripePaymentPublishKey: currentPaymentMethod!.testValue!.stripePublickey.validate(),
          data: widget.bookings,
          totalAmount: totalAmount,
          stripeURL: currentPaymentMethod!.testValue!.stripeUrl.validate(),
          stripePaymentKey: currentPaymentMethod!.testValue!.stripeKey.validate(),
          isTest: true,
        );
        await 1.seconds.delay;
        stripeServices.stripePay();
      } else {
        appStore.setLoading(true);

        await stripeServices.init(
          stripePaymentPublishKey: currentPaymentMethod!.liveValue!.stripePublickey.validate(),
          data: widget.bookings,
          totalAmount: totalAmount,
          stripeURL: currentPaymentMethod!.liveValue!.stripeUrl.validate(),
          stripePaymentKey: currentPaymentMethod!.liveValue!.stripeKey.validate(),
          isTest: false,
        );
        await 1.seconds.delay;
        stripeServices.stripePay();
      }
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_RAZOR) {
      if (currentPaymentMethod!.isTest == 1) {
        appStore.setLoading(true);
        RazorPayServices.init(razorKey: currentPaymentMethod!.testValue!.razorKey!, data: widget.bookings);
        await 1.seconds.delay;
        appStore.setLoading(false);
        RazorPayServices.razorPayCheckout(totalAmount);
      } else {
        appStore.setLoading(true);
        RazorPayServices.init(razorKey: currentPaymentMethod!.liveValue!.razorKey!, data: widget.bookings);
        await 1.seconds.delay;
        appStore.setLoading(false);
        RazorPayServices.razorPayCheckout(totalAmount);
      }
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_FLUTTER_WAVE) {
      if (currentPaymentMethod!.isTest == 1) {
        appStore.setLoading(true);

        FlutterWaveServices().payWithFlutterWave(
          bookDetailData: widget.bookings,
          totalAmount: totalAmount,
          flutterWavePublicKey: currentPaymentMethod!.testValue!.flutterwavePublic.validate(),
          flutterWaveSecretKey: currentPaymentMethod!.testValue!.flutterwaveSecret.validate(),
          isTestMode: true,
        );
      } else {
        appStore.setLoading(true);

        FlutterWaveServices().payWithFlutterWave(
          bookDetailData: widget.bookings,
          totalAmount: totalAmount,
          flutterWavePublicKey: currentPaymentMethod!.liveValue!.flutterwavePublic.validate(),
          flutterWaveSecretKey: currentPaymentMethod!.liveValue!.flutterwaveSecret.validate(),
          isTestMode: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(language.payment, color: context.primaryColor, textColor: Colors.white, backWidget: BackWidget()),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PriceCommonWidget(
                      bookingDetail: widget.bookings.bookingDetail!,
                      serviceDetail: widget.bookings.service!,
                      taxes: widget.bookings.bookingDetail!.taxes.validate(),
                      couponData: widget.bookings.couponData,
                    ),
                    32.height,
                    Text(language.lblChoosePaymentMethod, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                  ],
                ).paddingAll(16),
                if (paymentList.isNotEmpty)
                  ListView.builder(
                    itemCount: paymentList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      PaymentSetting value = paymentList[index];
                      return RadioListTile<PaymentSetting>(
                        dense: true,
                        activeColor: primaryColor,
                        value: value,
                        controlAffinity: ListTileControlAffinity.trailing,
                        groupValue: currentPaymentMethod,
                        onChanged: (PaymentSetting? ind) {
                          currentPaymentMethod = ind;
                          setState(() {});
                        },
                        title: Text(value.title.validate(), style: primaryTextStyle()),
                      );
                    },
                  )
                else
                  Column(
                    children: [
                      24.height,
                      Image.asset(notDataFoundImg, height: 150),
                      16.height,
                      Text(language.lblNoPayments, style: boldTextStyle()).center(),
                    ],
                  ),
                if (paymentList.isNotEmpty)
                  AppButton(
                    onTap: () {
                      if (currentPaymentMethod!.type == PAYMENT_METHOD_COD) {
                        showConfirmDialogCustom(
                          context,
                          dialogType: DialogType.CONFIRMATION,
                          title: "${language.lblPayWith} ${currentPaymentMethod!.title.validate()}",
                          primaryColor: primaryColor,
                          positiveText: language.lblYes,
                          negativeText: language.lblCancel,
                          onAccept: (p0) {
                            _handleClick();
                          },
                        );
                      } else {
                        _handleClick();
                      }
                    },
                    text: "${language.payWith} ${currentPaymentMethod!.title.validate()}",
                    color: context.primaryColor,
                    width: context.width(),
                  ).paddingAll(16),
              ],
            ),
          ),
          Observer(builder: (context) => LoaderWidget().visible(appStore.isLoading)).center()
        ],
      ),
    );
  }
}
