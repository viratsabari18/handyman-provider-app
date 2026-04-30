import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:handyman_provider_flutter/components/base_scaffold_widget.dart';
import 'package:handyman_provider_flutter/components/selected_item_widget.dart';
import 'package:handyman_provider_flutter/controllers/registration_data_controller.dart';

import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Models new/register_request_model.dart';
import '../Models new/registration_data.dart' show Zone, Category;
import '../Models new/upload_doucment_model.dart';
import '../components/app_widgets.dart';
import '../components/empty_error_state_widget.dart';
import '../components/pdf_viewer_component.dart';
import '../main.dart';
import '../models/document_list_response.dart';

import '../service new/auth service/auth_service.dart';
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
  
  // ✅ NEW: Use UploadDocument list instead of Documents
  List<UploadDocument> uploadDocs = [];
  
  // Zone and Category state
  List<Zone> zoneList = [];
  List<String> selectedZoneIds = [];
  List<Category> categoryList = [];
  List<String> selectedCategoryIds = [];
  bool isZoneTileExpanded = false;
  bool isCategoryTileExpanded = false;
  bool isLoadingZonesCategories = true;
  bool isProvider = false;
  bool isLoadingDocuments = true;
  
  // Add error tracking
  String? uploadError;
  bool hasUploadError = false;
  String? zonesCategoriesError;
  bool hasZonesCategoriesError = false;

  // MOCK DATA for UI display without backend API
  List<DocumentItem> getMockDocuments() {
    return [
      DocumentItem(id: 1, name: "Aadhar Card (Front Side)", isRequired: 1),
      DocumentItem(id: 2, name: "Aadhar Card (Back Side)", isRequired: 1),
      DocumentItem(id: 3, name: "Pan Card", isRequired: 1),
    ];
  }

  // Helper method to clear upload error
  void _clearUploadError() {
    if (hasUploadError) {
      setState(() {
        uploadError = null;
        hasUploadError = false;
      });
    }
  }

  // Helper method to clear zones/categories error
  void _clearZonesCategoriesError() {
    if (hasZonesCategoriesError) {
      setState(() {
        zonesCategoriesError = null;
        hasZonesCategoriesError = false;
      });
    }
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
      _clearZonesCategoriesError(); // Clear previous errors
    });
    try {
      print('🔵 Fetching registration fields...');
      final response = await RegistrationDataController.getRegistrationFields();
      print('✅ Categories count: ${response.categories?.length ?? 0}');
      print('✅ Zones count: ${response.zones?.length ?? 0}');
      
      setState(() {
        if (response.zones != null && response.zones!.isNotEmpty) {
          zoneList = response.zones!;
          print('✅ Zones loaded: ${zoneList.length} zones');
        } else {
          // Set error if no zones available
          zonesCategoriesError = "No zones available. Please contact support.";
          hasZonesCategoriesError = true;
        }
        
        if (response.categories != null && response.categories!.isNotEmpty) {
          categoryList = response.categories!;
          print('✅ Categories loaded: ${categoryList.length} categories');
        } else {
          // Set error if no categories available
          if (zonesCategoriesError == null) {
            zonesCategoriesError = "No categories available. Please contact support.";
            hasZonesCategoriesError = true;
          }
        }
        
        isLoadingZonesCategories = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        isLoadingZonesCategories = false;
        zonesCategoriesError = 'Failed to load zones and categories: $e';
        hasZonesCategoriesError = true;
      });
      toast('Failed to load data: $e', print: true);
    }
  }

  void init() {
    // Clear previous errors
    _clearUploadError();
    
    // USING MOCK DATA
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        final mockDocuments = getMockDocuments();
        // Initialize uploadDocs as empty (no files selected yet)
        uploadDocs = [];
        setState(() {
          isLoadingDocuments = false;
        });
        appStore.setLoading(false);
      }
    });
    
    appStore.setLoading(false);
  }

  // ✅ UPDATED: Store file in UploadDocument list
  void getMultipleFile({required int documentId, required String documentName, required int index}) async {
    // Clear previous error when starting file selection
    _clearUploadError();
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false, 
      type: FileType.custom, 
      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf']
    );

    if (result != null) {
      showConfirmDialogCustom(
        context,
        title: languages.confirmationUpload,
        onAccept: (BuildContext context) {
          ifNotTester(context, () {
            final file = File(result.paths.first!);
            
            setState(() {
              // ✅ NEW: Remove existing file for this document if any
              uploadDocs.removeWhere((e) => e.id == documentId);
              
              // ✅ NEW: Add new UploadDocument
              uploadDocs.add(
                UploadDocument(
                  id: documentId,
                  name: documentName,
                  file: file,
                ),
              );
              _clearUploadError(); // Clear error on successful upload
            });
            
            toast("${documentName} uploaded successfully");
          });
        },
        positiveText: languages.lblYes,
        negativeText: languages.lblNo,
        primaryColor: primaryColor,
      );
    } else {
      // User cancelled file selection, no need to show error
      print("File selection cancelled");
    }
  }

  // ✅ UPDATED: Register method with proper file handling - using appStore.isLoading to prevent multiple clicks
  Future<void> register() async {
    // ✅ Check if already loading - prevents multiple clicks
    if (appStore.isLoading) {
      toast("Please wait, registration in progress...");
      return;
    }
    
    // Clear previous errors
    _clearUploadError();
    _clearZonesCategoriesError();
    
    if (!isAcceptedTc) {
      toast("Accept Terms & Conditions");
      setState(() {
        uploadError = "Please accept Terms & Conditions to proceed";
        hasUploadError = true;
      });
      return;
    }

    // Check if all required documents are uploaded
    final requiredDocIds = getMockDocuments()
        .where((doc) => doc.isRequired == 1)
        .map((doc) => doc.id)
        .toList();
    
    final uploadedDocIds = uploadDocs.map((doc) => doc.id).toList();
    final missingDocs = requiredDocIds.where((id) => !uploadedDocIds.contains(id)).toList();
    
    if (missingDocs.isNotEmpty) {
      final missingDocNames = getMockDocuments()
          .where((doc) => missingDocs.contains(doc.id))
          .map((doc) => doc.name)
          .join(', ');
      
      toast("Please upload all required documents");
      setState(() {
        uploadError = "Missing required documents: $missingDocNames";
        hasUploadError = true;
      });
      return;
    }

    // Validate zones and categories for provider
    if (isProvider) {
      if (selectedZoneIds.isEmpty) {
        toast("Please select at least one service zone");
        setState(() {
          uploadError = "Please select at least one service zone for your service area";
          hasUploadError = true;
        });
        return;
      }
      
      if (selectedCategoryIds.isEmpty) {
        toast("Please select at least one category");
        setState(() {
          uploadError = "Please select at least one service category";
          hasUploadError = true;
        });
        return;
      }
    }

    // ✅ Set loading to true - this will disable the button
    appStore.setLoading(true);

    try {
      // ✅ ONLY send IDs (not the files)
      final request = RegisterRequest(
        firstName: widget.formRequest['first_name'],
        lastName: widget.formRequest['last_name'],
        username: widget.formRequest['username'],
        email: widget.formRequest['email'],
        password: widget.formRequest['password'],
        contactNumber: widget.formRequest['mobile'],
        userType: widget.formRequest['user_type'],

        /// Provider
        providerTypeId: widget.formRequest['provider_type_id'],

        /// Handyman
        providerId: widget.formRequest['provider_id'],
        handymanTypeId: widget.formRequest['handyman_type_id'],

        categoryIds: isProvider
            ? selectedCategoryIds.map((e) => int.parse(e)).toList()
            : null,

        serviceZones: isProvider
            ? selectedZoneIds.map((e) => int.parse(e)).toList()
            : null,

        /// 🔥 ONLY DOCUMENT IDs (NOT FILES)
        documentIds: uploadDocs.map((e) => e.id).toList(),
      );
      
      // ✅ Send FILES separately
      final files = uploadDocs.map((doc) => doc.file).toList();
      
      final response = await AuthService.registerUser(
        request: request,
        files: files,
      );

      if (response != null && response.data?.id != null) {
        toast(response.message ?? "Registration Success");
        
        // Clear sensitive data after successful registration
        uploadDocs.clear();
        
        push(
          SignInScreen(),
          isNewTask: true,
          pageRouteAnimation: PageRouteAnimation.Fade,
        );
      } else {
        final errorMsg = response?.message ?? "Registration failed";
        toast(errorMsg);
        setState(() {
          uploadError = errorMsg;
          hasUploadError = true;
        });
      }
    } catch (e) {
      final errorMsg = "Registration error: ${e.toString()}";
      toast(errorMsg);
      setState(() {
        uploadError = errorMsg;
        hasUploadError = true;
      });
      print("Registration error: $e");
    } finally {
      // ✅ Always set loading to false when done (success or error)
      appStore.setLoading(false);
    }
  }

  // Check if document is uploaded
  bool isDocumentUploaded(int documentId) {
    return uploadDocs.any((doc) => doc.id == documentId);
  }

  UploadDocument? getUploadDoc(int documentId) {
    for (var doc in uploadDocs) {
      if (doc.id == documentId) return doc;
    }
    return null;
  }

  File? getUploadedFile(int documentId) {
    return getUploadDoc(documentId)?.file;
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
            _clearUploadError(); // Clear error when toggling terms
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
        initiallyExpanded: false,
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
                _clearZonesCategoriesError(); // Clear error when selecting zones
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
        initiallyExpanded: false,
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
                _clearZonesCategoriesError(); // Clear error when selecting categories
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
    uploadDocs.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mockDocuments = getMockDocuments();
    
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
                        // Display upload error if any
                        if (uploadError != null)
                          Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    uploadError!,
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Show zones and categories ONLY for Provider
                        if (isProvider) ...[
                          if (isLoadingZonesCategories)
                            Center(child: LoaderWidget()).paddingTop(20)
                          else ...[
                            // Display zones/categories error if any
                            if (zonesCategoriesError != null)
                              Container(
                                margin: EdgeInsets.only(bottom: 16),
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        zonesCategoriesError!,
                                        style: TextStyle(color: Colors.orange.shade700, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (zoneList.isNotEmpty) _buildZoneSelectionTile(),
                            if (zoneList.isEmpty && zonesCategoriesError == null)
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
                            if (categoryList.isEmpty && zonesCategoriesError == null)
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
                        else if (mockDocuments.isNotEmpty)
                          AnimatedListView(
                            itemCount: mockDocuments.length,
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
                              DocumentItem data = mockDocuments[index];
                              final isUploaded = isDocumentUploaded(data.id);
                              final uploadedFile = getUploadedFile(data.id);
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: primaryTextStyle(size: 14),
                                      children: [
                                        TextSpan(text: data.name, style: boldTextStyle(size: 14, weight: FontWeight.w500)),
                                        if (data.isRequired == 1) TextSpan(text: ' *', style: primaryTextStyle(color: Colors.red, size: 14)),
                                        if (isUploaded) TextSpan(
                                          text: ' ✓', 
                                          style: primaryTextStyle(color: Colors.green, size: 16)
                                        ),
                                      ],
                                    ),
                                  ),
                                  12.height,
                                  GestureDetector(
                                    onTap: () {
                                      getMultipleFile(
                                        documentId: data.id, 
                                        documentName: data.name,
                                        index: index,
                                      );
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
                                        child: isUploaded && uploadedFile != null
                                          ? Container(
                                              height: 200,
                                              width: context.width(),
                                              decoration: BoxDecoration(
                                                color: lightPrimaryColor,
                                                borderRadius: radius(defaultRadius),
                                                image: (uploadedFile.path.contains('.pdf'))
                                                  ? DecorationImage(
                                                      image: AssetImage(img_files),
                                                      colorFilter: ColorFilter.mode(
                                                        black.withValues(alpha: 0.6),
                                                        BlendMode.darken,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : DecorationImage(
                                                      image: FileImage(uploadedFile),
                                                      fit: BoxFit.cover,
                                                    ),
                                              ),
                                              child: (uploadedFile.path.contains('.pdf'))
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
                                                        Text(uploadedFile.path.split("/").last, 
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
                                                          PdfViewerComponent(pdfFile: uploadedFile.path, isFile: true).launch(context);
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
                                _clearUploadError(); // Clear errors on refresh
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
                    // ✅ Button is disabled when appStore.isLoading is true
                    color: appStore.isLoading 
                        ? primaryColor.withValues(alpha: 0.5) 
                        : primaryColor,
                    textStyle: boldTextStyle(color: white),
                    width: context.width() - context.navigationBarHeight,
                    onTap: () {
                      // ✅ Only allow tap when not loading
                      if (!appStore.isLoading) {
                        register();
                      }
                    },
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

// Helper class for mock documents
class DocumentItem {
  final int id;
  final String name;
  final int isRequired;
  
  DocumentItem({
    required this.id,
    required this.name,
    required this.isRequired,
  });
}