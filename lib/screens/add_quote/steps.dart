import 'package:animations/animations.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figstyle/router/app_router.gr.dart';
import 'package:figstyle/utils/app_logger.dart';
import 'package:figstyle/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:figstyle/actions/drafts.dart';
import 'package:figstyle/actions/temp_quotes.dart';
import 'package:figstyle/components/add_quote_app_bar.dart';
import 'package:figstyle/components/full_page_error.dart';
import 'package:figstyle/components/full_page_loading.dart';
import 'package:figstyle/components/data_quote_inputs.dart';
import 'package:figstyle/screens/add_quote/help/author.dart';
import 'package:figstyle/screens/add_quote/help/comment.dart';
import 'package:figstyle/screens/add_quote/help/content.dart';
import 'package:figstyle/screens/add_quote/help/reference.dart';
import 'package:figstyle/screens/add_quote/help/topics.dart';
import 'package:figstyle/screens/add_quote/author.dart';
import 'package:figstyle/screens/add_quote/comment.dart';
import 'package:figstyle/screens/add_quote/content.dart';
import 'package:figstyle/screens/add_quote/reference.dart';
import 'package:figstyle/screens/add_quote/topics.dart';
import 'package:figstyle/screens/admin_temp_quotes.dart';
import 'package:figstyle/screens/home/home.dart';
import 'package:figstyle/screens/my_temp_quotes.dart';
import 'package:figstyle/screens/signin.dart';
import 'package:figstyle/state/colors.dart';
import 'package:figstyle/state/user.dart';
import 'package:figstyle/types/enums.dart';
import 'package:figstyle/utils/snack.dart';
import 'package:flutter/services.dart';
import 'package:unicons/unicons.dart';

class AddQuoteSteps extends StatefulWidget {
  final int step;

  const AddQuoteSteps({
    Key key,
    @QueryParam('step') this.step = 0,
  }) : super(key: key);

  @override
  _AddQuoteStepsState createState() => _AddQuoteStepsState();
}

class _AddQuoteStepsState extends State<AddQuoteSteps> {
  AddQuoteType actionIntent;
  AddQuoteType actionResult;

  bool canManage = false;
  bool isCheckingAuth = false;
  bool isFabVisible = false;
  bool isSmallView = false;
  bool isSubmitting = false;
  bool stepChanged = false;

  FocusNode keyboardFocusNode;
  FocusNode showNavBackConfirmFocusNode;

  Icon fabIcon = Icon(UniconsLine.message);

  int currentStep = 0;
  int totalStep = 5;

  List<Widget> helpSteps = [
    HelpContent(),
    HelpTopics(),
    HelpAuthor(),
    HelpReference(),
    HelpComment(),
  ];

  String errorMessage = '';
  String fabText = 'Submit quote';

  /// True if the new step's index is less than the previous one.
  /// This property is used to reverse the shared axis transition.
  bool sharedAxisReverse = false;

  @override
  void initState() {
    super.initState();
    currentStep = widget.step;
    keyboardFocusNode = FocusNode();
    showNavBackConfirmFocusNode = FocusNode();

    checkAuth();

    if (DataQuoteInputs.quote.id.isNotEmpty) {
      fabText = 'Save quote';
      fabIcon = Icon(UniconsLine.save);
    }
  }

  @override
  void dispose() {
    keyboardFocusNode.dispose();
    showNavBackConfirmFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < Constants.maxMobileWidth;
    final horizontal = isNarrow ? 0.0 : 70.0;

    return RawKeyboardListener(
      onKey: (keyEvent) {
        // ?NOTE: Keys combinations must stay on top
        // or other single matching key events will override it.

        // <-- Previous step
        if (keyEvent.isAltPressed &&
            keyEvent.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
          cancel();
          return;
        }

        // Next step -->
        if (keyEvent.isAltPressed &&
            keyEvent.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
          next();
          return;
        }
      },
      focusNode: keyboardFocusNode,
      child: Scaffold(
        appBar: PreferredSize(
          child: AddQuoteAppBar(
            title: 'Add quote',
            isNarrow: isNarrow,
            help: helpSteps[currentStep],
          ),
          preferredSize: Size.fromHeight(80.0),
        ),
        floatingActionButton: isFabVisible
            ? FloatingActionButton.extended(
                onPressed: () => propose(),
                backgroundColor: stateColors.validation,
                foregroundColor: Colors.white,
                icon: fabIcon,
                label: Text(
                  fabText,
                ),
              )
            : Container(),
        body: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
          ),
          child: body(),
        ),
      ),
    );
  }

  Widget actionButtonLabel({
    String labelText = '',
    Function onTap,
    Widget icon,
    Color backgroundIconColor,
  }) {
    return SizedBox(
      width: 120.0,
      child: Column(
        children: <Widget>[
          Material(
            elevation: 3.0,
            color: backgroundIconColor,
            shape: CircleBorder(),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: icon,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Opacity(
              opacity: 0.6,
              child: Text(
                labelText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget actionTile({
    String labelText = '',
    Function onTap,
    Color iconBackgroundColor,
    Widget icon,
  }) {
    return Container(
      width: 400.0,
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 30.0,
                backgroundColor: iconBackgroundColor,
                foregroundColor: Colors.white,
                child: icon,
              ),
              Padding(padding: const EdgeInsets.only(left: 30.0)),
              Expanded(
                flex: 2,
                child: Opacity(
                  opacity: 0.6,
                  child: Text(
                    labelText,
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget body() {
    if (errorMessage.isNotEmpty) {
      return FullPageError(
        message: errorMessage,
      );
    }

    if (isCheckingAuth) {
      return FullPageLoading();
    }

    if (isSubmitting) {
      return FullPageLoading(
        title: DataQuoteInputs.quote.id.isEmpty
            ? 'Submitting quote...'
            : 'Saving quote...',
      );
    }

    return stepperSections();
  }

  StepState computeStepState({
    int stepIndex,
    Function compute,
  }) {
    if (currentStep == stepIndex) {
      return StepState.editing;
    }

    if (compute != null) {
      StepState computed = compute();
      return computed;
    }

    return StepState.indexed;
  }

  Widget dynamicStepContent({@required int index}) {
    Widget stepChild;

    if (currentStep != index) {
      stepChild = Padding(
        padding: EdgeInsets.zero,
      );
    } else {
      switch (index) {
        case 0:
          stepChild = AddQuoteContent(
            onSaveDraft: () => saveQuoteDraft(),
          );
          break;
        case 1:
          stepChild = AddQuoteTopics();
          break;
        case 2:
          stepChild = AddQuoteAuthor();
          break;
        case 3:
          stepChild = AddQuoteReference();
          break;
        case 4:
          stepChild = AddQuoteComment();
          break;
        default:
          stepChild = Padding(
            padding: EdgeInsets.zero,
          );
          break;
      }
    }

    return sharedAxisTransition(
      child: stepChild,
      reverse: sharedAxisReverse,
    );
  }

  Widget horizontalActions() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 100.0,
        bottom: 200.0,
      ),
      child: Wrap(
        spacing: 40.0,
        runSpacing: 20.0,
        children: <Widget>[
          actionButtonLabel(
            labelText: 'Home',
            icon: Icon(Icons.home, color: Colors.white),
            backgroundIconColor: Colors.green.shade400,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => Home())),
          ),
          actionButtonLabel(
            labelText: 'Add another quote',
            icon: Icon(Icons.add, color: Colors.white),
            backgroundIconColor: stateColors.primary,
            onTap: () {
              DataQuoteInputs.clearQuoteData();
              DataQuoteInputs.clearTopics();
              DataQuoteInputs.clearComment();

              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => AddQuoteSteps()));
            },
          ),
          actionButtonLabel(
            labelText:
                canManage ? 'Admin temporary quotes' : 'Temporary quotes',
            icon: Icon(Icons.timelapse, color: Colors.white),
            backgroundIconColor: Colors.orange,
            onTap: () {
              if (canManage) {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => AdminTempQuotes()));
                return;
              }

              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => MyTempQuotes()));
            },
          ),
        ],
      ),
    );
  }

  Widget sharedAxisTransition({
    @required Widget child,
    bool reverse = false,
  }) {
    return PageTransitionSwitcher(
      child: child,
      reverse: reverse,
      transitionBuilder: (
        Widget child,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return SharedAxisTransition(
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
        );
      },
    );
  }

  Widget stepperSections() {
    return Stepper(
      controlsBuilder: (context, {onStepCancel, onStepContinue}) {
        return Row(
          children: [
            TextButton(
              onPressed: onStepCancel,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  currentStep > 0 ? "PREVIOUS" : "QUIT",
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
            ),
            ElevatedButton(
              onPressed: onStepContinue,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  currentStep >= (totalStep - 1)
                      ? fabText.toUpperCase()
                      : "NEXT",
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: stateColors.validation,
              ),
            ),
          ],
        );
      },
      currentStep: currentStep,
      onStepContinue: next,
      onStepCancel: cancel,
      onStepTapped: (step) => goTo(step),
      steps: [
        Step(
          title: Text('Content'),
          subtitle: Text('Required'),
          content: dynamicStepContent(index: 0),
          state: computeStepState(
            stepIndex: 0,
            compute: () {
              return DataQuoteInputs.quote.name.isEmpty
                  ? StepState.error
                  : StepState.complete;
            },
          ),
        ),
        Step(
          title: const Text('Topics'),
          subtitle: Text('Required'),
          content: dynamicStepContent(index: 1),
          state: computeStepState(
            stepIndex: 1,
            compute: () {
              if (!stepChanged) {
                return StepState.indexed;
              }

              if (DataQuoteInputs.quote.topics.length == 0) {
                return StepState.error;
              }

              return StepState.complete;
            },
          ),
        ),
        Step(
          subtitle: Text('Optional'),
          title: const Text('Author'),
          content: dynamicStepContent(index: 2),
          state: computeStepState(
            stepIndex: 2,
            compute: () {
              return DataQuoteInputs.author.name.isEmpty
                  ? StepState.indexed
                  : StepState.complete;
            },
          ),
        ),
        Step(
          subtitle: Text('Optional'),
          title: const Text('Reference'),
          content: dynamicStepContent(index: 3),
          state: computeStepState(
            stepIndex: 3,
            compute: () {
              return DataQuoteInputs.reference.name.isEmpty
                  ? StepState.indexed
                  : StepState.complete;
            },
          ),
        ),
        Step(
          subtitle: Text('Optional'),
          title: const Text('Comments'),
          content: dynamicStepContent(index: 4),
          state: computeStepState(
            stepIndex: 2,
            compute: () {
              return DataQuoteInputs.comment.isEmpty
                  ? StepState.indexed
                  : StepState.complete;
            },
          ),
        ),
      ],
    );
  }

  Widget verticalActions() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 100.0,
        bottom: 200.0,
      ),
      child: Column(
        children: <Widget>[
          actionTile(
            labelText: 'Home',
            icon: Icon(
              Icons.home,
            ),
            iconBackgroundColor: Colors.green.shade400,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => Home())),
          ),
          actionTile(
            labelText: 'Add another quote',
            icon: Icon(
              Icons.add,
            ),
            iconBackgroundColor: stateColors.primary,
            onTap: () {
              DataQuoteInputs.clearQuoteData();
              DataQuoteInputs.clearTopics();
              DataQuoteInputs.clearComment();

              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => AddQuoteSteps()));
            },
          ),
          actionTile(
            labelText:
                canManage ? 'Admin temporary quotes' : 'Temporary quotes',
            icon: Icon(
              Icons.timelapse,
            ),
            iconBackgroundColor: Colors.orange,
            onTap: () {
              if (canManage) {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => AdminTempQuotes()));
                return;
              }

              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => MyTempQuotes()));
            },
          ),
        ],
      ),
    );
  }

  bool badQuoteFormat() {
    if (DataQuoteInputs.quote.name.isEmpty) {
      Snack.e(
        context: context,
        message: "The quote's content cannot be empty.",
      );

      return true;
    }

    if (DataQuoteInputs.quote.topics.length == 0) {
      Snack.e(
        context: context,
        message: 'You must select at least 1 topics for the quote.',
      );

      return true;
    }

    return false;
  }

  void cancel() {
    if (currentStep > 0) {
      sharedAxisReverse = true;
      goTo(currentStep - 1);
      return;
    }

    if (DataQuoteInputs.quote.name.isEmpty) {
      handleNavBack(false);
      return;
    }

    showNavBackConfirm();
  }

  void checkAuth() {
    setState(() {
      isCheckingAuth = true;
      isFabVisible = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      try {
        final userAuth = stateUser.userAuth;

        if (userAuth == null) {
          setState(() => isCheckingAuth = false);
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (_) => Signin()));
          return;
        }

        final user = await FirebaseFirestore.instance
            .collection('users')
            .doc(userAuth.uid)
            .get();

        if (!user.exists) {
          setState(() => isCheckingAuth = false);
          return;
        }

        setState(() {
          isCheckingAuth = false;
          isFabVisible = true;
          canManage = user.data()['rights']['user:managequote'] == true;
        });
      } catch (error) {
        debugPrint(error.toString());
        isCheckingAuth = false;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => Signin(),
          ),
        );
      }
    });
  }

  void goTo(int step) {
    stepChanged = true;
    sharedAxisReverse = currentStep < step;
    setState(() => currentStep = step);
  }

  void handleNavBack(bool fromDialog) {
    final rootRouter = context.router.root;
    final stackLength = rootRouter.stack.length;

    if (stackLength < 2) {
      rootRouter.push(HomeRoute());
      return;
    }

    final route = rootRouter.stack.elementAt(stackLength - 2).routeData.route;

    if (fromDialog) {
      rootRouter.push(route);
      return;
    }

    rootRouter.pop();
  }

  void next() {
    sharedAxisReverse = false;
    currentStep + 1 < totalStep ? goTo(currentStep + 1) : propose();
  }

  void propose() async {
    if (badQuoteFormat()) {
      return;
    }

    actionIntent = AddQuoteType.tempquote;

    setState(() {
      isSubmitting = true;
      isFabVisible = false;
    });

    if (DataQuoteInputs.isEditingPubQuote) {
      actionIntent = AddQuoteType.pubQuote;
      savePubQuote();
      return;
    }

    final success = await TempQuotesActions.proposeQuote(context: context);
    postProcessPropose(success);
  }

  void postProcessPropose(bool success) async {
    if (success) {
      setState(() {
        actionResult = AddQuoteType.tempquote;
        isSubmitting = false;
        isFabVisible = true;

        currentStep = 0;
        DataQuoteInputs.clearQuoteData();
      });

      if (DataQuoteInputs.isOfflineDraft) {
        DraftsActions.deleteOfflineItem(
          createdAt: DataQuoteInputs.draft.createdAt.toString(),
        );
      }

      if (DataQuoteInputs.draft != null) {
        await DraftsActions.deleteItem(
          context: context,
          draft: DataQuoteInputs.draft,
        );
      }

      Snack.s(
        context: context,
        message: TempQuotesActions.getResultMessage(
          actionIntent: actionIntent,
          actionResult: actionResult,
        ),
      );

      fabIcon = Icon(UniconsLine.message);
      return;
    }

    // Don't duplicate the draft (if it's already one)
    if (DataQuoteInputs.draft != null) {
      setState(() {
        actionResult = AddQuoteType.draft;
        isFabVisible = true;
        isSubmitting = false;
        fabIcon = Icon(UniconsLine.message);

        currentStep = 0;
        DataQuoteInputs.clearQuoteData();
      });

      return;
    }

    final successDraft = await DraftsActions.saveItem(
      context: context,
    );

    if (successDraft) {
      setState(() {
        actionResult = AddQuoteType.draft;
        isSubmitting = false;
        isFabVisible = true;
        fabIcon = Icon(UniconsLine.message);

        currentStep = 0;
        DataQuoteInputs.clearQuoteData();
      });

      if (DataQuoteInputs.isOfflineDraft) {
        DraftsActions.deleteOfflineItem(
          createdAt: DataQuoteInputs.draft.createdAt.toString(),
        );
      }

      Snack.s(
        context: context,
        message: TempQuotesActions.getResultMessage(
          actionIntent: actionIntent,
          actionResult: actionResult,
        ),
      );

      return;
    }

    await DraftsActions.saveOfflineItem(context: context);

    setState(() {
      actionResult = AddQuoteType.offline;
      fabIcon = Icon(UniconsLine.message);
      isSubmitting = false;
      isFabVisible = true;

      currentStep = 0;
      DataQuoteInputs.clearQuoteData();
    });

    Snack.s(
      context: context,
      message: TempQuotesActions.getResultMessage(
        actionIntent: actionIntent,
        actionResult: actionResult,
      ),
    );
  }

  void savePubQuote() async {
    try {
      final quoteDoc = await FirebaseFirestore.instance
          .collection('quotes')
          .doc(DataQuoteInputs.quote.id)
          .get();

      if (!quoteDoc.exists) {
        Snack.e(
          context: context,
          message:
              "Sorry, the quote ${DataQuoteInputs.quote.id} does not exist. "
              "It may have been deleted.",
        );
        return;
      }

      final payload = DataQuoteInputs.quote.toJSON(
        withAuthor: DataQuoteInputs.author,
        withReference: DataQuoteInputs.reference,
      );

      await quoteDoc.reference.update(payload);

      setState(() {
        actionResult = AddQuoteType.pubQuote;
        isSubmitting = false;
        isFabVisible = true;

        DataQuoteInputs.clearQuoteData();
        currentStep = 0;
        fabIcon = Icon(UniconsLine.message);
      });

      Snack.s(
        context: context,
        message: "Your changes has been successfully saved!",
      );
    } catch (error) {
      appLogger.e(error);

      setState(() {
        actionResult = AddQuoteType.pubQuote;
        isSubmitting = false;
        isFabVisible = true;
      });

      Snack.e(
        context: context,
        message: "Sorry, we couldn't save your modifications for this quote. "
            "Please try again or contact us if the issue persists.",
      );
    }
  }

  void saveQuoteDraft() async {
    if (DataQuoteInputs.quote.name.isEmpty) {
      Snack.e(
        context: context,
        message: "The quote's content cannot be empty.",
      );

      return;
    }

    actionIntent = AddQuoteType.draft;

    final successDraft = await DraftsActions.saveItem(
      context: context,
    );

    if (successDraft) {
      setState(() {
        actionResult = AddQuoteType.draft;
        isSubmitting = false;
        isFabVisible = true;
        currentStep = 0;
        DataQuoteInputs.clearQuoteData();
      });

      Snack.s(
        context: context,
        message: "Your draft has been successfully saved online.",
      );

      if (DataQuoteInputs.isOfflineDraft) {
        DraftsActions.deleteOfflineItem(
          createdAt: DataQuoteInputs.draft.createdAt.toString(),
        );
      }

      return;
    }

    await DraftsActions.saveOfflineItem(context: context);

    setState(() {
      actionResult = AddQuoteType.offline;
      isSubmitting = false;
      isFabVisible = true;
      currentStep = 0;
      DataQuoteInputs.clearAll();
    });

    Snack.s(
      context: context,
      message: "Your draft has been successfully saved offline.",
    );
  }

  void showNavBackConfirm() {
    showDialog(
      context: context,
      builder: (_) {
        return RawKeyboardListener(
          autofocus: true,
          focusNode: showNavBackConfirmFocusNode,
          onKey: (keyEvent) {
            if (keyEvent.isKeyPressed(LogicalKeyboardKey.enter) ||
                keyEvent.isKeyPressed(LogicalKeyboardKey.space)) {
              context.router.pop();
              handleNavBack(true);
            }
          },
          child: AlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  UniconsLine.exclamation_triangle,
                  color: stateColors.secondary,
                ),
                Padding(padding: const EdgeInsets.only(left: 8.0)),
                Text('Abandon'),
              ],
            ),
            content: Opacity(
              opacity: 0.6,
              child: Text("All unsaved data will be lost."),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  context.router.pop();
                  handleNavBack(true);
                },
                child: Text(
                  'YES',
                  style: TextStyle(
                    color: stateColors.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: context.router.pop,
                child: Text(
                  'NO',
                  style: TextStyle(
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
