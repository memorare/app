import 'package:auto_route/auto_route.dart';
import 'package:fig_style/components/lang_popup_menu_button.dart';
import 'package:fig_style/router/app_router.gr.dart';
import 'package:fig_style/utils/app_logger.dart';
import 'package:fig_style/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:fig_style/components/base_page_app_bar.dart';
import 'package:fig_style/components/circle_button.dart';
import 'package:fig_style/components/app_icon.dart';
import 'package:fig_style/state/colors.dart';
import 'package:fig_style/types/enums.dart';
import 'package:unicons/unicons.dart';

class PageAppBar extends StatefulWidget {
  final bool alwaysHideNavBackIcon;
  final bool descending;

  /// If true, add a close button on the right.
  /// This property will override `showNavBackIcon` as its not conventional
  /// to show a navigation back button and a close button.
  final bool showCloseButton;

  final double expandedHeight;
  final double collapsedHeight;
  final double toolbarHeight;

  /// Title's padding. Used if textTitle is not null.
  final EdgeInsets titlePadding;

  /// Secondary content's padding.
  final EdgeInsets bottomPadding;

  final Function(bool) onDescendingChanged;
  final Function(String) onLangChanged;

  final void Function(ItemsLayout) onItemsLayoutSelected;
  final void Function() onIconPressed;
  final void Function() onTitlePressed;

  final ItemsLayout itemsLayout;

  /// Additional custom icon buttons.
  final List<Widget> additionalIconButtons;

  final String textTitle;
  final String textSubTitle;
  final String lang;

  /// App bar's title. Usually a Text widget.
  /// If set, 'textTitle' property will be ignored.
  final Widget title;

  const PageAppBar({
    Key key,
    this.additionalIconButtons = const [],
    this.alwaysHideNavBackIcon = false,
    this.bottomPadding = EdgeInsets.zero,
    this.collapsedHeight,
    this.descending = true,
    this.expandedHeight = 110.0,
    this.itemsLayout = ItemsLayout.list,
    this.lang = '',
    this.onDescendingChanged,
    this.onIconPressed,
    this.onItemsLayoutSelected,
    this.onLangChanged,
    this.onTitlePressed,
    this.showCloseButton = false,
    this.textTitle,
    this.textSubTitle,
    this.title,
    this.titlePadding = const EdgeInsets.only(top: 16.0),
    this.toolbarHeight,
  }) : super(key: key);

  @override
  _PageAppBarState createState() => _PageAppBarState();
}

class _PageAppBarState extends State<PageAppBar> {
  bool showNavBackIcon = false;

  @override
  initState() {
    super.initState();

    if (widget.onLangChanged != null &&
        (widget.lang == null || widget.lang.isEmpty)) {
      appLogger.d("Please specify a value for the 'lang' property.");
    }

    if (widget.onItemsLayoutSelected != null && widget.itemsLayout == null) {
      appLogger.d("Please specify a value for the 'itemsLayout' property.");
    }

    if (widget.onDescendingChanged != null && widget.descending == null) {
      appLogger.d("Please specify a value for the 'descending' property.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final showOrderButtons = widget.onDescendingChanged != null;
    final showLangSelector = widget.onLangChanged != null;
    final showItemsLayout = widget.onItemsLayoutSelected != null;

    if (!widget.alwaysHideNavBackIcon) {
      showNavBackIcon = context.router.root.stack.length > 1;
    } else {
      showNavBackIcon = false;
    }

    final isScreenSmall =
        MediaQuery.of(context).size.width < Constants.maxMobileWidth;

    return BasePageAppBar(
      expandedHeight: widget.expandedHeight,
      title: widget.textSubTitle != null ? twoLinesTitle() : oneLineTitle(),
      showNavBackIcon: showNavBackIcon,
      bottom: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: widget.bottomPadding,
          child: Wrap(
            spacing: 10.0,
            alignment: WrapAlignment.start,
            children: <Widget>[
              if (showOrderButtons) orderButton(),
              if (showLangSelector)
                LangPopupMenuButton(
                  opacity: 0.6,
                  lang: widget.lang,
                  padding: isScreenSmall
                      ? const EdgeInsets.only(top: 6.0)
                      : const EdgeInsets.only(top: 2.0),
                  onLangChanged: widget.onLangChanged,
                ),
              if (showItemsLayout) itemsLayoutSelector(),
              ...widget.additionalIconButtons,
            ],
          ),
        ),
      ),
    );
  }

  Widget itemsLayoutSelector() {
    final itemsLayout = widget.itemsLayout;
    final isListLayout = itemsLayout == ItemsLayout.list;

    return Opacity(
      opacity: 0.6,
      child: IconButton(
        tooltip: isListLayout ? "View in grid layout" : "View in list layout",
        icon: isListLayout ? Icon(UniconsLine.list_ul) : Icon(UniconsLine.grid),
        onPressed: () {
          final newItemsLayout = itemsLayout == ItemsLayout.list
              ? ItemsLayout.grid
              : ItemsLayout.list;
          widget.onItemsLayoutSelected(newItemsLayout);
        },
      ),
    );
  }

  Widget oneLineTitle() {
    if (widget.title != null) {
      return widget.title;
    }

    if (widget.showCloseButton) {
      return Padding(
        padding: widget.titlePadding,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    AppIcon(
                      padding: const EdgeInsets.only(
                        right: 8.0,
                      ),
                      size: 30.0,
                    ),
                    if (widget.textTitle != null)
                      Text(
                        widget.textTitle,
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 22.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                color: stateColors.foreground,
                icon: Icon(UniconsLine.times),
                onPressed: context.router.pop,
              ),
            ),
          ],
        ),
      );
    }

    if (showNavBackIcon) {
      return Padding(
        padding: widget.titlePadding,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleButton(
                onTap: context.router.pop,
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Icon(
                    UniconsLine.arrow_left,
                    color: stateColors.foreground,
                  ),
                ),
              ),
            ),
            AppIcon(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
              size: 30.0,
            ),
            if (widget.textTitle != null)
              Text(
                widget.textTitle,
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 22.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: widget.titlePadding,
      child: Row(
        children: [
          AppIcon(
            padding: const EdgeInsets.only(
              right: 8.0,
            ),
            size: 30.0,
          ),
          if (widget.textTitle != null)
            Text(
              widget.textTitle,
              style: TextStyle(
                color: Colors.blue,
                fontSize: 22.0,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget orderButton() {
    final descending = widget.descending;

    return Opacity(
      opacity: 0.6,
      child: IconButton(
        tooltip: descending ? "View last to first" : "View first to last",
        icon: descending
            ? Icon(UniconsLine.sort_amount_down)
            : Icon(UniconsLine.sort_amount_up),
        onPressed: () {
          widget.onDescendingChanged(!descending);
        },
      ),
    );
  }

  Widget separator() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 10.0,
        right: 10.0,
        top: 20.0,
      ),
      child: Container(
        width: 10.0,
        height: 10.0,
        decoration: BoxDecoration(
          color: stateColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget twoLinesTitle() {
    return Padding(
      padding: widget.titlePadding,
      child: Row(
        children: [
          if (showNavBackIcon)
            CircleButton(
              onTap: context.router.pop,
              icon: Padding(
                padding: const EdgeInsets.only(
                  bottom: 3.0,
                ),
                child: Icon(
                  UniconsLine.arrow_left,
                  color: stateColors.foreground,
                ),
              ),
            ),
          AppIcon(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
            ),
            size: 30.0,
            onTap: widget.onIconPressed ??
                () {
                  context.router.root.push(HomeRoute());
                },
          ),
          Expanded(
            child: InkWell(
              onTap: widget.onTitlePressed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.title != null)
                    widget.title
                  else if (widget.textTitle != null)
                    Text(
                      widget.textTitle,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: stateColors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Opacity(
                    opacity: 0.6,
                    child: Text(
                      widget.textSubTitle,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: stateColors.foreground,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showCloseButton)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                color: stateColors.foreground,
                icon: Icon(Icons.close),
                onPressed: context.router.pop,
              ),
            ),
        ],
      ),
    );
  }
}
