import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fig_style/components/delete_list_dialog.dart';
import 'package:fig_style/components/edit_list_dialog.dart';
import 'package:fig_style/components/sliver_edge_padding.dart';
import 'package:fig_style/components/sliver_empty_view.dart';
import 'package:fig_style/router/app_router.gr.dart';
import 'package:fig_style/types/edit_list_payload.dart';
import 'package:fig_style/utils/app_logger.dart';
import 'package:fig_style/utils/constants.dart';
import 'package:fig_style/utils/flash_helper.dart';
import 'package:flutter/material.dart';
import 'package:fig_style/actions/lists.dart';
import 'package:fig_style/components/error_container.dart';
import 'package:fig_style/components/page_app_bar.dart';
import 'package:fig_style/components/loading_animation.dart';
import 'package:fig_style/router/route_names.dart';
import 'package:fig_style/state/colors.dart';
import 'package:fig_style/state/user.dart';
import 'package:fig_style/types/user_quotes_list.dart';
import 'package:fig_style/utils/app_storage.dart';
import 'package:fig_style/utils/snack.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:supercharged/supercharged.dart';
import 'package:unicons/unicons.dart';

class QuotesLists extends StatefulWidget {
  @override
  _QuotesListsState createState() => _QuotesListsState();
}

class _QuotesListsState extends State<QuotesLists> {
  bool descending = true;
  bool hasErrors = false;
  bool hasNext = true;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool newIsPublic = false;
  bool updateListIsPublic = false;

  final pageRoute = RouteNames.ListsRoute;
  final scrollController = ScrollController();

  int limit = 10;

  List<UserQuotesList> userQuotesLists = [];

  DocumentSnapshot lastDoc;

  @override
  initState() {
    super.initState();
    fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showEditListDialog,
        child: Icon(Icons.add),
        backgroundColor: stateColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
          onRefresh: () async {
            await fetch();
            return null;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollNotif) {
              if (scrollNotif.metrics.pixels <
                  scrollNotif.metrics.maxScrollExtent) {
                return false;
              }

              if (hasNext && !isLoadingMore) {
                fetchMore();
              }

              return false;
            },
            child: CustomScrollView(
              controller: scrollController,
              slivers: <Widget>[
                SliverEdgePadding(),
                appBar(),
                body(),
              ],
            ),
          )),
    );
  }

  Widget appBar() {
    final width = MediaQuery.of(context).size.width;
    double titleLeftPadding = 70.0;
    double bottomContentLeftPadding = 94.0;

    if (width < Constants.maxMobileWidth) {
      titleLeftPadding = 0.0;
      bottomContentLeftPadding = 24.0;
    }

    return PageAppBar(
      textTitle: 'Lists',
      textSubTitle: 'Thematic lists created by you',
      titlePadding: EdgeInsets.only(
        left: titleLeftPadding,
      ),
      bottomPadding: EdgeInsets.only(
        left: bottomContentLeftPadding,
        bottom: 10.0,
      ),
      expandedHeight: 100.0,
      onTitlePressed: () {
        scrollController.animateTo(
          0,
          duration: 250.milliseconds,
          curve: Curves.easeIn,
        );
      },
      descending: descending,
      onDescendingChanged: (newDescending) {
        if (descending == newDescending) {
          return;
        }

        descending = newDescending;
        fetch();

        appStorage.setPageOrder(
          descending: newDescending,
          pageRoute: pageRoute,
        );
      },
    );
  }

  Widget body() {
    if (isLoading) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(top: 200.0),
            child: LoadingAnimation(),
          ),
        ]),
      );
    }

    if (!isLoading && hasErrors) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(top: 150.0),
            child: ErrorContainer(
              onRefresh: () => fetch(),
            ),
          ),
        ]),
      );
    }

    if (userQuotesLists.length == 0) {
      return emptyView();
    }

    return sliverQuotesList();
  }

  Widget cardListItem({
    @required int index,
    @required UserQuotesList quotesList,
    bool showPopupMenu = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 2.5,
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 500.0,
            child: SwipeActionCell(
              key: ObjectKey(index),
              performsFirstActionWithFullSwipe: true,
              leadingActions: [
                SwipeAction(
                  title: "edit",
                  color: Colors.blue,
                  icon: Icon(UniconsLine.edit, color: Colors.white),
                  onTap: (CompletionHandler handler) {
                    handler(false);
                    _showEditListDialog();
                  },
                ),
              ],
              trailingActions: [
                SwipeAction(
                  title: "delete",
                  color: stateColors.deletion,
                  icon: Icon(UniconsLine.trash, color: Colors.white),
                  onTap: (CompletionHandler handler) {
                    handler(false);

                    showDeleteListDialog(
                      context: context,
                      listName: quotesList.name,
                      onCancel: context.router.pop,
                      onConfirm: () {
                        context.router.pop();
                        deleteCurrentList(quotesList);
                      },
                    );
                  },
                ),
              ],
              child: cardListItemContent(
                quotesList,
                showPopupMenu,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget cardListItemContent(
    UserQuotesList quotesList,
    bool showPopupMenu,
  ) {
    return Card(
      elevation: 2.0,
      child: InkWell(
        onTap: () async {
          context.router.push(
            QuotesListRoute(
              listId: quotesList.id,
              onResult: (hasDeletedList) {
                if (!hasDeletedList) {
                  return;
                }

                setState(() {
                  userQuotesLists.remove(quotesList);
                });
              },
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Stack(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    radius: 20.0,
                    backgroundColor: Colors.black12,
                    child: Icon(Icons.list, color: Colors.white),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            quotesList.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20.0,
                            ),
                          ),
                          Opacity(
                            opacity: 0.6,
                            child: Text(
                              quotesList.description,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showPopupMenu) popupMenuButton(quotesList),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget popupMenuButton(UserQuotesList quotesList) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'delete') {
          showDeleteListDialog(
            context: context,
            listName: quotesList.name,
            onCancel: () => context.router.pop(),
            onConfirm: () {
              context.router.pop();
              deleteCurrentList(quotesList);
            },
          );
          return;
        }

        if (value == 'edit') {
          _showEditListDialog();
          return;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Delete'),
          ),
        ),
      ],
    );
  }

  Widget emptyView() {
    return SliverEmptyView(
      icon: Icon(
        UniconsLine.list_ui_alt,
        size: 100.0,
      ),
      titleString: "There's no list there",
      descriptionString: "You can create a new list "
          "by taping on the '+' button",
      onTapDescription: _showEditListDialog,
    );
  }

  Widget sliverQuotesList() {
    final showPopupMenu =
        MediaQuery.of(context).size.width > Constants.maxMobileWidth;

    return SliverPadding(
      padding: const EdgeInsets.only(top: 20.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final quotesList = userQuotesLists.elementAt(index);

            return cardListItem(
              index: index,
              quotesList: quotesList,
              showPopupMenu: showPopupMenu,
            );
          },
          childCount: userQuotesLists.length,
        ),
      ),
    );
  }

  void createNewList(EditListPayload payload) async {
    FlashHelper.showProgress(
      context,
      title: "Create",
      progressId: 'create_list',
      message: "Ceating list ${payload.name}...",
      icon: Icon(UniconsLine.plus),
      duration: 60.seconds,
    );

    final quotesList = await ListsActions.create(
      name: payload.name,
      description: payload.description,
      isPublic: payload.isPublic,
    );

    FlashHelper.dismissProgress(id: 'create_list');

    if (quotesList == null) {
      Snack.e(
        context: context,
        message: 'There was and issue while creating the list. Try again later',
      );

      return;
    }

    setState(() {
      userQuotesLists.add(quotesList);
    });
  }

  void deleteCurrentList(UserQuotesList quotesList) async {
    int index = userQuotesLists.indexOf(quotesList);

    setState(() {
      userQuotesLists.removeAt(index);
    });

    final success = await ListsActions.delete(id: quotesList.id);

    if (!success) {
      setState(() => userQuotesLists.insert(index, quotesList));

      Snack.e(
        context: context,
        message: 'There was and issue while deleting the list. Try again later',
      );

      return;
    }
  }

  Future fetch() async {
    setState(() {
      isLoading = true;
      userQuotesLists.clear();
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(stateUser.userAuth.uid)
          .collection('lists')
          .orderBy('updatedAt', descending: descending)
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          hasNext = false;
          isLoading = false;
        });

        return;
      }

      snapshot.docs.forEach((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        final quoteList = UserQuotesList.fromJSON(data);
        userQuotesLists.add(quoteList);
      });

      lastDoc = snapshot.docs.last;

      setState(() {
        hasNext = snapshot.docs.length == limit;
        isLoading = false;
      });
    } catch (error) {
      appLogger.e(error);
      setState(() => isLoading = false);
    }
  }

  void fetchMore() async {
    setState(() => isLoadingMore = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(stateUser.userAuth.uid)
          .collection('lists')
          .orderBy('updatedAt', descending: descending)
          .startAfterDocument(lastDoc)
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          hasNext = false;
          isLoadingMore = false;
        });

        return;
      }

      snapshot.docs.forEach((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        final quoteList = UserQuotesList.fromJSON(data);
        userQuotesLists.add(quoteList);
      });

      lastDoc = snapshot.docs.last;

      setState(() {
        hasNext = snapshot.docs.length == limit;
        isLoadingMore = false;
      });
    } catch (error) {
      debugPrint(error.toString());
      setState(() => isLoadingMore = false);
    }
  }

  void updateSelectedList(
    UserQuotesList quotesList,
    EditListPayload payload,
  ) async {
    final oldListDescription = quotesList.description;
    final oldListName = quotesList.name;
    final oldIsPublic = quotesList.isPublic;

    // Optimistic
    setState(() {
      quotesList.name = payload.name;
      quotesList.description = payload.description;
      quotesList.isPublic = payload.isPublic;
    });

    final success = await ListsActions.update(
      id: quotesList.id,
      name: payload.name,
      description: payload.description,
      isPublic: payload.isPublic,
      iconUrl: quotesList.iconUrl,
    );

    if (!success) {
      // Rollback
      setState(() {
        quotesList.description = oldListDescription;
        quotesList.name = oldListName;
        quotesList.isPublic = oldIsPublic;
      });

      Snack.e(
        context: context,
        message: "Sorry, could not update your list. Please try again later.",
      );

      return;
    }
  }

  Future _showEditListDialog() {
    return showEditListDialog(
      context: context,
      listDesc: '',
      listName: '',
      listIsPublic: false,
      textButtonConfirmation: "Create",
      title: "You'll be able to change these properties later",
      subtitle: 'Create a new list',
      onCancel: () => context.router.pop(),
      onConfirm: (payload) {
        context.router.pop();
        createNewList(payload);
      },
      onNameSubmitted: (payload) {
        context.router.pop();
        createNewList(payload);
      },
      onDescriptionSubmitted: (payload) {
        context.router.pop();
        createNewList(payload);
      },
    );
  }
}
