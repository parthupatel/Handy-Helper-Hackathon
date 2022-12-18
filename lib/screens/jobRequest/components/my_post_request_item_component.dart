import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/screens/jobRequest/my_post_detail_screen.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class MyPostRequestItemComponent extends StatefulWidget {
  final PostJobData data;
  final VoidCallback callback;

  MyPostRequestItemComponent({required this.data,required this.callback});

  @override
  _MyPostRequestItemComponentState createState() => _MyPostRequestItemComponentState();
}

class _MyPostRequestItemComponentState extends State<MyPostRequestItemComponent> {

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        MyPostDetailScreen(
          postRequestId: widget.data.id.validate().toInt(),
          postJobData:widget.data,
          callback: () {
            widget.callback.call();
          },
        ).launch(context);
      },
      child: Container(
        decoration: boxDecorationWithRoundedCorners(borderRadius: radius(), backgroundColor: context.cardColor),
        width: context.width(),
        margin: EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
        padding: EdgeInsets.only(top: 12, bottom: 12, left: 16, right: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              CachedImageWidget(
                url: (widget.data.service.validate().isNotEmpty && widget.data.service.validate().first.attachments.validate().isNotEmpty) ? widget.data.service.validate().first.attachments.validate().first.validate(): "",
                fit: BoxFit.cover,
                height: 70,
                width: 70,
                circle: false,
              ).cornerRadiusWithClipRRect(defaultRadius),
            16.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.data.title.validate(), style: boldTextStyle(), maxLines: 2, overflow: TextOverflow.ellipsis),
                4.height,
                PriceWidget(
                  price: widget.data.status.validate() == JOB_REQUEST_STATUS_ACCEPTED ? widget.data.jobPrice.validate() : widget.data.price.validate(),
                  isHourlyService: false,
                  color: textPrimaryColorGlobal,
                  isFreeService: false,
                  size: 18,
                ),
                4.height,
                Text(
                  formatDate(widget.data.createdAt.validate(), format: DATE_FORMAT_2),
                  style: secondaryTextStyle(),
                ),
              ],
            ).expand(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.data.status.validate().getJobStatusColor.withOpacity(0.1),
                borderRadius: radius(8),
              ),
              child: Text(
                widget.data.status.validate().capitalizeFirstLetter(),
                style: boldTextStyle(color: widget.data.status.validate().getJobStatusColor, size: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
