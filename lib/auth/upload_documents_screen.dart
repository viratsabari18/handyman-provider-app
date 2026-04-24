import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/Models%20new/zone_and_cetagory_model.dart';
import 'package:handyman_provider_flutter/components/base_scaffold_widget.dart';
import 'package:handyman_provider_flutter/components/selected_item_widget.dart';
import 'package:handyman_provider_flutter/controllers/zone_and_cetagories_controller.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/app_widgets.dart';
import '../components/empty_error_state_widget.dart';
import '../components/pdf_viewer_component.dart';
import '../main.dart';
import '../models/document_list_response.dart';
import '../networks/rest_apis.dart';
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/configs.dart';
import '../utils/constant.dart';
import '../utils/images.dart';
import 'sign_in_screen.dart';

class UploadDocumentsScreen extends StatefulWidget {
  final Map<String, dynamic> formRequest;
  const UploadDocumentsScreen({super.key, required this.formRequest});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  bool isAcceptedTc = false;
  ValueNotifier _valueNotifier = ValueNotifier(true);
  
  // COMMENTED: Backend API future - WILL BE USED WHEN BACKEND IS READY
  // Future<DocumentListResponse>? future;
  
  FilePickerResult? filePickerResult;
  File? imageFile;
  List<Documents> uploadDocResp = [];
  
  // Zone and Category state
  List<Zone> zoneList = [];
  List<String> selectedZoneIds = [];
  List<Category> categoryList = [];
  List<String> selectedCategoryIds = [];
  bool isZoneTileExpanded = false;  // Start closed
  bool isCategoryTileExpanded = false;  // Start closed
  bool isLoadingZonesCategories = true;
  bool isProvider = false;
  bool isLoadingDocuments = true;

  // MOCK DATA for UI display without backend API
List<Documents> getMockDocuments() {
  return [
    Documents(
      id: 1,
      name: "Aadhar Card (Front Side)",
      isRequired: 1,
      filePath: null,
    ),
    Documents(
      id: 2,
      name: "Aadhar Card (Back Side)",
      isRequired: 1,
      filePath: null,
    ),
    Documents(
      id: 3,
      name: "Pan Card",
      isRequired: 1,
      filePath: null,
    ),
  ];
}

  @override
  void initState() {
    super.initState();
    isProvider = widget.formRequest['user_type'] == USER_TYPE_PROVIDER;
    init();
    if (isProvider) {
      fetchZonesAndCategories();
    }
  }

  Future<void> fetchZonesAndCategories() async {
    setState(() {
      isLoadingZonesCategories = true;
    });
    try {
      print('🔵 Fetching registration fields...');
      final response = await ZoneAndCetagoriesController.getRegistrationFields();
      print('✅ Categories count: ${response.categories?.length ?? 0}');
      print('✅ Zones count: ${response.zones?.length ?? 0}');
      
      setState(() {
        if (response.zones != null && response.zones!.isNotEmpty) {
          zoneList = response.zones!;
          print('✅ Zones loaded: ${zoneList.length} zones');
        }
        if (response.categories != null && response.categories!.isNotEmpty) {
          categoryList = response.categories!;
          print('✅ Categories loaded: ${categoryList.length} categories');
        }
        isLoadingZonesCategories = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('Stack trace: $stackTrace');
      toast('Failed to load data: $e', print: true);
      setState(() {
        isLoadingZonesCategories = false;
      });
    }
  }

  void init() {
    // ============================================================
    // BACKEND API CALL - COMMENTED FOR NOW
    // Uncomment this when backend is ready
    // ============================================================
    // future = getDocList().whenComplete(() {
    //   appStore.setLoading(false);
    //   setState(() {
    //     isLoadingDocuments = false;
    //   });
    // }).catchError((error) {
    //   setState(() {
    //     isLoadingDocuments = false;
    //   });
    //   toast('Failed to load documents: $error');
    // });
    
    // USING MOCK DATA (Remove this when backend is ready)
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        final mockResponse = DocumentListResponse();
        mockResponse.documents = getMockDocuments();
        uploadDocResp = mockResponse.documents!;
        setState(() {
          isLoadingDocuments = false;
        });
        appStore.setLoading(false);
      }
    });
    
    appStore.setLoading(false);
  }

  void getMultipleFile({int? updateId, Function(String)? setImage}) async {
    filePickerResult = await FilePicker.platform.pickFiles(
      allowMultiple: false, 
      type: FileType.custom, 
      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf']
    );

    if (filePickerResult != null) {
      showConfirmDialogCustom(
        context,
        title: languages.confirmationUpload,
        onAccept: (BuildContext context) {
          ifNotTester(context, () {
            setState(() {
              imageFile = File(filePickerResult!.paths.first!);
              setImage?.call(imageFile!.path);
            });
          });
        },
        positiveText: languages.lblYes,
        negativeText: languages.lblNo,
        primaryColor: primaryColor,
      );
    }
  }

  // Register API Fun
  Future<void> registerFun() async {
    if (!isAcceptedTc) {
      toast(languages.lblTermCondition);
      return;
    }
    
    // Validate zones and categories for provider
    if (isProvider) {
      if (selectedZoneIds.isEmpty) {
        toast(languages.plzSelectOneZone);
        return;
      }
      if (selectedCategoryIds.isEmpty) {
        toast(languages.plzSelectOneCategory);
        return;
      }
    }
    
    log("Document List: ${uploadDocResp.where((element) => element.filePath?.isEmpty ?? true).toList()}");
    if (uploadDocResp.isEmpty || (uploadDocResp.where((element) => (element.isRequired == 1 && (element.filePath?.isEmpty ?? true))).isNotEmpty)) {
      toast(languages.pleaseUploadAllRequired);
      return;
    }
    
    appStore.setLoading(true);
    
    // Add zones and categories to form request if provider
    if (isProvider) {
      widget.formRequest['zone_ids'] = selectedZoneIds;
      widget.formRequest['category_ids'] = selectedCategoryIds;
    }
    
    List<Documents> list = uploadDocResp.where((element) => element.filePath?.isNotEmpty ?? false).toList();
    for (int i = 0; i < list.length; i++) {
      widget.formRequest['document_id[$i]'] = list[i].id;
    }
    log("Request ---> ${widget.formRequest}");
    
    // ============================================================
    // BACKEND REGISTRATION API CALL - COMMENTED FOR NOW
    // Uncomment this when backend is ready
    // ============================================================
    // await registerUser(widget.formRequest, imageFile: list).then((value) {
    //   appStore.setLoading(false);
    //   toast(value.message.validate());
    //   push(SignInScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
    // }).catchError((error) {
    //   appStore.setLoading(false);
    //   toast(error.toString());
    // }).whenComplete(() {
    //   appStore.setLoading(false);
    // });
    
    // MOCK: Simulate successful registration (Remove this when backend is ready)
    await Future.delayed(Duration(seconds: 2));
    toast("Registration successful! (Demo)");
    push(SignInScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
    appStore.setLoading(false);
  }

  // Terms of service and Privacy policy text
  Widget _buildTcAcceptWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ValueListenableBuilder(
          valueListenable: _valueNotifier,
          builder: (context, value, child) => SelectedItemWidget(isSelected: isAcceptedTc).onTap(() async {
            isAcceptedTc = !isAcceptedTc;
            _valueNotifier.notifyListeners();
          }),
        ),
        16.width,
        
        RichTextWidget(
          list: [
            TextSpan(text: '${languages.lblIAgree} ', style: secondaryTextStyle()),
            TextSpan(
              text: languages.lblTermsOfService,
              style: boldTextStyle(color: primaryColor),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  checkIfLink(context, appConfigurationStore.termConditions, title: languages.lblTermsAndConditions);
                },
            ),
            TextSpan(text: ' & ', style: secondaryTextStyle()),
            TextSpan(
              text: languages.lblPrivacyPolicy,
              style: boldTextStyle(color: primaryColor),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  checkIfLink(context, appConfigurationStore.privacyPolicy, title: languages.lblPrivacyPolicy);
                },
            ),
          ],
        ).flexible(flex: 2),
      ],
    ).paddingAll(16);
  }

  Widget _buildZoneSelectionTile() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: boxDecorationDefault(color: context.cardColor),
      child: ExpansionTile(
        iconColor: context.iconColor,
        tilePadding: EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.symmetric(horizontal: 16),
        initiallyExpanded: false, // Start closed
        dense: true,
        visualDensity: VisualDensity.compact,
        title: Row(
          children: [
            Icon(Icons.location_on_outlined, size: 20, color: context.iconColor),
            8.width,
            Text(languages.selectZones, style: boldTextStyle(size: 14)),
            if (selectedZoneIds.isNotEmpty) ...[
              8.width,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedZoneIds.length} ${languages.selected}',
                  style: primaryTextStyle(size: 10, color: primaryColor),
                ),
              ),
            ],
          ],
        ),
        onExpansionChanged: (val) {
          setState(() {
            isZoneTileExpanded = val;
          });
        },
        trailing: Icon(
          isZoneTileExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: context.iconColor,
        ),
        children: zoneList.map((zone) {
          bool isSelected = selectedZoneIds.contains(zone.id.toString());
          return CheckboxListTile(
            checkboxShape: RoundedRectangleBorder(borderRadius: radius(4)),
            activeColor: context.primaryColor,
            checkColor: appStore.isDarkMode ? context.iconColor : context.cardColor,
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            title: Text(zone.name.validate(), style: secondaryTextStyle(color: context.iconColor)),
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selectedZoneIds.add(zone.id.toString());
                } else {
                  selectedZoneIds.remove(zone.id.toString());
                }
              });
            },
            splashRadius: 0.0,
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategorySelectionTile() {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      decoration: boxDecorationDefault(color: context.cardColor),
      child: ExpansionTile(
        iconColor: context.iconColor,
        tilePadding: EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.symmetric(horizontal: 16),
        initiallyExpanded: false, // Start closed
        dense: true,
        visualDensity: VisualDensity.compact,
        title: Row(
          children: [
            Icon(Icons.category_outlined, size: 20, color: context.iconColor),
            8.width,
            Text(languages.selectCategories, style: boldTextStyle(size: 14)),
            if (selectedCategoryIds.isNotEmpty) ...[
              8.width,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedCategoryIds.length} ${languages.selected}',
                  style: primaryTextStyle(size: 10, color: primaryColor),
                ),
              ),
            ],
          ],
        ),
        onExpansionChanged: (val) {
          setState(() {
            isCategoryTileExpanded = val;
          });
        },
        trailing: Icon(
          isCategoryTileExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: context.iconColor,
        ),
        children: categoryList.map((category) {
          bool isSelected = selectedCategoryIds.contains(category.id.toString());
          return CheckboxListTile(
            checkboxShape: RoundedRectangleBorder(borderRadius: radius(4)),
            activeColor: context.primaryColor,
            checkColor: appStore.isDarkMode ? context.iconColor : context.cardColor,
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            title: Text(category.name.validate(), style: secondaryTextStyle(color: context.iconColor)),
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selectedCategoryIds.add(category.id.toString());
                } else {
                  selectedCategoryIds.remove(category.id.toString());
                }
              });
            },
            splashRadius: 0.0,
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    uploadDocResp.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: languages.uploadDocuments,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Show zones and categories for Provider
                        if (isProvider) ...[
                          if (isLoadingZonesCategories)
                            Center(child: LoaderWidget()).paddingTop(20)
                          else ...[
                            if (zoneList.isNotEmpty) _buildZoneSelectionTile(),
                            if (zoneList.isEmpty)
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: boxDecorationDefault(color: context.cardColor),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.orange),
                                    12.width,
                                    Expanded(
                                      child: Text('No zones available', 
                                        style: secondaryTextStyle(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (categoryList.isNotEmpty) _buildCategorySelectionTile(),
                            if (categoryList.isEmpty)
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: boxDecorationDefault(color: context.cardColor),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.orange),
                                    12.width,
                                    Expanded(
                                      child: Text('No categories available', 
                                        style: secondaryTextStyle(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                        
                        // Documents Section Title
                        if (isProvider) 24.height,
                        
                        Text(languages.uploadRequiredDocuments, style: boldTextStyle(size: 14)),
                        8.height,
                        RichText(
                          text: TextSpan(
                            style: secondaryTextStyle(size: 12),
                            children: [
                              TextSpan(text: languages.pleaseUploadTheFollowing),
                              TextSpan(
                                text: '*',
                                style: secondaryTextStyle(size: 12).copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: ' ${languages.requiredDocumentsMustBe}'),
                            ],
                          ),
                        ),
                        24.height,
                        
                        // Document list UI
                        if (isLoadingDocuments)
                          Center(child: LoaderWidget()).paddingTop(context.height() * 0.2)
                        else if (uploadDocResp.isNotEmpty)
                          AnimatedListView(
                            itemCount: uploadDocResp.length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            listAnimationType: ListAnimationType.FadeIn,
                            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                            emptyWidget: NoDataWidget(
                              title: languages.noNotificationTitle,
                              subTitle: languages.noNotificationSubTitle,
                              imageWidget: EmptyStateWidget(),
                            ),
                            itemBuilder: (context, index) {
                              Documents data = uploadDocResp[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: primaryTextStyle(size: 14),
                                      children: [
                                        TextSpan(text: data.name.validate(), style: boldTextStyle(size: 14, weight: FontWeight.w500)),
                                        if (data.isRequired == 1) TextSpan(text: ' *', style: primaryTextStyle(color: Colors.red, size: 14)),
                                      ],
                                    ),
                                  ),
                                  12.height,
                                  GestureDetector(
                                    onTap: () {
                                      getMultipleFile(setImage: (imagePath) {
                                        log("Image Path: $imagePath");
                                        setState(() {
                                          uploadDocResp[index] = uploadDocResp[index].copyWith(filePath: imagePath);
                                        });
                                      });
                                    },
                                    child: DottedBorderWidget(
                                      color: context.dividerColor,
                                      radius: defaultRadius,
                                      child: Container(
                                        height: 200,
                                        width: context.width(),
                                        decoration: BoxDecoration(
                                          color: lightPrimaryColor,
                                          borderRadius: radius(defaultRadius),
                                        ),
                                        alignment: Alignment.center,
                                        child: (data.filePath?.isNotEmpty ?? false) 
                                          ? Container(
                                              height: 200,
                                              width: context.width(),
                                              decoration: BoxDecoration(
                                                color: lightPrimaryColor,
                                                borderRadius: radius(defaultRadius),
                                                image: (data.filePath?.contains('.pdf') ?? false)
                                                  ? DecorationImage(
                                                      image: AssetImage(img_files),
                                                      colorFilter: ColorFilter.mode(
                                                        black.withValues(alpha: 0.6),
                                                        BlendMode.darken,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : DecorationImage(
                                                      image: FileImage(File(data.filePath!)),
                                                      fit: BoxFit.cover,
                                                    ),
                                              ),
                                              child: (data.filePath?.contains('.pdf') ?? false)
                                                ? Container(
                                                    width: double.infinity,
                                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.only(
                                                        bottomLeft: radiusCircular(defaultRadius),
                                                        bottomRight: radiusCircular(defaultRadius)
                                                      )
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text("${data.filePath.validate().split("/").last}", 
                                                          style: boldTextStyle(color: white), 
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          textAlign: TextAlign.center,
                                                        ),
                                                        8.height,
                                                        Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(4),
                                                            color: context.primaryColor,
                                                          ),
                                                          child: Text(languages.viewPDF, style: boldTextStyle(color: white)),
                                                        ).onTap(() {
                                                          PdfViewerComponent(pdfFile: data.filePath.validate(), isFile: true).launch(context);
                                                        }),
                                                      ],
                                                    ),
                                                  )
                                                : Offstage(),
                                            )
                                          : Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Image.asset(ic_documents, height: 58),
                                                18.height,
                                                RichText(
                                                  text: TextSpan(
                                                    style: primaryTextStyle(size: 14),
                                                    children: [
                                                      TextSpan(text: languages.dropYourFilesHereOr, style: primaryTextStyle(size: 14, weight: FontWeight.w500, color: black)),
                                                      TextSpan(text: " ${languages.browse}", style: boldTextStyle(size: 14, color: context.primaryColor)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                      ),
                                    ),
                                  ),
                                  16.height
                                ],
                              );
                            },
                            onSwipeRefresh: () async {
                              setState(() {
                                isLoadingDocuments = true;
                              });
                              init();
                              if (isProvider) {
                                await fetchZonesAndCategories();
                              }
                              setState(() {});
                              return await 2.seconds.delay;
                            },
                          )
                        else
                          NoDataWidget(
                            title: "No documents found",
                            subTitle: "No documents are required for registration",
                            imageWidget: EmptyStateWidget(),
                          ).paddingTop(context.height() * 0.2),
                      ],
                    ),
                  ),
                ),
                _buildTcAcceptWidget(),
                Observer(
                  builder: (_) => AppButton(
                    margin: EdgeInsets.only(bottom: 12),
                    text: languages.lblSignup,
                    height: 40,
                    color: appStore.isLoading ? primaryColor.withValues(alpha: 0.5) : primaryColor,
                    textStyle: boldTextStyle(color: white),
                    width: context.width() - context.navigationBarHeight,
                    onTap: () {
                      if (!appStore.isLoading) {
                        registerFun();
                      }
                    }
                  ),
                ).paddingOnly(left: 16.0, right: 16.0, bottom: 16.0)
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openPdfExternally(String pdfUrl) async {
    final uri = Uri.parse(pdfUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $pdfUrl';
    }
  }
}