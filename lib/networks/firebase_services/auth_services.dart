import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../main.dart';
import '../../models/user_data.dart';
import '../../networks/rest_apis.dart';

class AuthService {

  Future<UserCredential> getFirebaseUser() async {

    UserCredential? userCredential;

    try {

      log("=========== FIREBASE LOGIN START ===========");

      log("EMAIL => ${appStore.userEmail}");

      log("USER TYPE => ${appStore.userType}");

      log("USER ID => ${appStore.userId}");

      log("============================================");

      /// LOGIN FIREBASE
      userCredential =
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(
        email: appStore.userEmail.trim(),
        password: DEFAULT_PASSWORD_FOR_FIREBASE,
      );

      log("=========== FIREBASE LOGIN SUCCESS =========");

      log("FIREBASE UID => ${userCredential.user?.uid}");

      log("============================================");

    } on FirebaseAuthException catch (e) {

      log("=========== FIREBASE LOGIN ERROR ===========");

      log("CODE => ${e.code}");

      log("MESSAGE => ${e.message}");

      log("============================================");

      /// USER NOT FOUND
      if (e.code == 'user-not-found') {

        log("=========== CREATING FIREBASE USER =========");

        userCredential =
            await FirebaseAuth.instance
                .createUserWithEmailAndPassword(
          email: appStore.userEmail.trim(),
          password: DEFAULT_PASSWORD_FOR_FIREBASE,
        );

        log("=========== FIREBASE USER CREATED ==========");

        log("FIREBASE UID => ${userCredential.user?.uid}");

        log("============================================");
      }

      /// INVALID OLD ACCOUNT
      else if (
      e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {

        log("=========== INVALID FIREBASE ACCOUNT =======");

        log("TRYING FRESH ACCOUNT");

        log("============================================");

        try {
          await FirebaseAuth.instance.currentUser?.delete();
        } catch (_) {}

        userCredential =
            await FirebaseAuth.instance
                .createUserWithEmailAndPassword(
          email: appStore.userEmail.trim(),
          password: DEFAULT_PASSWORD_FOR_FIREBASE,
        );

        log("=========== NEW FIREBASE ACCOUNT CREATED ===");

        log("FIREBASE UID => ${userCredential.user?.uid}");

        log("============================================");
      }
    }

    if (userCredential != null &&
        userCredential.user == null) {

      log("=========== USER NULL RETRY LOGIN ==========");

      userCredential =
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(
        email: appStore.userEmail.trim(),
        password: DEFAULT_PASSWORD_FOR_FIREBASE,
      );

      log("=========== RETRY LOGIN SUCCESS ============");

      log("FIREBASE UID => ${userCredential.user?.uid}");

      log("============================================");
    }

    if (userCredential != null) {
      return userCredential;
    } else {

      log("=========== FIREBASE LOGIN FAILED ==========");

      throw errorSomethingWentWrong;
    }
  }

  Future<void> verifyFirebaseUser() async {

    try {

      log("=========== VERIFY FIREBASE USER START =====");

      UserCredential userCredential =
      await getFirebaseUser();

      log("=========== FIREBASE VERIFIED ==============");

      log("FIREBASE UID => ${userCredential.user?.uid}");

      log("============================================");

      UserData userData = UserData();

      userData.id = appStore.userId;

      userData.email = appStore.userEmail;

      userData.firstName =
          appStore.userFirstName;

      userData.lastName =
          appStore.userLastName;

      userData.profileImage =
          appStore.userProfileImage;

      userData.updatedAt =
          Timestamp.now().toDate().toString();

      /// FIREBASE UID
      userData.uid =
          userCredential.user!.uid;

      log("=========== CHECKING FIRESTORE USER ========");

      bool isUserExistWithUid =
      await userService.isUserExistWithUid(
          userCredential.user!.uid);

      log("USER EXISTS => $isUserExistWithUid");

      log("============================================");

      /// CREATE FIRESTORE USER
      if (!isUserExistWithUid) {

        log("=========== CREATING FIRESTORE USER ========");

        userData.createdAt =
            Timestamp.now().toDate().toString();

        await userService.addDocumentWithCustomId(
          userCredential.user!.uid,
          userData.toFirebaseJson(),
        );

        log("=========== FIRESTORE USER CREATED =========");

      } else {

        log("=========== UPDATING FIRESTORE USER ========");

        await userService.updateDocument(
          userData.toFirebaseJson(),
          userCredential.user!.uid,
        );

        log("=========== FIRESTORE USER UPDATED =========");
      }

      log("============================================");

      /// UPDATE BACKEND
      updateProfile({
        'uid': userCredential.user!.uid,
      });

      log("=========== BACKEND UID UPDATED ============");

      /// SAVE FIREBASE UID
      await appStore.setUId(
          userCredential.user!.uid);

      log("=========== FIREBASE UID SAVED =============");

      log(appStore.uid);

      log("============================================");

      /// CHAT ID
      String myChatId = '';

      if (appStore.userType == 'provider') {

        myChatId =
        'provider_${appStore.userId}';

      } else {

        myChatId =
        'handyman_${appStore.userId}';
      }

      /// SAVE LOCAL CHAT ID
      await setValue(
          'my_chat_id',
          myChatId);

      log("=========== MY CHAT ID SAVED ===============");

      log(myChatId);

      log("============================================");

      /// VERIFY LOCAL STORAGE
      String savedChatId =
      getStringAsync('my_chat_id');

      log("=========== VERIFY LOCAL CHAT ID ===========");

      log(savedChatId);

      log("============================================");

    } catch (e) {

      log("=========== VERIFY FIREBASE USER ERROR =====");

      log(e.toString());

      log("============================================");
    }
  }
}