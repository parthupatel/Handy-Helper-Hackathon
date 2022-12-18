import 'dart:convert';
import 'dart:io';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

class CreateServiceScreen extends StatefulWidget {
  @override
  _CreateServiceScreenState createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController serviceNameCont = TextEditingController();
  TextEditingController descriptionCont = TextEditingController();

  FocusNode serviceNameFocus = FocusNode();
  FocusNode descriptionFocus = FocusNode();

  List<XFile> imageFiles = [];
  List<CategoryData> categoryList = [];
  List<String> typeList = [SERVICE_TYPE_FIXED, SERVICE_TYPE_HOURLY];

  ImagePicker picker = ImagePicker();

  CategoryData? selectedCategory;
  String serviceType = '';

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await getCategoryList('all').then((value) {
      if (value.categoryList!.isNotEmpty) {
        categoryList.addAll(value.categoryList.validate());
      }

      setState(() {});
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  Future<void> getMultipleFile() async {
    await picker.pickMultiImage().then((value) {
      imageFiles.addAll(value);
      setState(() {});
    });
  }

  Future<void> createServiceRequest() async {
    appStore.setLoading(true);

    MultipartRequest multiPartRequest = await getMultiPartRequest('service-save');
    multiPartRequest.fields[CreateService.name] = serviceNameCont.text.validate();
    multiPartRequest.fields[CreateService.description] = descriptionCont.text.validate();
    multiPartRequest.fields[CreateService.type] = SERVICE_TYPE_FIXED;
    multiPartRequest.fields[CreateService.price] = '0';
    multiPartRequest.fields[CreateService.addedBy] = appStore.userId.toString().validate();
    multiPartRequest.fields[CreateService.providerId] = appStore.userId.toString();
    multiPartRequest.fields[CreateService.categoryId] = selectedCategory!.id.toString();
    multiPartRequest.fields[CreateService.status] = '1';
    multiPartRequest.fields[CreateService.duration] = "0";

    if (imageFiles.isNotEmpty) {
      await Future.forEach<XFile>(imageFiles, (element) async {
        int i = imageFiles.indexOf(element);
        log('${CreateService.serviceAttachment + i.toString()}');
        multiPartRequest.files.add(await MultipartFile.fromPath('${CreateService.serviceAttachment + i.toString()}', element.path));
      });
    }

    if (imageFiles.isNotEmpty) multiPartRequest.fields[CreateService.attachmentCount] = imageFiles.length.toString();

    if (imageFiles.isNotEmpty) {
      await Future.forEach<XFile>(imageFiles, (element) async {
        int i = imageFiles.indexOf(element);
        log('${CreateService.serviceAttachment + i.toString()} Image Path: ${element.path}');
        multiPartRequest.files.add(await MultipartFile.fromPath('${CreateService.serviceAttachment + i.toString()}', element.path));
      });
    }

    if (imageFiles.isNotEmpty) multiPartRequest.fields[CreateService.attachmentCount] = imageFiles.length.toString();

    multiPartRequest.headers.addAll(buildHeaderTokens());

    log('Multipart request: ${multiPartRequest.fields}');

    sendMultiPartRequest(
      multiPartRequest,
      onSuccess: (data) async {
        appStore.setLoading(false);
        toast(jsonDecode(data)['message'], print: true);

        finish(context, true);
      },
      onError: (error) {
        toast(error.toString(), print: true);
        appStore.setLoading(false);
      },
    ).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.createServiceRequest,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: context.width(),
                height: 120,
                child: DottedBorderWidget(
                  color: primaryColor.withOpacity(0.6),
                  strokeWidth: 1,
                  gap: 6,
                  radius: 12,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(selectImage, height: 25, width: 25, color: appStore.isDarkMode ? white : gray),
                      8.height,
                      Text(language.chooseImages, style: boldTextStyle()),
                    ],
                  ).center().onTap(borderRadius: radius(), () async {
                    getMultipleFile();
                  }),
                ),
              ),
              HorizontalList(
                itemCount: imageFiles.length,
                itemBuilder: (context, i) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.file(File(imageFiles[i].path), width: 90, height: 90, fit: BoxFit.cover).cornerRadiusWithClipRRect(16),
                      Container(
                        decoration: boxDecorationWithRoundedCorners(boxShape: BoxShape.circle, backgroundColor: primaryColor),
                        margin: EdgeInsets.only(right: 8, top: 4),
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 16, color: white),
                      ).onTap(() {
                        imageFiles.removeAt(i);
                        setState(() {});
                      }),
                    ],
                  );
                },
              ).paddingBottom(16).visible(imageFiles.isNotEmpty),
              20.height,
              DropdownButtonFormField<CategoryData>(
                decoration: inputDecoration(context, labelText: language.lblCategory),
                hint: Text(language.selectCategory, style: secondaryTextStyle()),
                value: selectedCategory,
                dropdownColor: context.scaffoldBackgroundColor,
                items: categoryList.map((data) {
                  return DropdownMenuItem<CategoryData>(
                    value: data,
                    child: Text(data.name.validate(), style: primaryTextStyle()),
                  );
                }).toList(),
                onChanged: (CategoryData? value) async {
                  selectedCategory = value!;
                  setState(() {});
                },
              ),
              16.height,
              AppTextField(
                controller: serviceNameCont,
                textFieldType: TextFieldType.NAME,
                nextFocus: descriptionFocus,
                errorThisFieldRequired: language.lblRequiredValidation,
                decoration: inputDecoration(context, labelText: language.serviceName),
              ),
              16.height,
              AppTextField(
                controller: descriptionCont,
                textFieldType: TextFieldType.MULTILINE,
                errorThisFieldRequired: language.lblRequiredValidation,
                maxLines: 2,
                focus: descriptionFocus,
                decoration: inputDecoration(context, labelText: language.serviceDescription),
                validator: (value) {
                  if (value!.isEmpty) return language.lblRequiredValidation;
                  return null;
                },
              ),
              16.height,
              AppButton(
                text: language.save,
                color: context.primaryColor,
                width: context.width(),
                onTap: () {
                  hideKeyboard(context);

                  if (imageFiles.isEmpty) {
                    return toast(language.pleaseAddImage);
                  }

                  if (selectedCategory == null) {
                    return toast(language.pleaseSelectCategory);
                  }

                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();

                    createServiceRequest();
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
