import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:figstyle/components/tile_button.dart';
import 'package:figstyle/router/app_router.gr.dart';
import 'package:figstyle/screens/notifications_center.dart';
import 'package:figstyle/state/topics_colors.dart';
import 'package:figstyle/types/topic_color.dart';
import 'package:figstyle/utils/constants.dart';
import 'package:figstyle/utils/navigation_helper.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:figstyle/components/base_page_app_bar.dart';
import 'package:figstyle/components/app_icon.dart';
import 'package:figstyle/components/data_quote_inputs.dart';
import 'package:figstyle/state/colors.dart';
import 'package:figstyle/state/user.dart';
import 'package:figstyle/utils/app_storage.dart';
import 'package:figstyle/utils/snack.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';
import 'package:unicons/unicons.dart';

class DashboardMobileTab extends StatefulWidget {
  @override
  _DashboardMobileTabState createState() => _DashboardMobileTabState();
}

class _DashboardMobileTabState extends State<DashboardMobileTab> {
  bool prevIsAuthenticated = false;
  bool isAccountAdvVisible = false;
  bool showNotifiBadge = false;

  double beginY = 20.0;

  final scrollController = ScrollController();

  int unreadNotifiCount = 0;
  StreamSubscription<DocumentSnapshot> userSubscription;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    userSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Observer(builder: (context) {
        if (!stateUser.isUserConnected) {
          return Container();
        }

        return FloatingActionButton.extended(
          backgroundColor: stateColors.accent,
          foregroundColor: Colors.white,
          label: Text(
            "Add quote",
            style: TextStyle(
              fontSize: 17.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: Icon(Icons.add),
          onPressed: () {
            DataQuoteInputs.clearAll();

            context.router.root.push(
              DashboardPageRoute(
                children: [
                  AddQuoteStepsRoute(),
                ],
              ),
            );
          },
        );
      }),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          appBar(),
          body(),
        ],
      ),
    );
  }

  Widget aboutButton() {
    return TileButton(
      iconData: UniconsLine.question,
      textTitle: 'About',
      onTap: () {
        context.router.push(AboutRoute());
      },
    );
  }

  List<Widget> adminWidgets(BuildContext context) {
    return [
      CustomAnimation(
        duration: 250.milliseconds,
        tween: Tween(begin: 0.0, end: MediaQuery.of(context).size.width),
        child: Divider(
          thickness: 1.0,
          height: 30.0,
        ),
        builder: (_, child, value) {
          return SizedBox(
            width: value,
            child: child,
          );
        },
      ),
      TileButton(
        iconData: UniconsLine.clock,
        textTitle: 'Admin validation',
        onTap: () {
          context.router.push(
            DashboardPageRoute(
              children: [
                AdminDeepRoute(
                  children: [
                    AdminTempDeepRoute(
                      children: [AdminTempQuotesRoute()],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      TileButton(
        iconData: UniconsLine.sunset,
        textTitle: 'Quotidians',
        onTap: () {
          context.router.push(
            DashboardPageRoute(
              children: [
                AdminDeepRoute(
                  children: [QuotidiansRoute()],
                ),
              ],
            ),
          );
        },
      ),
    ];
  }

  Widget appBar() {
    final width = MediaQuery.of(context).size.width;
    double horizontal = width < Constants.maxMobileWidth ? 0.0 : 70.0;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      sliver: BasePageAppBar(
        pinned: true,
        collapsedHeight: 70.0,
        expandedHeight: 90.0,
        title: Padding(
          padding: const EdgeInsets.only(
            top: 24.0,
            left: 16.0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      scrollController.animateTo(
                        0,
                        duration: 250.milliseconds,
                        curve: Curves.easeIn,
                      );
                    },
                    icon: AppIcon(
                      padding: EdgeInsets.zero,
                      size: 30.0,
                    ),
                    label: Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 22.0,
                      ),
                    ),
                  ),
                ),
              ),
              notificationsIconButton(),
            ],
          ),
        ),
        showNavBackIcon: false,
      ),
    );
  }

  List<Widget> authWidgets(BuildContext context) {
    return [
      Column(
        children: <Widget>[
          draftsButton(),
          listsButton(),
          tempQuotesButton(),
          favButton(),
          pubQuotesButton(),
          shuffeColorButton(),
          settingsButton(),
          signOutButton(),
          aboutButton(),
        ],
      ),
    ];
  }

  Widget body() {
    final width = MediaQuery.of(context).size.width;
    double horizontal = width < Constants.maxMobileWidth ? 0.0 : 70.0;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      sliver: Observer(builder: (context) {
        List<Widget> children = [];

        if (stateUser.isUserConnected) {
          children.addAll(authWidgets(context));

          if (stateUser.canManageQuotes) {
            children.addAll(adminWidgets(context));
          }
        } else {
          userSubscription?.cancel();
          children.add(whyAccountBlock());
          children.addAll(guestWidgets(context));
        }

        return SliverPadding(
          padding: const EdgeInsets.only(
            bottom: 150.0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              )
            ]),
          ),
        );
      }),
    );
  }

  Widget bulletPoint({String text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Opacity(
        opacity: 0.5,
        child: Row(
          children: [
            Icon(UniconsLine.check),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget draftsButton() {
    return TileButton(
      iconData: UniconsLine.edit,
      textTitle: 'Drafts',
      onTap: () {
        context.router.push(
          DashboardPageRoute(
            children: [DraftsRoute()],
          ),
        );
      },
    );
  }

  Widget favButton() {
    return TileButton(
      iconData: UniconsLine.heart,
      textTitle: 'Favourites',
      onTap: () {
        context.router.push(
          DashboardPageRoute(
            children: [FavouritesRoute()],
          ),
        );
      },
    );
  }

  List<Widget> guestWidgets(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 40.0,
        ),
        child: Column(
          children: [
            signinButton(),
            signupButton(),
          ],
        ),
      ),
      Divider(
        height: 100.0,
        thickness: 1.0,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          shuffeColorButton(),
          settingsButton(),
          aboutButton(),
        ],
      ),
    ];
  }

  Widget signOutButton() {
    return TileButton(
      iconData: UniconsLine.signout,
      textTitle: 'Sign out',
      onTap: () async {
        await appStorage.clearUserAuthData();
        await stateUser.signOut();

        Snack.s(
          context: context,
          message: 'You have been successfully disconnected.',
        );
      },
    );
  }

  Widget listsButton() {
    return TileButton(
      iconData: UniconsLine.list_ul,
      textTitle: 'Lists',
      onTap: () {
        context.router.push(
          DashboardPageRoute(
            children: [
              QuotesListsDeepRoute(),
            ],
          ),
        );
      },
    );
  }

  Widget notificationsIconButton() {
    return Observer(
      builder: (context) {
        if (!stateUser.isUserConnected) {
          return Container();
        }

        return Padding(
          padding: const EdgeInsets.only(
            top: 8.0,
            right: 32.0,
          ),
          child: Badge(
            badgeContent: Text(
              "$unreadNotifiCount",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            showBadge: showNotifiBadge,
            child: IconButton(
              onPressed: () async {
                final size = MediaQuery.of(context).size;

                if (size.width > Constants.maxMobileWidth &&
                    size.height > Constants.maxMobileWidth) {
                  await showFlash(
                    context: context,
                    persistent: false,
                    builder: (context, controller) {
                      return Flash.dialog(
                        controller: controller,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        enableDrag: true,
                        margin: const EdgeInsets.only(
                          left: 120.0,
                          right: 120.0,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                        child: FlashBar(
                          message: Container(
                            height: MediaQuery.of(context).size.height - 100.0,
                            padding: const EdgeInsets.all(60.0),
                            child: NotificationsCenter(),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  await showCupertinoModalBottomSheet(
                    context: context,
                    builder: (_) => NotificationsCenter(
                      scrollController: scrollController,
                    ),
                  );
                }
              },
              color: stateColors.foreground,
              tooltip: "My notifications",
              icon: Icon(UniconsLine.bell),
            ),
          ),
        );
      },
    );
  }

  Widget pubQuotesButton() {
    return TileButton(
      iconData: UniconsLine.upload,
      textTitle: 'Published',
      onTap: () {
        context.router.push(
          DashboardPageRoute(
            children: [MyPublishedQuotesRoute()],
          ),
        );
      },
    );
  }

  Widget settingsButton() {
    return TileButton(
      iconData: UniconsLine.setting,
      textTitle: 'Settings',
      onTap: () {
        context.router.push(
          NavigationHelper.getSettingsRoute(showAppBar: true),
        );
      },
    );
  }

  Widget shuffeColorButton() {
    return TileButton(
      iconData: UniconsLine.paint_tool,
      textTitle: 'Shuffle accent color',
      trailing: Padding(
        padding: const EdgeInsets.only(
          right: 24.0,
        ),
        child: ClipOval(
          child: Material(
            color: stateColors.accent,
            child: SizedBox(
              width: 15,
              height: 15,
            ),
          ),
        ),
      ),
      onTap: () {
        final color = appTopicsColors.shuffle(max: 1).firstOrElse(
              () => TopicColor(
                name: 'blue',
                decimal: Colors.blue.value,
                hex: Colors.blue.value.toRadixString(16),
              ),
            );

        stateColors.setAccentColor(Color(color.decimal));

        Snack.s(
          context: context,
          message: "A new accent color has been selected.",
        );

        setState(() {});
      },
    );
  }

  Widget signinButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: TextButton(
        onPressed: () {
          context.router.push(SigninRoute());
        },
        style: TextButton.styleFrom(
          textStyle: TextStyle(
            color: stateColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
            side: BorderSide(
              color: stateColors.primary,
              width: 2.0,
            ),
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 220.0,
            minHeight: 60.0,
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'SIGN IN',
                  style: TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Icon(Icons.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget signupButton() {
    return TextButton(
      onPressed: () {
        context.router.push(SignupRoute());
      },
      style: TextButton.styleFrom(
        textStyle: TextStyle(
          color: stateColors.secondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
          side: BorderSide(
            color: Colors.orange.shade600,
            width: 2.0,
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 220.0,
          minHeight: 60.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'SIGN UP',
                style: TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Icon(UniconsLine.user_plus),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget tempQuotesButton() {
    return TileButton(
      iconData: UniconsLine.clock,
      textTitle: 'In validation',
      onTap: () {
        context.router.push(
          DashboardPageRoute(
            children: [MyTempQuotesRoute()],
          ),
        );
      },
    );
  }

  Widget whyAccountBlock() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 30.0,
        bottom: 30.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: () =>
                setState(() => isAccountAdvVisible = !isAccountAdvVisible),
            child: Opacity(
              opacity: 0.6,
              child: Text(
                'Why create an account?',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (isAccountAdvVisible)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(top: 10.0)),
                  bulletPoint(text: 'Favourites quotes'),
                  bulletPoint(text: 'Create thematic lists'),
                  bulletPoint(text: 'Propose new quotes'),
                  bulletPoint(text: '& more...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future fetchUserData() async {
    try {
      final userAuth = stateUser.userAuth;

      if (userAuth == null) {
        return;
      }

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userAuth.uid)
          .get();

      if (!userSnapshot.exists) {
        debugPrint("The user with the id ${userAuth.uid}"
            " doesn't exist anymore.");

        return;
      }

      userSubscription = userSnapshot.reference.snapshots().listen(
        (documentSnapshot) {
          final data = documentSnapshot.data();
          if (data == null) {
            userSubscription.cancel();
            return;
          }

          setState(() {
            unreadNotifiCount = data['stats']['notifications']['unread'];
            showNotifiBadge = unreadNotifiCount > 0;
          });
        },
        onError: (error, stacktrace) {
          debugPrint(error.toString());

          if (stacktrace != null) {
            debugPrint(stacktrace.toString());
          }
        },
      );
    } on Exception catch (error) {
      debugPrint(error.toString());
    }
  }
}
