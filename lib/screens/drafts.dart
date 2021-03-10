import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figstyle/components/sliver_edge_padding.dart';
import 'package:figstyle/components/sliver_empty_view.dart';
import 'package:figstyle/router/app_router.gr.dart';
import 'package:figstyle/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:figstyle/actions/drafts.dart';
import 'package:figstyle/components/error_container.dart';
import 'package:figstyle/components/loading_animation.dart';
import 'package:figstyle/components/page_app_bar.dart';
import 'package:figstyle/components/temp_quote_row_with_actions.dart';
import 'package:figstyle/components/data_quote_inputs.dart';
import 'package:figstyle/router/route_names.dart';
import 'package:figstyle/state/colors.dart';
import 'package:figstyle/state/user.dart';
import 'package:figstyle/types/enums.dart';
import 'package:figstyle/types/temp_quote.dart';
import 'package:figstyle/utils/app_storage.dart';
import 'package:figstyle/utils/snack.dart';
import 'package:supercharged/supercharged.dart';
import 'package:unicons/unicons.dart';

class Drafts extends StatefulWidget {
  @override
  _DraftsState createState() => _DraftsState();
}

class _DraftsState extends State<Drafts> {
  bool descending = true;
  bool hasNext = true;
  bool hasErrors = false;
  bool isLoading = false;
  bool isLoadingMore = false;

  DocumentSnapshot lastDoc;

  int limit = 30;
  int order = -1;

  ItemsLayout itemsLayout = ItemsLayout.list;

  List<TempQuote> drafts = [];
  List<TempQuote> offlineDrafts = [];

  /// Quotes which are being deleted.
  /// Useful reference if a rollback is necessary.
  Map<int, TempQuote> processingQuotes = Map();

  ScrollController scrollController = ScrollController();
  final String pageRoute = RouteNames.DraftsRoute;

  @override
  void initState() {
    super.initState();
    initProps();
    fetch();
  }

  void initProps() {
    descending = appStorage.getPageOrder(pageRoute: pageRoute);
    itemsLayout = appStorage.getItemsStyle(pageRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      textTitle: 'Drafts',
      textSubTitle: 'They are only visible to you',
      titlePadding: EdgeInsets.only(
        left: titleLeftPadding,
      ),
      bottomPadding: EdgeInsets.only(
        left: bottomContentLeftPadding,
        bottom: 10.0,
      ),
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
      itemsLayout: itemsLayout,
      onItemsLayoutSelected: (selectedLayout) {
        if (selectedLayout == itemsLayout) {
          return;
        }

        setState(() {
          itemsLayout = selectedLayout;
        });

        appStorage.saveItemsStyle(
          pageRoute: pageRoute,
          style: selectedLayout,
        );
      },
    );
  }

  Widget body() {
    if (isLoading) {
      return loadingView();
    }

    if (!isLoading && hasErrors) {
      return errorView();
    }

    if (drafts.length == 0) {
      return emptyView();
    }

    final Widget sliver =
        itemsLayout == ItemsLayout.list ? listView() : gridView();

    return SliverPadding(
      padding: const EdgeInsets.only(top: 24.0),
      sliver: sliver,
    );
  }

  Widget emptyView() {
    return SliverEmptyView(
      icon: Icon(
        UniconsLine.edit,
        size: 40.0,
      ),
      titleString: "No drafts",
      descriptionString:
          "You can save them when you are not ready to propose your quotes",
    );
  }

  Widget errorView() {
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

  Widget gridView() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300.0,
          crossAxisSpacing: 20.0,
          mainAxisSpacing: 20.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final draft = drafts.elementAt(index);

            return TempQuoteRowWithActions(
              componentType: ItemComponentType.card,
              isDraft: true,
              padding: const EdgeInsets.all(20.0),
              elevation: Constants.cardElevation,
              onTap: () => editDraft(draft),
              tempQuote: draft,
            );
          },
          childCount: drafts.length,
        ),
      ),
    );
  }

  Widget listView() {
    double horPadding = 70.0;

    if (MediaQuery.of(context).size.width < Constants.maxMobileWidth) {
      horPadding = 0.0;
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final draft = drafts.elementAt(index);

          return TempQuoteRowWithActions(
            tempQuote: draft,
            isDraft: true,
            key: ObjectKey(index),
            useSwipeActions: true,
            showPopupMenuButton: true,
            onTap: () => editDraft(draft),
            padding: EdgeInsets.symmetric(horizontal: horPadding),
            onBeforeAddTempQuoteFromDraft: () {
              processingQuotes.putIfAbsent(index, () => draft);
              setState(() => drafts.removeAt(index));

              Snack.s(
                context: context,
                message:
                    "Draft has been saved as temporary quote for validation.",
              );
            },
            onAfterAddTempQuoteFromDraft: (success) {
              if (success) {
                deleteDraftAfterSubmitAsTempQuote(draft);
                return;
              }

              if (processingQuotes.containsKey(index)) {
                drafts.insert(
                  index,
                  processingQuotes.entries.elementAt(index).value,
                );
              }

              Snack.e(
                context: context,
                message: "Couldn't submit this draft as a temporary quote. "
                    "Please try again or contact us if the problem persists.",
              );
            },
            onBeforeDeleteDraft: () {
              processingQuotes.putIfAbsent(index, () => draft);
              setState(() => drafts.removeAt(index));

              Snack.s(
                context: context,
                message: "Draft deleted.",
              );
            },
            onAfterDeleteDraft: (success) {
              if (success) {
                return;
              }

              if (processingQuotes.containsKey(index)) {
                drafts.insert(
                  index,
                  processingQuotes.entries.elementAt(index).value,
                );
              }

              Snack.e(
                context: context,
                message: "Couldn't delete this draft quote. "
                    "Please try again or contact us if the problem persists.",
              );
            },
          );
        },
        childCount: drafts.length,
      ),
    );
  }

  Widget loadingView() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.only(top: 150.0),
          child: LoadingAnimation(),
        ),
      ]),
    );
  }

  void deleteAction({TempQuote draft, int index}) async {
    setState(() => drafts.removeAt(index));

    bool success = false;

    if (draft.isOffline) {
      success = DraftsActions.deleteOfflineItem(
          createdAt: draft.createdAt.toString());
    } else {
      success = await DraftsActions.deleteItem(
        context: context,
        draft: draft,
      );
    }

    if (!success) {
      drafts.insert(index, draft);

      Snack.e(
        context: context,
        message: "Couldn't delete the temporary quote.",
      );
    }
  }

  void deleteDraftAfterSubmitAsTempQuote(TempQuote draft) async {
    if (draft.isOffline) {
      DraftsActions.deleteOfflineItem(
        createdAt: draft.createdAt.toString(),
      );
    } else {
      await DraftsActions.deleteItem(
        context: context,
        draft: draft,
      );
    }
  }

  void editDraft(TempQuote draft) async {
    DataQuoteInputs.isOfflineDraft = draft.isOffline;
    DataQuoteInputs.draft = draft;
    DataQuoteInputs.populateWithTempQuote(draft);

    await context.router.root.push(
      DashboardPageRoute(
        children: [
          AddQuoteStepsRoute(),
        ],
      ),
    );

    fetch();
  }

  Future fetch() async {
    setState(() {
      isLoading = true;
      drafts.clear();
    });

    try {
      fetchOffline();

      final draftsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(stateUser.userAuth.uid)
          .collection('drafts')
          .orderBy('createdAt', descending: descending)
          .limit(limit)
          .get();

      if (draftsSnap.docs.isEmpty) {
        setState(() {
          hasNext = false;
          isLoading = false;
        });

        return;
      }

      draftsSnap.docs.forEach((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        final draft = TempQuote.fromJSON(data);
        drafts.add(draft);
      });

      lastDoc = draftsSnap.docs.last;

      setState(() {
        isLoading = false;
        hasErrors = false;
        hasNext = draftsSnap.docs.length == limit;
      });
    } catch (error) {
      debugPrint(error.toString());
      hasErrors = true;
    }
  }

  Future fetchMore() async {
    if (lastDoc == null) {
      return;
    }

    setState(() => isLoadingMore = true);

    try {
      final snapColl = await FirebaseFirestore.instance
          .collection('users')
          .doc(stateUser.userAuth.uid)
          .collection('drafts')
          .startAfterDocument(lastDoc)
          .orderBy('createdAt', descending: descending)
          .limit(limit)
          .get();

      if (snapColl.docs.isEmpty) {
        setState(() {
          hasNext = false;
          isLoading = false;
        });

        return;
      }

      snapColl.docs.forEach((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        final draft = TempQuote.fromJSON(data);
        drafts.add(draft);
      });

      lastDoc = snapColl.docs.last;

      setState(() {
        isLoading = false;
        hasErrors = false;
        hasNext = snapColl.docs.length == limit;
      });
    } catch (error) {
      debugPrint(error.toString());
      hasErrors = true;
    }
  }

  void fetchOffline() {
    final savedDrafts = DraftsActions.getOfflineData();
    drafts.addAll(savedDrafts);
  }

  void showDeleteDialog({TempQuote draft, int index}) {
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text(
              'Confirm deletion?',
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 40.0,
            ),
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      primary: stateColors.softBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(3.0),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30.0,
                        vertical: 15.0,
                      ),
                      child: Text(
                        'NO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(left: 15.0)),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      deleteAction(draft: draft, index: index);
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(3.0),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30.0,
                        vertical: 15.0,
                      ),
                      child: Text(
                        'YES',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        });
  }
}
