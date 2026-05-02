import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/base_scaffold_widget.dart';
import 'package:handyman_provider_flutter/components/selected_item_widget.dart';
import 'package:handyman_provider_flutter/controllers/registration_data_controller.dart';
import 'package:handyman_provider_flutter/fragments/booking_fragment.dart';
import 'package:handyman_provider_flutter/provider/components/assign_handyman_screen.dart';
import 'package:handyman_provider_flutter/utils/model_keys.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Models new/register_request_model.dart';
import '../Models new/registration_data.dart';
import '../Models new/upload_doucment_model.dart';
import '../components/app_widgets.dart';
import '../components/empty_error_state_widget.dart';
import '../components/pdf_viewer_component.dart';
import '../main.dart';
import '../models/user_data.dart';
import '../models/document_list_response.dart';
import '../service new/auth service/auth_service.dart';
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/configs.dart';
import '../utils/constant.dart';
import '../utils/images.dart';
import '../networks/rest_apis.dart';

class HandymanUploadDocumentsScreen extends StatefulWidget {
  final Map<String, dynamic> formRequest;
  final bool isUpdate;
  final UserData? handymanData;
  final Function? onUpdate;

  const HandymanUploadDocumentsScreen({
    super.key,
    required this.formRequest,
    this.isUpdate = false,
    this.handymanData,
    this.onUpdate,
  });

  @override
  State<HandymanUploadDocumentsScreen> createState() =>
      _HandymanUploadDocumentsScreenState();
}

class _HandymanUploadDocumentsScreenState
    extends State<HandymanUploadDocumentsScreen> {
  bool isAcceptedTc = false;
  ValueNotifier _valueNotifier = ValueNotifier(true);

  List<UploadDocument> uploadDocs = [];

  bool isLoadingDocuments = true;

  String? uploadError;
  bool hasUploadError = false;

  // Document list
  List<DocumentItem> documentList = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    _clearUploadError();

    // Initialize document list
    documentList = getMockDocuments();

    // Simulate loading
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          isLoadingDocuments = false;
        });
      }
    });
  }

  List<DocumentItem> getMockDocuments() {
    return [
      DocumentItem(id: 1, name: "Aadhar Card (Front Side)", isRequired: 1),
      DocumentItem(id: 2, name: "Aadhar Card (Back Side)", isRequired: 1),
      DocumentItem(id: 3, name: "Pan Card", isRequired: 1),
    ];
  }

  void _clearUploadError() {
    if (hasUploadError) {
      setState(() {
        uploadError = null;
        hasUploadError = false;
      });
    }
  }

  Future<void> getMultipleFile(
      {required int documentId,
      required String documentName,
      required int index}) async {
    _clearUploadError();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.custom,
          allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf']);

      if (result != null &&
          result.paths.isNotEmpty &&
          result.paths.first != null) {
        final file = File(result.paths.first!);

        setState(() {
          // Remove existing file for this document if any
          uploadDocs.removeWhere((e) => e.id == documentId);

          // Add new UploadDocument
          uploadDocs.add(
            UploadDocument(
              id: documentId,
              name: documentName,
              file: file,
            ),
          );
          _clearUploadError();
        });

        toast("${documentName} uploaded successfully");
      } else {
        // User cancelled file selection
        print("File selection cancelled");
      }
    } catch (e) {
      toast("Error selecting file: $e");
      print("Error selecting file: $e");
    }
  }

  Future<void> registerOrUpdate() async {
    if (appStore.isLoading) {
      toast("Please wait, processing...");
      return;
    }

    _clearUploadError();

    // For new handyman, need to accept terms
    if (!widget.isUpdate && !isAcceptedTc) {
      toast("Accept Terms & Conditions");
      setState(() {
        uploadError = "Please accept Terms & Conditions to proceed";
        hasUploadError = true;
      });
      return;
    }

    // Check if all required documents are uploaded (only for new handyman)
    if (!widget.isUpdate && documentList.isNotEmpty) {
      final requiredDocIds = documentList
          .where((doc) => doc.isRequired == 1)
          .map((doc) => doc.id)
          .toList();

      final uploadedDocIds = uploadDocs.map((doc) => doc.id).toList();
      final missingDocs =
          requiredDocIds.where((id) => !uploadedDocIds.contains(id)).toList();

      if (missingDocs.isNotEmpty) {
        final missingDocNames = documentList
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
    }

    appStore.setLoading(true);

    try {
      if (widget.isUpdate) {
        await updateHandyman();
      } else {
        await registerNewHandyman();
      }
    } catch (e) {
      final errorMsg = "Error: ${e.toString()}";
      toast(errorMsg);
      setState(() {
        uploadError = errorMsg;
        hasUploadError = true;
      });
    } finally {
      appStore.setLoading(false);
    }
  }

  Future<void> registerNewHandyman() async {
    final request = RegisterRequest(
      firstName: widget.formRequest['first_name'],
      lastName: widget.formRequest['last_name'],
      username: widget.formRequest['username'],
      email: widget.formRequest['email'],
      password: widget.formRequest['password'],
      contactNumber: widget.formRequest['mobile'],
      userType: widget.formRequest['user_type'],
      providerId: widget.formRequest['provider_id'],
      handymanTypeId: widget.formRequest['handyman_type_id'],
      documentIds: uploadDocs.map((e) => e.id).toList(),
    );

    final files = uploadDocs.map((doc) => doc.file).toList();

    final response = await AuthService.registerUser(
      request: request,
      files: files,
    );

    if (response != null && response.data?.id != null) {
      toast(response.message ?? "Handyman registered successfully");
      uploadDocs.clear();

      if (widget.onUpdate != null) {
        widget.onUpdate!.call();
      }
      BookingFragment().launch(context,
          pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
    } else {
      throw Exception(response?.message ?? "Registration failed");
    }
  }

  Future<void> updateHandyman() async {
    var request = {
      CommonKeys.id: widget.formRequest['id'],
      UserKeys.firstName: widget.formRequest['first_name'],
      UserKeys.lastName: widget.formRequest['last_name'],
      UserKeys.userName: widget.formRequest['username'],
      UserKeys.email: widget.formRequest['email'],
      UserKeys.contactNumber: widget.formRequest['mobile'],
      UserKeys.designation: widget.formRequest['designation'],
      UserKeys.handyman_zone_id: widget.formRequest['handyman_zone_id'],
      UserKeys.handymanTypeId: widget.formRequest['handyman_type_id'],
      UserKeys.providerId: widget.formRequest['provider_id'],
      UserKeys.status: USER_STATUS_CODE,
    };

    await updateProfile(request).then((res) async {
      toast("Handyman updated successfully");
      if (widget.onUpdate != null) {
        widget.onUpdate!.call();
      }
      finish(context, true);
    }).catchError((e) {
      throw Exception(e.toString());
    });
  }

  bool isDocumentUploaded(int documentId) {
    return uploadDocs.any((doc) => doc.id == documentId);
  }

  File? getUploadedFile(int documentId) {
    try {
      final doc = uploadDocs.firstWhere((e) => e.id == documentId);
      return doc.file;
    } catch (e) {
      return null;
    }
  }

  Widget _buildTcAcceptWidget() {
    if (widget.isUpdate) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ValueListenableBuilder(
            valueListenable: _valueNotifier,
            builder: (context, value, child) =>
                SelectedItemWidget(isSelected: isAcceptedTc).onTap(() async {
              isAcceptedTc = !isAcceptedTc;
              _valueNotifier.notifyListeners();
              _clearUploadError();
            }),
          ),
          16.width,
          Expanded(
            child: RichTextWidget(
              list: [
                TextSpan(
                    text: '${languages.lblIAgree} ',
                    style: secondaryTextStyle()),
                TextSpan(
                  text: languages.lblTermsOfService,
                  style: boldTextStyle(color: primaryColor),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      checkIfLink(context, appConfigurationStore.termConditions,
                          title: languages.lblTermsAndConditions);
                    },
                ),
                TextSpan(text: ' & ', style: secondaryTextStyle()),
                TextSpan(
                  text: languages.lblPrivacyPolicy,
                  style: boldTextStyle(color: primaryColor),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      checkIfLink(context, appConfigurationStore.privacyPolicy,
                          title: languages.lblPrivacyPolicy);
                    },
                ),
              ],
            ),
          ),
        ],
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
    return AppScaffold(
      appBarTitle: widget.isUpdate
          ? "Update Handyman Documents"
          : languages.uploadDocuments,
      body: SafeArea(
        child: Column(
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                uploadError!,
                                style: TextStyle(
                                    color: Colors.red.shade700, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Document upload section
                    if (!widget.isUpdate) ...[
                      Text(languages.uploadRequiredDocuments,
                          style: boldTextStyle(size: 14)),
                      8.height,
                      RichText(
                        text: TextSpan(
                          style: secondaryTextStyle(size: 12),
                          children: [
                            TextSpan(text: languages.pleaseUploadTheFollowing),
                            TextSpan(
                              text: '*',
                              style: secondaryTextStyle(size: 12).copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                                text: ' ${languages.requiredDocumentsMustBe}'),
                          ],
                        ),
                      ),
                      24.height,
                    ],

                    // Document list
                    if (isLoadingDocuments)
                      Center(child: LoaderWidget())
                          .paddingTop(context.height() * 0.2)
                    else if (documentList.isNotEmpty)
                      ...documentList.asMap().entries.map((entry) {
                        int index = entry.key;
                        DocumentItem data = entry.value;
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
                                  TextSpan(
                                      text: data.name,
                                      style: boldTextStyle(
                                          size: 14, weight: FontWeight.w500)),
                                  if (data.isRequired == 1 && !widget.isUpdate)
                                    TextSpan(
                                        text: ' *',
                                        style: primaryTextStyle(
                                            color: Colors.red, size: 14)),
                                  if (isUploaded)
                                    TextSpan(
                                        text: ' ✓',
                                        style: primaryTextStyle(
                                            color: Colors.green, size: 16)),
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
                                            image: (uploadedFile.path
                                                    .toLowerCase()
                                                    .contains('.pdf'))
                                                ? DecorationImage(
                                                    image:
                                                        AssetImage(img_files),
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                      black.withValues(
                                                          alpha: 0.6),
                                                      BlendMode.darken,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                : DecorationImage(
                                                    image:
                                                        FileImage(uploadedFile),
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                          child: (uploadedFile.path
                                                  .toLowerCase()
                                                  .contains('.pdf'))
                                              ? Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10),
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.only(
                                                          bottomLeft:
                                                              radiusCircular(
                                                                  defaultRadius),
                                                          bottomRight:
                                                              radiusCircular(
                                                                  defaultRadius))),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        uploadedFile.path
                                                            .split("/")
                                                            .last,
                                                        style: boldTextStyle(
                                                            color: white),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                      8.height,
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 16,
                                                                vertical: 6),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          color: context
                                                              .primaryColor,
                                                        ),
                                                        child: Text(
                                                            languages.viewPDF,
                                                            style:
                                                                boldTextStyle(
                                                                    color:
                                                                        white)),
                                                      ).onTap(() {
                                                        PdfViewerComponent(
                                                                pdfFile:
                                                                    uploadedFile
                                                                        .path,
                                                                isFile: true)
                                                            .launch(context);
                                                      }),
                                                    ],
                                                  ),
                                                )
                                              : Offstage(),
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(ic_documents,
                                                height: 58),
                                            18.height,
                                            RichText(
                                              text: TextSpan(
                                                style:
                                                    primaryTextStyle(size: 14),
                                                children: [
                                                  TextSpan(
                                                      text: languages
                                                          .dropYourFilesHereOr,
                                                      style: primaryTextStyle(
                                                          size: 14,
                                                          weight:
                                                              FontWeight.w500,
                                                          color: black)),
                                                  TextSpan(
                                                      text:
                                                          " ${languages.browse}",
                                                      style: boldTextStyle(
                                                          size: 14,
                                                          color: context
                                                              .primaryColor)),
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
                      }).toList()
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
            // Terms and conditions (only for new handyman)
            if (!widget.isUpdate) _buildTcAcceptWidget(),
            // Submit button
            Observer(
              builder: (_) => Container(
                margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: AppButton(
                  text: widget.isUpdate
                      ? languages.btnSave
                      : languages.lblAddHandyman,
                  height: 40,
                  color: appStore.isLoading
                      ? primaryColor.withValues(alpha: 0.5)
                      : primaryColor,
                  textStyle: boldTextStyle(color: white),
                  width: context.width() - 32,
                  onTap: () {
                    if (!appStore.isLoading) {
                      registerOrUpdate();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
