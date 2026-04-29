import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/Models%20new/user_model.dart';
import 'package:handyman_provider_flutter/auth/component/user_demo_mode_screen.dart';
import 'package:handyman_provider_flutter/auth/forgot_password_dialog.dart';
import 'package:handyman_provider_flutter/auth/sign_up_screen.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/selected_item_widget.dart';
import 'package:handyman_provider_flutter/controllers/auth_controller.dart';
import 'package:handyman_provider_flutter/handyman/handyman_dashboard_screen.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/user_data.dart';
import 'package:handyman_provider_flutter/provider/provider_dashboard_screen.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';

import '../networks/rest_apis.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  //-------------------------------- Variables -------------------------------//

  /// TextEditing controller
  TextEditingController emailCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();

  /// FocusNodes
  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();

  /// FormKey
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// AutoValidate mode
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

  bool isRemember = getBoolAsync(IS_REMEMBERED);

  // Add this for error handling
  String? loginError;
  bool isLoginError = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
    emailCont.dispose();
    passwordCont.dispose();
    passwordFocus.dispose();
    emailFocus.dispose();
  }

  void init() async {
    if (await isIqonicProduct) {
      emailCont.text = getStringAsync(USER_EMAIL);
      passwordCont.text = getStringAsync(USER_PASSWORD);
      setState(() {});
    }
  }

  // Helper method to clear login error
  void _clearLoginError() {
    if (isLoginError) {
      setState(() {
        loginError = null;
        isLoginError = false;
      });
    }
  }

  //------------------------------------ UI ----------------------------------//

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: SizedBox(
          height: context.height(),
          width: context.width(),
          child: Stack(
            children: [
              Form(
                key: formKey,
                autovalidateMode: autovalidateMode,
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppBar().preferredSize.height),
                      // Hello again with Welcome text
                      _buildHelloAgainWithWelcomeText(),

                      // Display login error message if any
                      if (loginError != null)
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
                                  loginError!,
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),

                      AutofillGroup(
                        onDisposeAction: AutofillContextAction.commit,
                        child: Column(
                          children: [
                            // Enter email text field.
                            AppTextField(
                              textFieldType: TextFieldType.EMAIL_ENHANCED,
                              controller: emailCont,
                              focus: emailFocus,
                              autoFocus: true,
                              nextFocus: passwordFocus,
                              errorThisFieldRequired: languages.hintRequired,
                              decoration: inputDecoration(context,
                                  hint: languages.hintEmailAddressTxt),
                              suffix:
                                  ic_message.iconImage(size: 10).paddingAll(14),
                              autoFillHints: [AutofillHints.email],
                              onChanged: (value) => _clearLoginError(), // Clear error on typing
                              onFieldSubmitted: (val) => FocusScope.of(context)
                                  .requestFocus(passwordFocus),
                            ),
                            16.height,
                            // Enter password text field
                            AppTextField(
                              textFieldType: TextFieldType.PASSWORD,
                              controller: passwordCont,
                              focus: passwordFocus,
                              obscureText: true,
                              errorThisFieldRequired: languages.hintRequired,
                              suffixPasswordVisibleWidget:
                                  ic_show.iconImage(size: 10).paddingAll(14),
                              suffixPasswordInvisibleWidget:
                                  ic_hide.iconImage(size: 10).paddingAll(14),
                              errorMinimumPasswordLength:
                                  "${languages.errorPasswordLength} $passwordLengthGlobal",
                              decoration: inputDecoration(context,
                                  hint: languages.hintPassword),
                              autoFillHints: [AutofillHints.password],
                              isValidationRequired: true,
                              onChanged: (value) => _clearLoginError(), // Clear error on typing
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return languages.hintRequired;
                                } else if (val.length < 8 || val.length > 12) {
                                  return languages.passwordLengthShouldBe;
                                }
                                return null;
                              },
                              onFieldSubmitted: (s) {
                                _handleLogin();
                              },
                            ),
                            8.height,
                          ],
                        ),
                      ),

                      _buildForgotRememberWidget(),
                      _buildButtonWidget(),
                      16.height,
                      SnapHelperWidget<bool>(
                        future: isIqonicProduct,
                        onSuccess: (data) {
                          if (data) {
                            return UserDemoModeScreen(
                              onChanged: (email, password) {
                                if (email.isNotEmpty && password.isNotEmpty) {
                                  setState(() {
                                    emailCont.text = email;
                                    passwordCont.text = password;
                                    loginError = null; // Clear error when demo user selected
                                    isLoginError = false;
                                  });
                                } else {
                                  setState(() {
                                    emailCont.clear();
                                    passwordCont.clear();
                                    loginError = null; // Clear error when clearing
                                    isLoginError = false;
                                  });
                                }
                              },
                            );
                          }
                          return Offstage();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Observer(
                builder: (_) =>
                    LoaderWidget().center().visible(appStore.isLoading),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //region Widgets
  Widget _buildHelloAgainWithWelcomeText() {
    return Column(
      children: [
        32.height,
        Text(languages.lblLoginTitle, style: boldTextStyle(size: 18)).center(),
        16.height,
        Text(
          languages.lblLoginSubtitle,
          style: secondaryTextStyle(size: 14),
          textAlign: TextAlign.center,
        ).paddingSymmetric(horizontal: 32).center(),
        64.height,
      ],
    );
  }

  Widget _buildForgotRememberWidget() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                2.width,
                SelectedItemWidget(isSelected: isRemember).onTap(() async {
                  await setValue(IS_REMEMBERED, isRemember);
                  isRemember = !isRemember;
                  setState(() {});
                }),
                TextButton(
                  onPressed: () async {
                    await setValue(IS_REMEMBERED, isRemember);
                    isRemember = !isRemember;
                    setState(() {});
                  },
                  child:
                      Text(languages.rememberMe, style: secondaryTextStyle()),
                ),
              ],
            ),
            TextButton(
              child: Text(
                languages.forgotPassword,
                style: boldTextStyle(
                    color: primaryColor, fontStyle: FontStyle.italic),
                textAlign: TextAlign.right,
              ),
              onPressed: () {
                showInDialog(
                  context,
                  contentPadding: EdgeInsets.zero,
                  builder: (_) => ForgotPasswordScreen(),
                );
              },
            ).flexible()
          ],
        ),
        32.height,
      ],
    );
  }

  Widget _buildButtonWidget() {
    return Column(
      children: [
        AppButton(
          text: languages.signIn,
          height: 40,
          color: primaryColor,
          textStyle: boldTextStyle(color: white),
          width: context.width() - context.navigationBarHeight,
          onTap: () {
            _handleLogin();
          },
        ),
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(languages.doNotHaveAccount, style: secondaryTextStyle()),
            TextButton(
              onPressed: () {
                // Clear error when navigating to sign up
                setState(() {
                  loginError = null;
                  isLoginError = false;
                });
                SignUpScreen().launch(context);
              },
              child: Text(
                languages.signUp,
                style: boldTextStyle(
                  color: primaryColor,
                  decoration: TextDecoration.underline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  void _handleLogin() {
    hideKeyboard(context);
    // Clear previous errors before validation
    setState(() {
      loginError = null;
      isLoginError = false;
    });
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      _handleLoginUsers();
    }
  }

  void _handleLoginUsers() async {
    hideKeyboard(context);

    appStore.setLoading(true);
    try {
      final controller = AuthController();

      final user = await controller.login(
        email: emailCont.text.trim(),
        password: passwordCont.text.trim(),
      );

      if (user == null) {
        // Show user-friendly error message
        setState(() {
          loginError = "Invalid email or password";
          isLoginError = true;
        });
        appStore.setLoading(false);
        // Clear password field on failed login for security
        passwordCont.clear();
        // Request focus on password field for retry
        FocusScope.of(context).requestFocus(passwordFocus);
        return;
      }

      // if (user.status != 1) {
      //   toast("Contact admin");
      //   return;
      // }

      /// SAVE TOKEN
      await setValue("TOKEN", user.apiToken ?? "");

      // if (user.status != 1) {
      //   appStore.setLoading(false);
      //   return toast(languages.pleaseContactYourAdmin);
      // }

      await setValue(USER_PASSWORD, passwordCont.text);
      await setValue(IS_REMEMBERED, isRemember);
      // await saveUserData(user);
      await saveLoginUserData(user);

      // authService.verifyFirebaseUser();

      // Clear password after successful login
      passwordCont.clear();

      redirectWidget(res: user);
    } catch (e) {
      appStore.setLoading(false);
      
      // Parse and display appropriate error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceAll('Exception:', '').trim();
      }
      
      // Show specific error messages based on error content
      if (errorMessage.toLowerCase().contains('email') || 
          errorMessage.toLowerCase().contains('not found')) {
        setState(() {
          loginError = "Email address not found";
          isLoginError = true;
        });
      } else if (errorMessage.toLowerCase().contains('password') || 
                 errorMessage.toLowerCase().contains('credential')) {
        setState(() {
          loginError = "Incorrect password. Please try again.";
          isLoginError = true;
        });
      } else {
        setState(() {
          loginError = errorMessage;
          isLoginError = true;
        });
      }
      
      // Clear password field on error for security
      passwordCont.clear();
      // Request focus on password field for retry
      FocusScope.of(context).requestFocus(passwordFocus);
      
      toast(e.toString());
    }
  }

 void redirectWidget({required UserModel res}) async {
  appStore.setLoading(false);

  /// SAVE TOKEN
  await appStore.setToken(res.apiToken ?? "");

  /// 🔥 IGNORE STATUS
  if (res.userType == USER_TYPE_PROVIDER) {
    ProviderDashboardScreen().launch(context, isNewTask: true);
  } else if (res.userType == USER_TYPE_HANDYMAN) {
    HandymanDashboardScreen().launch(context, isNewTask: true);
  } else {
    toast("Invalid user type");
  }
}

  // void redirectWidget({required UserModel res}) async {
  //   appStore.setLoading(false);
  //   TextInput.finishAutofillContext();

  //   if (res.status.validate() == 1) {
  //     await appStore.setToken(res.apiToken.validate());
  //     appStore.setTester(res.email == DEFAULT_PROVIDER_EMAIL ||
  //         res.email == DEFAULT_HANDYMAN_EMAIL);

  //     if (res.userType.validate().trim() == USER_TYPE_PROVIDER) {
  //       HandymanDashboardScreen(index: 0).launch(context,
  //           isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
  //     } else if (res.userType.validate().trim() == USER_TYPE_HANDYMAN) {
  //       HandymanDashboardScreen().launch(context,
  //           isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
  //     } else {
  //       toast(languages.cantLogin, print: true);
  //     }
  //   } else {
  //     toast(languages.lblWaitForAcceptReq);
  //   }
  // }

  //endregion

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }
}