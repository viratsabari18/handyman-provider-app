import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';
import '../components/back_widget.dart';
import 'upload_documents_screen.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // TextEditing controllers
  TextEditingController fNameCont = TextEditingController();
  TextEditingController lNameCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  TextEditingController userNameCont = TextEditingController();
  TextEditingController mobileCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();
  TextEditingController designationCont = TextEditingController();

  // FocusNodes
  FocusNode fNameFocus = FocusNode();
  FocusNode lNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode mobileFocus = FocusNode();
  FocusNode userTypeFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode designationFocus = FocusNode();

  String? selectedUserTypeValue;
  bool isAcceptedTc = false;

  @override
  void initState() {
    super.initState();
  }

  // Method to log all user entered values
  void _logUserEnteredValues() {
    print('================== USER REGISTRATION DETAILS ==================');
    print('📝 First Name: ${fNameCont.text.trim()}');
    print('📝 Last Name: ${lNameCont.text.trim()}');
    print('📝 Username: ${userNameCont.text.trim()}');
    print('📝 Email: ${emailCont.text.trim()}');
    print('📝 Mobile: ${mobileCont.text.trim()}');
    print('📝 Password: ${'*' * passwordCont.text.length}');
    print(
        '👤 User Type: ${selectedUserTypeValue == USER_TYPE_PROVIDER ? "Provider" : "Handyman"}');
    print('💼 Designation: ${designationCont.text.trim()}');
    print('===============================================================');
  }

  @override
  void dispose() {
    fNameCont.dispose();
    lNameCont.dispose();
    emailCont.dispose();
    userNameCont.dispose();
    mobileCont.dispose();
    passwordCont.dispose();
    designationCont.dispose();
    fNameFocus.dispose();
    lNameFocus.dispose();
    emailFocus.dispose();
    userNameFocus.dispose();
    mobileFocus.dispose();
    userTypeFocus.dispose();
    passwordFocus.dispose();
    designationFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: Container(
            margin: EdgeInsets.only(left: 6),
            padding: EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: BackWidget(color: context.iconColor),
          ),
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness:
                appStore.isDarkMode ? Brightness.light : Brightness.dark,
            statusBarColor: context.scaffoldBackgroundColor,
          ),
        ),
        body: Form(
          key: formKey,
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTopWidget(),
                _buildFormWidget(),
                _buildFooterWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopWidget() {
    return Column(
      children: [
        (context.height() * 0.12).toInt().height,
        Container(
          width: 85,
          height: 85,
          decoration: boxDecorationWithRoundedCorners(
              boxShape: BoxShape.circle, backgroundColor: primaryColor),
          child: Image.asset(profile, height: 45, width: 45, color: white),
        ),
        16.height,
        Text(languages.lblSignupTitle, style: boldTextStyle(size: 18)),
        16.height,
        Text(
          languages.lblSignupSubtitle,
          style: secondaryTextStyle(size: 14),
          textAlign: TextAlign.center,
        ).paddingSymmetric(horizontal: 32),
        32.height,
      ],
    );
  }

  Widget _buildFormWidget() {
    return Column(
      children: [
        // First name
        AppTextField(
          textFieldType: TextFieldType.NAME,
          controller: fNameCont,
          focus: fNameFocus,
          nextFocus: lNameFocus,
          errorThisFieldRequired: languages.hintRequired,
          decoration:
              inputDecoration(context, hint: languages.hintFirstNameTxt),
          suffix: profile.iconImage(size: 10).paddingAll(14),
        ),
        16.height,

        // Last name
        AppTextField(
          textFieldType: TextFieldType.NAME,
          controller: lNameCont,
          focus: lNameFocus,
          nextFocus: userNameFocus,
          errorThisFieldRequired: languages.hintRequired,
          decoration: inputDecoration(context, hint: languages.hintLastNameTxt),
          suffix: profile.iconImage(size: 10).paddingAll(14),
        ),
        16.height,

        // Username
        AppTextField(
          textFieldType: TextFieldType.USERNAME,
          controller: userNameCont,
          focus: userNameFocus,
          nextFocus: emailFocus,
          errorThisFieldRequired: languages.hintRequired,
          decoration: inputDecoration(context, hint: languages.hintUserNameTxt),
          suffix: profile.iconImage(size: 10).paddingAll(14),
        ),
        16.height,

        // Email
        AppTextField(
          textFieldType: TextFieldType.EMAIL_ENHANCED,
          controller: emailCont,
          focus: emailFocus,
          nextFocus: mobileFocus,
          errorThisFieldRequired: languages.hintRequired,
          decoration:
              inputDecoration(context, hint: languages.hintEmailAddressTxt),
          suffix: ic_message.iconImage(size: 10).paddingAll(14),
        ),
        16.height,

        // Mobile number
        AppTextField(
          textFieldType: isAndroid ? TextFieldType.PHONE : TextFieldType.NAME,
          controller: mobileCont,
          focus: mobileFocus,
          errorThisFieldRequired: languages.hintRequired,
          nextFocus: passwordFocus,
          decoration:
              inputDecoration(context, hint: languages.hintContactNumberTxt),
          maxLength: 15,
          suffix: calling.iconImage(size: 10).paddingAll(14),
        ),
        8.height,

        // Designation
        AppTextField(
          textFieldType: TextFieldType.USERNAME,
          controller: designationCont,
          isValidationRequired: false,
          focus: designationFocus,
          nextFocus: passwordFocus,
          decoration: inputDecoration(context, hint: languages.lblDesignation),
          suffix: profile.iconImage(size: 10).paddingAll(14),
        ),
        16.height,

        // User Role Dropdown
        DropdownButtonFormField<String>(
          items: [
            DropdownMenuItem(
              child: Text(languages.provider, style: primaryTextStyle()),
              value: USER_TYPE_PROVIDER,
            ),
            DropdownMenuItem(
              child: Text(languages.handyman, style: primaryTextStyle()),
              value: USER_TYPE_HANDYMAN,
            ),
          ],
          focusNode: userTypeFocus,
          dropdownColor: context.cardColor,
          decoration: inputDecoration(context, hint: languages.userRole),
          value: selectedUserTypeValue,
          validator: (value) {
            if (value == null) return languages.hintRequired;
            return null;
          },
          onChanged: (c) {
            hideKeyboard(context);
            setState(() {
              selectedUserTypeValue = c.validate();
            });
          },
        ),

        16.height,

        // Password
        AppTextField(
          textFieldType: TextFieldType.PASSWORD,
          controller: passwordCont,
          focus: passwordFocus,
          obscureText: true,
          suffixPasswordVisibleWidget:
              ic_show.iconImage(size: 10).paddingAll(14),
          suffixPasswordInvisibleWidget:
              ic_hide.iconImage(size: 10).paddingAll(14),
          errorThisFieldRequired: languages.hintRequired,
          decoration: inputDecoration(context, hint: languages.hintPassword),
          isValidationRequired: true,
          validator: (val) {
            if (val == null || val.isEmpty) {
              return languages.hintRequired;
            } else if (val.length < 8 || val.length > 12) {
              return languages.passwordLengthShouldBe;
            }
            return null;
          },
        ),
        20.height,

        // Next Button
        AppButton(
          text: languages.lblNext,
          height: 40,
          color: primaryColor,
          textStyle: boldTextStyle(color: white),
          width: context.width() - context.navigationBarHeight,
          onTap: () async {
            if (formKey.currentState!.validate()) {
              if (selectedUserTypeValue == null) {
                toast(languages.userRole);
                return;
              }

              // Log all user entered values
              _logUserEnteredValues();

              // Prepare request map
              Map<String, dynamic> request = {
                'first_name': fNameCont.text.trim(),
                'last_name': lNameCont.text.trim(),
                'username': userNameCont.text.trim(),
                'email': emailCont.text.trim(),
                'mobile': mobileCont.text.trim(),
                'password': passwordCont.text.trim(),
                'user_type': selectedUserTypeValue,
                'designation': designationCont.text.trim(),
              };

              if (selectedUserTypeValue == USER_TYPE_PROVIDER) {
                // Provider: Navigate to UploadDocumentsScreen
                UploadDocumentsScreen(formRequest: request).launch(context,
                    pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
              } else {
                // Handyman: Navigate directly to SignInScreen
                toast("Registration successful! Please sign in.");
                push(SignInScreen(),
                    isNewTask: true,
                    pageRouteAnimation: PageRouteAnimation.Fade);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildFooterWidget() {
    return Column(
      children: [
        16.height,
        RichTextWidget(
          list: [
            TextSpan(
              text: "${languages.alreadyHaveAccountTxt}? ",
              style: secondaryTextStyle(),
            ),
            TextSpan(
              text: languages.signIn,
              style: boldTextStyle(color: primaryColor),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  finish(context);
                },
            ),
          ],
        ),
        30.height,
      ],
    );
  }
}
