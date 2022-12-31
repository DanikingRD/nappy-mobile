import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:nappy_mobile/common/exceptions/backend_error_mapping.dart';
import 'package:nappy_mobile/common/util/connection.dart';
import 'package:nappy_mobile/common/util/extensions.dart';
import 'package:nappy_mobile/common/util/logger.dart';
import 'package:nappy_mobile/common/util/notification.dart';
import 'package:nappy_mobile/common/value/value_helper.dart';
import 'package:nappy_mobile/common/widgets/dialog_box.dart';
import 'package:nappy_mobile/common/widgets/toast.dart';
import 'package:nappy_mobile/features/auth/states/signup_form.dart';
import 'package:nappy_mobile/models/user.dart';
import 'package:nappy_mobile/repositories/impl/auth_repository.dart';
import 'package:nappy_mobile/repositories/impl/user_repository.dart';
import 'package:nappy_mobile/repositories/interfaces/auth_facade.dart';

final signUpControllerProvider = StateNotifierProvider<SignUpController, SignUpForm>(
  (ref) {
    return SignUpController(
      authRepository: ref.read(authRepositoryProvider),
      ref: ref,
      logger: NappyLogger.getLogger((SignUpController).toString()),
    );
  },
  name: (SignUpController).toString(),
);

class SignUpController extends StateNotifier<SignUpForm> {
  final IAuthRepositoryFacade _authRepository;
  final Ref _ref;
  final NappyLogger _logger;

  SignUpController({
    required IAuthRepositoryFacade authRepository,
    required Ref ref,
    required NappyLogger logger,
  })  : _authRepository = authRepository,
        _ref = ref,
        _logger = logger,
        super(SignUpForm.empty());

  Future<Unit> register(BuildContext context) async {
    final connection = await handleConnectionError(context);
    if (!connection) {
      return unit;
    }
    final email = ValueHelper.handleEmail(
      context: context,
      email: state.email,
      logger: _logger,
    );
    final password = ValueHelper.handlePassword(
      context: context,
      password: state.password,
      logger: _logger,
    );
    final passwordVerification = ValueHelper.handlePassword(
      context: context,
      password: state.passwordVerification,
      logger: _logger,
      verification: true,
    );

    // Fast return if any of the inputs are invalid
    if (email.isNone() || password.isNone()) {
      return unit;
    }
    if (passwordVerification.isNone() || password != passwordVerification) {
      DialogBox.show(
        context: context,
        title: "Password Field",
        content: "Your passwords do not match.",
        continueText: "Continue",
        type: NotificationType.error,
      );
      return unit;
    }
    if (!state.agreeTerms) {
      showToast(
        message: "You must accept the Terms of Service to create an account.",
        type: NotificationType.info,
        context: context,
      );
      return unit;
    }
    final emailVal = email.getOrThrow();
    final passwordVal = password.getOrThrow();
    setLoading();
    final result = await _authRepository.register(
      email: emailVal,
      password: passwordVal,
    );
    result.match(
      (backendError) {
        setIdle();
        handleError(backendError, context);
      },
      (user) {
        // Not need to call setIdle() here as the view is automatically redirected
        // to the home page before it even runs. 
        // Otherwise it will throw an error saying that the widget was disposed..
      },
    );
    setIdle();
    return unit;
  }

  /// Update the user provider
  void setActiveUser(User user) {
    _ref.read(userProvider.notifier).update((state) => Option.of(user));
  }

  void handleError(BackendError e, BuildContext ctx) {
    DialogBox.show(
      context: ctx,
      title: e.title,
      content: e.description,
      continueText: "GOT IT",
      type: NotificationType.error,
    );
  }

  void handleSuccess(BuildContext context) {
    DialogBox.show(
      context: context,
      title: "Great!",
      content: "Your account has been created successfully.",
      continueText: "Start Exploring Nappy",
      type: NotificationType.success,
    );
  }

  void onEmailUpdate(String? email) {
    state = state.copyWith(email: email);
  }

  void onPasswordUpdate(String? pw) {
    state = state.copyWith(password: pw);
  }

  void onVerifyPasswordUpdate(String? pw) {
    state = state.copyWith(passwordVerification: pw);
  }

  void setLoading() {
    state = state.copyWith(loading: true);
  }

  void setIdle() {
    state = state.copyWith(loading: false);
  }

  void setAgreeTerms(bool? val) {
    // If Checkbox is not disabled
    if (val != null) {
      state = state.copyWith(agreeTerms: val);
    }
  }
}
