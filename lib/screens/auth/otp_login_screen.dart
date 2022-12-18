import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';

class OTPLoginScreen extends StatefulWidget {
  const OTPLoginScreen({Key? key}) : super(key: key);

  @override
  State<OTPLoginScreen> createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController numberController = TextEditingController();

  String countryCode = '';

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() => init());
  }

  Future<void> init() async {
    appStore.setLoading(false);
  }

  //region Methods
  Future<void> sendOTP() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      hideKeyboard(context);

      appStore.setLoading(true);

      toast('Sending OTP');

      await authService.loginWithOTP(context, phoneNumber: numberController.text.trim(), countryCode: countryCode).then((value) {
        //
      }).catchError(
        (e) {
          appStore.setLoading(false);

          toast(e.toString(), print: true);
        },
      );
    }
  }

  // endregion

  Widget _buildMainWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(language.lblEnterPhnNumber, style: boldTextStyle()),
        16.height,
        Container(
          child: Row(
            children: [
              CountryCodePicker(
                initialSelection: '+91',
                showCountryOnly: false,
                showFlag: true,
                showFlagDialog: true,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
                dialogBackgroundColor: context.cardColor,
                textStyle: primaryTextStyle(size: 18),
                onInit: (c) {
                  countryCode = c!.dialCode.validate();
                },
                onChanged: (c) {
                  countryCode = c.dialCode.validate();
                },
              ),
              2.width,
              Form(
                key: formKey,
                child: AppTextField(
                  controller: numberController,
                  textFieldType: TextFieldType.PHONE,
                  decoration: inputDecoration(context),
                  autoFocus: true,
                  onFieldSubmitted: (s) {
                    sendOTP();
                  },
                ).expand(),
              ),
            ],
          ),
        ),
        30.height,
        AppButton(
          onTap: () {
            sendOTP();
          },
          text: language.btnSendOtp,
          color: primaryColor,
          textStyle: boldTextStyle(color: white),
          width: context.width(),
        )
      ],
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.scaffoldBackgroundColor,
        leading: Navigator.of(context).canPop() ? BackWidget(iconColor: context.iconColor) : null,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(statusBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark, statusBarColor: context.scaffoldBackgroundColor),
      ),
      body: Body(
        child: Container(
          padding: EdgeInsets.all(16),
          child: _buildMainWidget(),
        ),
      ),
    );
  }
}
