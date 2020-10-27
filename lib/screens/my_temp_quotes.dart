import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figstyle/components/circle_button.dart';
import 'package:figstyle/components/error_container.dart';
import 'package:figstyle/components/base_page_app_bar.dart';
import 'package:figstyle/components/temp_quote_row_with_actions.dart';
import 'package:figstyle/components/app_icon.dart';
import 'package:figstyle/components/empty_content.dart';
import 'package:figstyle/components/fade_in_y.dart';
import 'package:figstyle/components/loading_animation.dart';
import 'package:figstyle/router/route_names.dart';
import 'package:figstyle/screens/signin.dart';
import 'package:figstyle/state/colors.dart';
import 'package:figstyle/state/user_state.dart';
import 'package:figstyle/types/enums.dart';
import 'package:figstyle/types/temp_quote.dart';
import 'package:figstyle/utils/app_localstorage.dart';
import 'package:figstyle/utils/snack.dart';
import 'package:supercharged/supercharged.dart';

class MyTempQuotes extends StatefulWidget {
  @override
  MyTempQuotesState createState() => MyTempQuotesState();
}

class MyTempQuotesState extends State<MyTempQuotes> {
  bool descending = false;
  bool hasNext = true;
  bool hasErrors = false;
  bool isFabVisible = false;
  bool isLoading = false;
  bool isLoadingMore = false;

  DocumentSnapshot lastDoc;

  ItemsLayout itemsLayout = ItemsLayout.list;

  int limit = 30;
  int order = -1;

  ScrollController scrollController = ScrollController();

  String lang = 'all';
  final String pageRoute = TempQuotesRoute;

  List<TempQuote> tempQuotes = [];

  @override
  initState() {
    super.initState();
    initProps();
    fetch();
  }

  void initProps() {
    lang = appLocalStorage.getPageLang(pageRoute: pageRoute);
    descending = appLocalStorage.getPageOrder(pageRoute: pageRoute);
    itemsLayout = appLocalStorage.getItemsStyle(pageRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: isFabVisible
          ? FloatingActionButton(
              onPressed: () {
                scrollController.animateTo(
                  0.0,
                  duration: Duration(seconds: 1),
                  curve: Curves.easeOut,
                );
              },
              backgroundColor: stateColors.primary,
              foregroundColor: Colors.white,
              child: Icon(Icons.arrow_upward),
            )
          : null,
      body: RefreshIndicator(
          onRefresh: () async {
            await fetch();
            return null;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollNotif) {
              // FAB visibility
              if (scrollNotif.metrics.pixels < 50 && isFabVisible) {
                setState(() {
                  isFabVisible = false;
                });
              } else if (scrollNotif.metrics.pixels > 50 && !isFabVisible) {
                setState(() {
                  isFabVisible = true;
                });
              }

              // Load more scenario
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
                appBar(),
                body(),
              ],
            ),
          )),
    );
  }

  Widget appBar() {
    // ?NOTE: Not using PageAppBar because of custom languages: 'all'.
    return BasePageAppBar(
      expandedHeight: 170.0,
      title: Row(
        children: [
          CircleButton(
              onTap: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back, color: stateColors.foreground)),
          AppIcon(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            size: 30.0,
            onTap: () {
              scrollController.animateTo(
                0,
                duration: 250.milliseconds,
                curve: Curves.easeIn,
              );
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In validation',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Opacity(
                  opacity: .6,
                  child: Text(
                    'Your quotes waiting to be validated',
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
      subHeader: Observer(
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 10.0,
              children: <Widget>[
                FadeInY(
                  beginY: 10.0,
                  delay: 0.0,
                  child: ChoiceChip(
                    label: Text(
                      'First added',
                      style: TextStyle(
                        color:
                            !descending ? Colors.white : stateColors.foreground,
                      ),
                    ),
                    selected: !descending,
                    selectedColor: stateColors.primary,
                    onSelected: (selected) {
                      if (!descending) {
                        return;
                      }

                      descending = false;
                      fetch();

                      appLocalStorage.setPageOrder(
                        descending: descending,
                        pageRoute: pageRoute,
                      );
                    },
                  ),
                ),
                FadeInY(
                  beginY: 10.0,
                  delay: 0.1,
                  child: ChoiceChip(
                    label: Text(
                      'Last added',
                      style: TextStyle(
                        color:
                            descending ? Colors.white : stateColors.foreground,
                      ),
                    ),
                    selected: descending,
                    selectedColor: stateColors.primary,
                    onSelected: (selected) {
                      if (descending) {
                        return;
                      }

                      descending = true;
                      fetch();

                      appLocalStorage.setPageOrder(
                        descending: descending,
                        pageRoute: pageRoute,
                      );
                    },
                  ),
                ),
                FadeInY(
                  beginY: 10.0,
                  delay: 0.3,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 10.0,
                      left: 20.0,
                      right: 20.0,
                    ),
                    child: Container(
                      height: 25,
                      width: 2.0,
                      color: stateColors.foreground,
                    ),
                  ),
                ),
                FadeInY(
                  beginY: 10.0,
                  delay: 0.4,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: DropdownButton<String>(
                      elevation: 2,
                      value: lang,
                      isDense: true,
                      underline: Container(
                        height: 0,
                        color: Colors.deepPurpleAccent,
                      ),
                      icon: Icon(Icons.keyboard_arrow_down),
                      style: TextStyle(
                        color: stateColors.foreground.withOpacity(0.6),
                        fontFamily: GoogleFonts.raleway().fontFamily,
                        fontSize: 20.0,
                      ),
                      onChanged: (String newLang) {
                        lang = newLang;
                        fetch();
                      },
                      items: ['all', 'en', 'fr'].map((String value) {
                        return DropdownMenuItem(
                            value: value,
                            child: Text(
                              value.toUpperCase(),
                            ));
                      }).toList(),
                    ),
                  ),
                ),
                FadeInY(
                  beginY: 10.0,
                  delay: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 10.0,
                      left: 20.0,
                      right: 20.0,
                    ),
                    child: Container(
                      height: 25,
                      width: 2.0,
                      color: stateColors.foreground,
                    ),
                  ),
                ),
                FadeInY(
                  beginY: 10.0,
                  delay: 0.6,
                  child: IconButton(
                    onPressed: () {
                      if (itemsLayout == ItemsLayout.list) {
                        return;
                      }

                      setState(() {
                        itemsLayout = ItemsLayout.list;
                      });

                      appLocalStorage.saveItemsStyle(
                        pageRoute: pageRoute,
                        style: ItemsLayout.list,
                      );
                    },
                    icon: Icon(Icons.list),
                    color: itemsLayout == ItemsLayout.list
                        ? stateColors.primary
                        : stateColors.foreground.withOpacity(0.5),
                  ),
                ),
                FadeInY(
                  beginY: 10.0,
                  delay: 0.7,
                  child: IconButton(
                    onPressed: () {
                      if (itemsLayout == ItemsLayout.grid) {
                        return;
                      }

                      setState(() {
                        itemsLayout = ItemsLayout.grid;
                      });

                      appLocalStorage.saveItemsStyle(
                        pageRoute: pageRoute,
                        style: ItemsLayout.grid,
                      );
                    },
                    icon: Icon(Icons.grid_on),
                    color: itemsLayout == ItemsLayout.grid
                        ? stateColors.primary
                        : stateColors.foreground.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget body() {
    if (isLoading) {
      return loadingView();
    }

    if (!isLoading && hasErrors) {
      return errorView();
    }

    if (tempQuotes.length == 0) {
      return emptyView();
    }

    if (itemsLayout == ItemsLayout.list) {
      return listView();
    }

    return gridView();
  }

  Widget emptyView() {
    return SliverList(
      delegate: SliverChildListDelegate([
        FadeInY(
          delay: 2.0,
          beginY: 50.0,
          child: EmptyContent(
            icon: Opacity(
              opacity: .8,
              child: Icon(
                Icons.timelapse,
                size: 120.0,
                color: Color(0xFFFF005C),
              ),
            ),
            title: "You've no quote in validation at this moment",
            subtitle: 'They will appear after you propose a new quote',
            onRefresh: () => fetch(),
          ),
        ),
      ]),
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
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final tempQuote = tempQuotes.elementAt(index);

            return TempQuoteRowWithActions(
              componentType: ItemComponentType.card,
              tempQuote: tempQuote,
              onBeforeDelete: () {
                setState(() {
                  tempQuotes.removeAt(index);
                });
              },
              onAfterDelete: (success) {
                if (success) {
                  return;
                }

                setState(() {
                  tempQuotes.insert(index, tempQuote);
                });

                showSnack(
                  context: context,
                  message: "Couldn't delete the temporary quote",
                  type: SnackType.error,
                );
              },
              onBeforeValidate: () {
                setState(() {
                  tempQuotes.removeAt(index);
                });
              },
              onAfterValidate: (success) {
                if (success) {
                  return;
                }

                setState(() {
                  tempQuotes.insert(index, tempQuote);
                });

                showSnack(
                  context: context,
                  message: "Couldn't validate your temporary quote.",
                  type: SnackType.error,
                );
              },
              onNavBack: () {
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  fetch();
                });
              },
            );
          },
          childCount: tempQuotes.length,
        ),
      ),
    );
  }

  Widget listView() {
    final horPadding = MediaQuery.of(context).size.width < 700.00 ? 20.0 : 70.0;

    return SliverPadding(
      padding: const EdgeInsets.only(top: 40.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tempQuote = tempQuotes.elementAt(index);

            return TempQuoteRowWithActions(
              tempQuote: tempQuote,
              isDraft: false,
              padding: EdgeInsets.symmetric(
                horizontal: horPadding,
              ),
              onBeforeDelete: () {
                setState(() {
                  tempQuotes.removeAt(index);
                });
              },
              onAfterDelete: (success) {
                if (success) {
                  return;
                }

                setState(() {
                  tempQuotes.insert(index, tempQuote);
                });

                showSnack(
                  context: context,
                  message: "Couldn't delete the temporary quote",
                  type: SnackType.error,
                );
              },
              onBeforeValidate: () {
                setState(() {
                  tempQuotes.removeAt(index);
                });
              },
              onAfterValidate: (success) {
                if (success) {
                  return;
                }

                setState(() {
                  tempQuotes.insert(index, tempQuote);
                });

                showSnack(
                  context: context,
                  message: "Couldn't validate your temporary quote.",
                  type: SnackType.error,
                );
              },
              onNavBack: () {
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  fetch();
                });
              },
            );
          },
          childCount: tempQuotes.length,
        ),
      ),
    );
  }

  Widget loadingView() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.only(top: 200.0),
          child: LoadingAnimation(),
        ),
      ]),
    );
  }

  Future fetch() async {
    setState(() {
      isLoading = true;
    });

    tempQuotes.clear();

    try {
      final userAuth = await userState.userAuth;

      if (userAuth == null) {
        throw Error();
      }

      QuerySnapshot snapshot;

      if (lang == 'all') {
        snapshot = await FirebaseFirestore.instance
            .collection('tempquotes')
            .where('user.id', isEqualTo: userAuth.uid)
            .orderBy('createdAt', descending: descending)
            .limit(limit)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('tempquotes')
            .where('user.id', isEqualTo: userAuth.uid)
            .where('lang', isEqualTo: lang)
            .orderBy('createdAt', descending: descending)
            .limit(limit)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        setState(() {
          hasErrors = false;
          hasNext = false;
          isLoading = false;
        });

        return;
      }

      snapshot.docs.forEach((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        final quote = TempQuote.fromJSON(data);
        tempQuotes.add(quote);
      });

      lastDoc = snapshot.docs.last;

      setState(() {
        isLoading = false;
        hasErrors = false;
        hasNext = snapshot.docs.length == limit;
      });
    } catch (error) {
      debugPrint(error.toString());

      setState(() {
        isLoading = false;
        hasErrors = true;
      });

      if (!userState.isUserConnected) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => Signin()));
      }
    }
  }

  void fetchMore() async {
    if (lastDoc == null) {
      return;
    }

    setState(() {
      isLoadingMore = true;
    });

    try {
      final userAuth = await userState.userAuth;

      if (userAuth == null) {
        throw Error();
      }

      QuerySnapshot snapshot;

      if (lang == 'all') {
        snapshot = await FirebaseFirestore.instance
            .collection('tempquotes')
            .startAfterDocument(lastDoc)
            .where('user.id', isEqualTo: userAuth.uid)
            .orderBy('createdAt', descending: descending)
            .limit(limit)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('tempquotes')
            .startAfterDocument(lastDoc)
            .where('user.id', isEqualTo: userAuth.uid)
            .where('lang', isEqualTo: lang)
            .orderBy('createdAt', descending: descending)
            .limit(limit)
            .get();
      }

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

        final quote = TempQuote.fromJSON(data);
        tempQuotes.insert(tempQuotes.length - 1, quote);
      });

      setState(() {
        hasNext = snapshot.docs.length == limit;
        isLoadingMore = false;
      });
    } catch (error) {
      debugPrint(error.toString());

      setState(() {
        isLoadingMore = false;
      });
    }
  }
}
