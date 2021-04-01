import 'package:auto_route/auto_route.dart';
import 'package:fig_style/router/app_router.dart';
import 'package:fig_style/utils/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:fig_style/components/circle_button.dart';
import 'package:fig_style/components/app_icon.dart';
import 'package:fig_style/state/colors.dart';
import 'package:fig_style/state/user.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:unicons/unicons.dart';

class AddQuoteAppBar extends StatefulWidget {
  final Function onTapIconHeader;
  final String title;

  /// If specified, show an icon button which will show
  /// a bottom sheet containing this widget content.
  final Widget help;

  final bool isNarrow;
  final EdgeInsets padding;

  AddQuoteAppBar({
    this.help,
    this.isNarrow = false,
    this.onTapIconHeader,
    this.padding = EdgeInsets.zero,
    this.title = '',
  });

  @override
  _AddQuoteAppBarState createState() => _AddQuoteAppBarState();
}

class _AddQuoteAppBarState extends State<AddQuoteAppBar> {
  @override
  Widget build(BuildContext context) {
    final leftPadding = widget.isNarrow ? 0.0 : 60.0;

    return AppBar(
      backgroundColor: stateColors.appBackground.withOpacity(1.0),
      automaticallyImplyLeading: false,
      toolbarHeight: 80.0,
      title: Padding(
        padding: EdgeInsets.only(
          left: leftPadding,
        ),
        child: Row(
          children: <Widget>[
            if (context.router.root.stack.length > 1)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  color: stateColors.foreground,
                  onPressed: () => context.router.pop(),
                  icon: Icon(Icons.arrow_back),
                ),
              ),
            AppIcon(
              size: 40.0,
              padding: EdgeInsets.zero,
              onTap: () => context.router.root.navigate(HomeRoute()),
            ),
            if (widget.title.isNotEmpty) titleBar(isNarrow: widget.isNarrow),
          ],
        ),
      ),
      actions: [
        helpButton(),
        if (!widget.isNarrow) userMenu(widget.isNarrow),
      ],
    );
  }

  Widget helpButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: CircleButton(
        elevation: 2.0,
        backgroundColor: stateColors.softBackground,
        icon: Icon(
          UniconsLine.question,
          size: 20.0,
          color: stateColors.primary,
        ),
        onTap: () => showCupertinoModalBottomSheet(
          context: context,
          builder: (context) {
            final padding =
                MediaQuery.of(context).size.width < 600.0 ? 20.0 : 40.0;

            return Scaffold(
              body: SingleChildScrollView(
                controller: ModalScrollController.of(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(padding),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CircleButton(
                            onTap: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              size: 20.0,
                              color: stateColors.primary,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Help',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Opacity(
                                  opacity: 0.6,
                                  child: Text(
                                    'Some useful informaton about the current step',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 20.0,
                      thickness: 2.0,
                      color: stateColors.primary,
                    ),
                    Padding(
                      padding: EdgeInsets.all(padding),
                      child: widget.help,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget titleBar({bool isNarrow = false}) {
    return Container(
      padding: const EdgeInsets.only(left: 10.0),
      child: isNarrow
          ? Tooltip(
              message: widget.title,
              child: Opacity(
                opacity: 0.6,
                child: Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: stateColors.foreground,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : Opacity(
              opacity: 0.6,
              child: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: stateColors.foreground,
                ),
              ),
            ),
    );
  }

  Widget userAvatar({bool isNarrow = true}) {
    final arrStr = stateUser.username.split(' ');
    String initials = '';

    if (arrStr.length > 0) {
      initials = arrStr.length > 1
          ? arrStr.reduce((value, element) => value + element.substring(1))
          : arrStr.first;

      if (initials != null && initials.isNotEmpty) {
        initials = initials.substring(0, 1);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 20.0,
        right: 20.0,
      ),
      child: PopupMenuButton<PageRouteInfo>(
        icon: CircleAvatar(
          backgroundColor: stateColors.primary,
          radius: 20.0,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        onSelected: (pageRouteInfo) {
          if (pageRouteInfo.routeName == 'SignOutRoute') {
            stateUser.signOut(
              context: context,
              redirectOnComplete: true,
            );
            return;
          }

          context.router.root.navigate(pageRouteInfo);
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<PageRouteInfo>>[
          const PopupMenuItem(
              value: DashboardPageRoute(children: [FavouritesRoute()]),
              child: ListTile(
                leading: Icon(UniconsLine.heart),
                title: Text(
                  'Favourites',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )),
          const PopupMenuItem(
              value: DashboardPageRoute(children: [QuotesListsRoute()]),
              child: ListTile(
                leading: Icon(UniconsLine.list_ul),
                title: Text(
                  'Lists',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )),
          const PopupMenuItem(
            value: DashboardPageRoute(children: [DraftsRoute()]),
            child: ListTile(
              leading: Icon(UniconsLine.edit),
              title: Text(
                'Drafts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const PopupMenuItem(
            value: DashboardPageRoute(children: [MyPublishedQuotesRoute()]),
            child: ListTile(
              leading: Icon(UniconsLine.cloud_upload),
              title: Text(
                'Published',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const PopupMenuItem(
              value: DashboardPageRoute(children: [MyTempQuotesRoute()]),
              child: ListTile(
                leading: Icon(UniconsLine.clock),
                title: Text(
                  'In Validation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )),
          PopupMenuItem(
            value: NavigationHelper.getSettingsRoute(),
            child: ListTile(
              leading: Icon(UniconsLine.setting),
              title: Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const PopupMenuItem(
            value: SignOutRoute(),
            child: ListTile(
              leading: Icon(UniconsLine.ship),
              title: Text(
                'Sign out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget userMenu(bool isNarrow) {
    return Observer(builder: (context) {
      if (stateUser.isUserConnected) {
        return userAvatar(isNarrow: isNarrow);
      }

      return Padding(padding: EdgeInsets.zero);
    });
  }
}
