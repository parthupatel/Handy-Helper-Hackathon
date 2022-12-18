import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/dashboard_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/auth/sign_in_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/component/category_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/featured_service_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/service_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/slider_and_location_component.dart';
import 'package:booking_system_flutter/screens/jobRequest/my_post_request_list_screen.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class DashboardFragment extends StatefulWidget {
  @override
  _DashboardFragmentState createState() => _DashboardFragmentState();
}

class _DashboardFragmentState extends State<DashboardFragment> {
  Future<DashboardResponse>? future;

  @override
  void initState() {
    super.initState();
    init();

    setStatusBarColor(transparentColor, delayInMilliSeconds: 1000);

    LiveStream().on(LIVESTREAM_UPDATE_DASHBOARD, (p0) {
      setState(() {});
    });
  }

  void init() async {
    future = userDashboard(isCurrentLocation: appStore.isCurrentLocation, lat: getDoubleAsync(LATITUDE), long: getDoubleAsync(LONGITUDE));
  }

  Widget createJobRequestComponent() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.primaryColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(defaultRadius), topRight: Radius.circular(defaultRadius)),
      ),
      width: context.width(),
      child: Column(
        children: [
          16.height,
          Text("Didn't find your service? Don't worry, You can post your requirements.", style: primaryTextStyle(color: white, size: 18), textAlign: TextAlign.center),
          20.height,
          AppButton(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: context.primaryColor),
                4.width,
                Text(language.newPostJobRequest, style: boldTextStyle(color: context.primaryColor)),
              ],
            ),
            textStyle: primaryTextStyle(color: appStore.isDarkMode ? textPrimaryColorGlobal : context.primaryColor),
            onTap: () async {
              if (appStore.isLoggedIn) {
                MyPostRequestListScreen().launch(context);
              } else {
                setStatusBarColor(Colors.white, statusBarIconBrightness: Brightness.dark);
                bool? res = await SignInScreen(isFromDashboard: true).launch(context);

                if (res ?? false) {
                  MyPostRequestListScreen().launch(context);
                }
              }
            },
          ),
          16.height,
        ],
      ),
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
    LiveStream().dispose(LIVESTREAM_UPDATE_DASHBOARD);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          init();
          setState(() {});
          return await 2.seconds.delay;
        },
        child: Stack(
          children: [
            FutureBuilder<DashboardResponse>(
              future: future,
              builder: (context, snap) {
                if (snap.hasData) {
                  reviewData = snap.data!.dashboardCustomerReview.validate();

                  return AnimatedScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    listAnimationType: ListAnimationType.FadeIn,
                    children: [
                      SliderLocationComponent(
                        sliderList: snap.data!.slider.validate(),
                        notificationReadCount: snap.data!.notificationUnreadCount.validate(),
                        callback: () async {
                          init();
                          await 300.milliseconds.delay;
                          setState(() {});
                        },
                      ),
                      32.height,
                      CategoryComponent(categoryList: snap.data!.category.validate()),
                      24.height,
                      FeaturedServiceListComponent(serviceList: snap.data!.featuredServices.validate()),
                      ServiceListComponent(serviceList: snap.data!.service.validate()),
                      16.height,
                      createJobRequestComponent(),
                    ],
                  );
                }
                return snapWidgetHelper(snap, loadingWidget: Offstage());
              },
            ),
            Observer(builder: (context) => LoaderWidget().visible(appStore.isLoading)),
          ],
        ),
      ),
    );
  }
}
