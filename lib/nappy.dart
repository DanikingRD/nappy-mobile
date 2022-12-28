import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nappy_mobile/constants/assets.dart';
import 'package:nappy_mobile/constants/colors.dart';
import 'package:nappy_mobile/constants/styles.dart';
import 'package:nappy_mobile/features/auth/controllers/auth_controller.dart';
import 'package:nappy_mobile/router.dart';
import 'package:routemaster/routemaster.dart';

class Nappy extends ConsumerWidget {
  const Nappy({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authEvents = ref.watch(authStateChangesProvider);
    return authEvents.when(
      data: (optionalId) {
        return MaterialApp.router(
          routeInformationParser: const RoutemasterParser(),
          routerDelegate: RoutemasterDelegate(
            routesBuilder: (context) {
              return optionalId.match(
                () => publicRoutes,
                (id) => appRoutes,
              );
            },
          ),
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: NappyColors.primary,
            ),
            inputDecorationTheme: kPrimaryInputDecorationTheme,
            scaffoldBackgroundColor: Colors.white,
            primaryIconTheme: kPrimaryIconTheme,
            iconTheme: kPrimaryIconTheme,
            fontFamily: kPoppinsFont,
            textTheme: TextTheme(
              headline1: kHeadline1,
              subtitle1: kSubtitle1,
              bodyText1: kBodyText1,
            ),
            textSelectionTheme: kTextSelectionTheme,
          ),
          debugShowCheckedModeBanner: false,
        );
      },
      error: (error, stack) => Scaffold(
        body: Center(child: Text(error.toString())),
      ),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class ExtendedScrollBehaviour extends ScrollBehavior {
  const ExtendedScrollBehaviour();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}