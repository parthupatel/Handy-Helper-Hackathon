import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';

class CategoryWidget extends StatelessWidget {
  final CategoryData categoryData;
  final double? width;
  final bool? isFromCategory;

  CategoryWidget({required this.categoryData, this.width, this.isFromCategory});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? context.width() / 4 - 24,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: context.cardColor, shape: BoxShape.circle),
            child: categoryData.categoryImage.validate().endsWith('.svg')
                ? SvgPicture.network(
                    categoryData.categoryImage.validate(),
                    height: CATEGORY_ICON_SIZE,
                    width: CATEGORY_ICON_SIZE,
                    color: appStore.isDarkMode ? Colors.white : categoryData.color.toColor(),
                    placeholderBuilder: (context) => PlaceHolderWidget(height: CATEGORY_ICON_SIZE, width: CATEGORY_ICON_SIZE, color: transparentColor),
                  ).paddingAll(8)
                : CachedImageWidget(
                    url: categoryData.categoryImage.validate(),
                    width: CATEGORY_ICON_SIZE,
                    height: CATEGORY_ICON_SIZE,
                    circle: true,
                  ),
          ),
          Text(
            '${categoryData.name.validate()}',
            style: primaryTextStyle(size: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
