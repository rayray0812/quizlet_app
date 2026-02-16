import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, AppLocalizations Function(Locale)> _localizedValues =
      {
        'en': (locale) => AppLocalizationsEn(locale),
        'zh': (locale) => AppLocalizationsZh(locale),
      };

  static AppLocalizations _create(Locale locale) {
    final factory = _localizedValues[locale.languageCode];
    if (factory != null) return factory(locale);
    return AppLocalizationsZh(locale);
  }

  // -- Home --
  String get myStudySets => '';
  String get noStudySetsYet => '';
  String get importOrCreate => '';
  String get importBtn => '';
  String get createBtn => '';
  String get deleteStudySet => '';
  String deleteStudySetConfirm(String title) => '';
  String get cancel => '';
  String get delete => '';
  String get newStudySet => '';
  String get title => '';
  String get descriptionOptional => '';
  String get create => '';
  String get createNewSet => '';
  String get importFromRecall => '';
  String get profile => '';
  String get settings => '';
  String get theme => '';
  String get systemMode => '';
  String get lightMode => '';
  String get darkMode => '';
  String signedInAs(String email) => '';
  String get close => '';
  String get signOut => '';
  String get sync => '';
  String get logIn => '';

  // -- Auth --
  String get signUp => '';
  String get welcomeBack => '';
  String get createAccount => '';
  String get email => '';
  String get password => '';
  String get enterValidEmail => '';
  String get passwordMinLength => '';
  String get noAccountSignUp => '';
  String get hasAccountLogIn => '';
  String get skipGuest => '';

  // -- Study Modes --
  String get flashcards => '';
  String get flashcardsDesc => '';
  String get quiz => '';
  String get quizDesc => '';
  String get matchingGame => '';
  String get matchingGameDesc => '';
  String nCards(int count) => '';
  String get needAtLeast4Cards => '';
  String get needAtLeast2Cards => '';
  String get studySetNotFound => '';
  String get noCardsAvailable => '';
  String get swipeOrTapArrows => '';
  String get hard => '';
  String get medium => '';
  String get easy => '';
  String get home => '';

  // -- Quiz --
  String get score => '';
  String scoreLabel(int score) => '';
  String get whatIsDefinitionOf => '';
  String get quizComplete => '';
  String quizResult(int score, int total) => '';
  String percentCorrect(int percent) => '';
  String get tryAgain => '';
  String get done => '';

  // -- Matching --
  String matched(int matched, int total) => '';
  String get restart => '';
  String get gameComplete => '';
  String timeSeconds(int seconds) => '';
  String attemptsForPairs(int attempts, int pairs) => '';
  String get playAgain => '';

  // -- Import --
  String get importTitle => '';
  String get useAppToImport => '';
  String get webViewMobileOnly => '';
  String get goBack => '';
  String get importSet => '';
  String get noFlashcardsFound => '';
  String importFailed(String error) => '';
  String get reviewImport => '';
  String get save => '';
  String get setTitle => '';
  String get addAtLeastOneCard => '';
  String get importedSet => '';

  // -- Language --
  String get language => '';
  String get chinese => '';
  String get english => '';

  // -- Study Set Card --
  String cards(int count) => '';

  // -- New keys (R7) --
  String get editCards => '';
  String savedNCards(int count) => '';
  String get start => '';
  String get know => '';
  String get dontKnow => '';
  String get greatJob => '';
  String get roundComplete => '';
  String reviewNUnknownCards(int count) => '';
  String get swipeToSort => '';
  String get importFromFile => '';
  String get enterRecallUrl => '';
  String get tapToFlip => '';
  String get definitionLabel => '';
  String get listen => '';
  String get exportAsJson => '';
  String get exportAsCsv => '';
  String get howMany => '';
  String get autoFetchImage => '';
  String get allTerms => '';
  String get addCards => '';
  String get pleaseEnterRecallUrl => '';

  // -- SRS --
  String get srsReview => '';
  String get srsReviewDesc => '';
  String get quickBrowse => '';
  String get quickBrowseDesc => '';
  String get speakingPractice => '';
  String get speakingPracticeDesc => '';
  String get todaySpeakingAvg => '';
  String get last30SpeakingAvg => '';
  String get speakingAttempts => '';
  String get speakWord => '';
  String get speakSentence => '';
  String get replaySequence => '';
  String get autoScore => '';
  String get stopListening => '';
  String useScore(int score) => '';
  String recognizedSpeech(String text) => '';
  String get speechRecognitionUnavailable => '';
  String get exampleLabel => '';
  String get autoGeneratedLabel => '';
  String get noExampleSentence => '';
  String get rateSpeaking => '';
  String get speakingComplete => '';
  String averageScore(double score) => '';
  String get noDueCards => '';
  String get reviewComplete => '';
  String reviewedNCards(int count) => '';
  String nDueCards(int count) => '';
  String get todayReview => '';
  String get newCards => '';
  String get learningCards => '';
  String get reviewCards => '';

  // -- Stats --
  String get statistics => '';
  String get todayReviews => '';
  String get streak => '';
  String get totalReviews => '';
  String get last30Days => '';
  String get ratingBreakdown => '';
  String nDays(int count) => '';

  // -- Tags / Search --
  String get tags => '';
  String get addTag => '';
  String get search => '';
  String get customStudy => '';
  String get selectTags => '';
  String nMatchingCards(int count) => '';
  String get startReview => '';
  String get noResults => '';

  // -- Photo to Flashcard (F6) --
  String get photoToFlashcard => '';
  String get vocabularyList => '';
  String get vocabularyListDesc => '';
  String get textbookPage => '';
  String get textbookPageDesc => '';
  String get takePhoto => '';
  String get chooseFromGallery => '';
  String get geminiApiKey => '';
  String get geminiApiKeyHint => '';
  String get geminiApiKeyNotSet => '';
  String get geminiApiKeySaved => '';
  String get analyzing => '';
  String get noCardsExtracted => '';
  String get photoScanFailed => '';
  String get chooseMode => '';
  String get chooseImageSource => '';
  String get retryOrChooseAnother => '';

  String get scanTimeout => '';
  String get scanQuotaExceeded => '';
  String get scanParseError => '';
  String get scanNetworkError => '';
  String get cancelAnalysis => '';

  // -- Multi-photo (F6+) --
  String cardsFromPhotos(int cards, int photos) => '';
  String get reviewAndSave => '';
  String get addMorePhotos => '';
  String photoAdded(int count) => '';

  // -- Daily Challenge --
  String get dailyChallenge => '';
  String challengeStreak(int count) => '';
  String challengeTodayComplete(int target) => '';
  String challengeProgress(int reviewed, int target) => '';
  String get challengeCompleteMsg => '';
  String get challengeNoDueCards => '';
  String challengeNextRun(int count) => '';
  String get play => '';
  String get challengeCompletedToast => '';

  // -- Revenge Mode --
  String get revengeMode => '';
  String revengeCount(int count) => '';
  String revengeClearedCount(int count) => '';
  String get revengeDetail => '';
  String get revengeLookbackDays => '';
  String revengeDaysOption(int days) => '';
  String get revengeFilterAll => '';
  String get revengeStats => '';
  String get revengeClearRate => '';
  String get revengeMostWrong => '';
  String revengeWrongTimes(int count) => '';
  String get revengeStartFlip => '';
  String get revengeStartQuiz => '';
  String get revengeNeedMoreCards => '';
  String get revengeSelectSets => '';

  // -- Notifications --
  String get dailyReminder => '';
  String get dailyReminderDesc => '';
  String get reminderTitle => '';

  // -- Folders (F7) --
  String get folders => '';
  String get noFoldersYet => '';
  String get newFolder => '';
  String get editFolder => '';
  String get folderName => '';
  String get deleteFolder => '';
  String deleteFolderConfirm(String name) => '';
  String get color => '';
  String get icon => '';
  String get moveToFolder => '';
  String get noFolder => '';
  String get pin => '';
  String get unpin => '';

  // -- Sorting (F8) --
  String get sortNewest => '';
  String get sortAlpha => '';
  String get sortMostDue => '';
  String get sortLastStudied => '';
  String get undo => '';

  // -- Onboarding (F9) --
  String get onboardingWelcome => '';
  String get onboardingWelcomeDesc => '';
  String get onboardingFeatures => '';
  String get onboardingFeaturesDesc => '';
  String get onboardingStart => '';
  String get onboardingStartDesc => '';
  String get skip => '';
  String get next => '';
  String get getStarted => '';

  // -- QR Share (F10) --
  String get shareSet => '';
  String get scanQr => '';
  String get scanToImport => '';
  String get linkCopied => '';
  String get copyLink => '';
  String get share => '';
  String get pointCameraAtQr => '';
  String get qrInvalidData => '';

  // -- Achievements (F11) --
  String get achievements => '';
  String get badgesUnlocked => '';
  String get badgeFirstReview => '';
  String get badgeFirstReviewDesc => '';
  String get badgeStreak7 => '';
  String get badgeStreak7Desc => '';
  String get badgeStreak30 => '';
  String get badgeStreak30Desc => '';
  String get badgeReviews100 => '';
  String get badgeReviews100Desc => '';
  String get badgeReviews1000 => '';
  String get badgeReviews1000Desc => '';
  String get badgeMastered50 => '';
  String get badgeMastered50Desc => '';
  String get badgeRevengeClear => '';
  String get badgeRevengeClearDesc => '';
  String get badgeSets10 => '';
  String get badgeSets10Desc => '';
  String get badgePerfectQuiz => '';
  String get badgePerfectQuizDesc => '';
  String get badgeChallenge30 => '';
  String get badgeChallenge30Desc => '';
  String get badgePhoto10 => '';
  String get badgePhoto10Desc => '';
  String get badgeSpeedrun => '';
  String get badgeSpeedrunDesc => '';
  String get badgeUnlocked => '';

  // -- Pomodoro (F12) --
  String get pomodoro => '';
  String get pomodoroDesc => '';
  String get pomodoroStudy => '';
  String get pomodoroShortBreak => '';
  String get pomodoroLongBreak => '';
  String get pomodoroReset => '';
  String get pomodoroStarted => '';
  String pomodoroSessions(int count) => '';

  String get reminderBody => '';

  // -- Rating labels (SRS) --
  String get ratingAgain => '';
  String get ratingHard => '';
  String get ratingGood => '';
  String get ratingEasy => '';

  // -- Card Edit form --
  String get termLabel => '';
  String get definitionInput => '';
  String get exampleSentenceLabel => '';
  String get deleteCard => '';
  String get add => '';
  String get tagNameHint => '';

  // -- Matching result --
  String get pairsLabel => '';
  String get attemptsLabel => '';

  // -- Challenge detail (review summary) --
  String challengeCompleteDetail(int target) => '';
  String challengeProgressDetail(int reviewed, int target) => '';

  // -- Auto-image --
  String autoImageProgress(int done, int total) => '';
  String autoImageDone(int count) => '';
  String get autoImageCancelled => '';

  // -- Quiz Enhancement (A3) --
  String get typeYourAnswer => '';
  String get submit => '';
  String get trueLabel => '';
  String get falseLabel => '';
  String get isThisCorrect => '';
  String get correctAnswer => '';
  String get reinforcementRound => '';
  String get reinforcementDesc => '';
  String get almostCorrect => '';
  String wrongCount(int n) => '';

  // -- Editor Upgrade (B2) --
  String get selectMode => '';
  String get selectAll => '';
  String get deselectAll => '';
  String get deleteSelected => '';
  String get addTagToSelected => '';
  String get removeTagFromSelected => '';
  String nSelected(int n) => '';
  String get undoAction => '';
  String get redoAction => '';
  String get duplicateWarning => '';
  String get blankWarning => '';
  String get saveAnyway => '';
  String get goBackToFix => '';
  String cardNMissingField(int n, String field) => '';
  String cardsAreDuplicates(int a, int b) => '';
}

class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh(super.locale);

  // -- Home --
  @override
  String get myStudySets => '\u6211\u7684\u5B78\u7FD2\u96C6';
  @override
  String get noStudySetsYet => '\u9084\u6C92\u6709\u5B78\u7FD2\u96C6';
  @override
  String get importOrCreate =>
      '\u5F9E\u7DB2\u9801\u532F\u5165\u6216\u81EA\u5DF1\u5EFA\u7ACB';
  @override
  String get importBtn => '\u532F\u5165';
  @override
  String get createBtn => '\u5EFA\u7ACB';
  @override
  String get deleteStudySet => '\u522A\u9664\u5B78\u7FD2\u96C6\uFF1F';
  @override
  String deleteStudySetConfirm(String title) =>
      '\u78BA\u5B9A\u8981\u522A\u9664\u300C$title\u300D\u55CE\uFF1F';
  @override
  String get cancel => '\u53D6\u6D88';
  @override
  String get delete => '\u522A\u9664';
  @override
  String get newStudySet => '\u65B0\u5B78\u7FD2\u96C6';
  @override
  String get title => '\u6A19\u984C';
  @override
  String get descriptionOptional => '\u63CF\u8FF0\uFF08\u9078\u586B\uFF09';
  @override
  String get create => '\u5EFA\u7ACB';
  @override
  String get createNewSet => '\u5EFA\u7ACB\u65B0\u5B78\u7FD2\u96C6';
  @override
  String get importFromRecall => '\u7DB2\u9801\u532F\u5165';
  @override
  String get profile => '\u500B\u4EBA\u6A94\u6848';
  @override
  String get settings => '\u8A2D\u5B9A';
  @override
  String get theme => '\u4E3B\u984C';
  @override
  String get systemMode => '\u8DDF\u96A8\u7CFB\u7D71';
  @override
  String get lightMode => '\u6DFA\u8272';
  @override
  String get darkMode => '\u6DF1\u8272';
  @override
  String signedInAs(String email) => '\u5DF2\u767B\u5165\uFF1A\n$email';
  @override
  String get close => '\u95DC\u9589';
  @override
  String get signOut => '\u767B\u51FA';
  @override
  String get sync => '\u540C\u6B65';
  @override
  String get logIn => '\u767B\u5165';

  // -- Auth --
  @override
  String get signUp => '\u8A3B\u518A';
  @override
  String get welcomeBack => '\u6B61\u8FCE\u56DE\u4F86';
  @override
  String get createAccount => '\u5EFA\u7ACB\u5E33\u865F';
  @override
  String get email => '\u96FB\u5B50\u4FE1\u7BB1';
  @override
  String get password => '\u5BC6\u78BC';
  @override
  String get enterValidEmail =>
      '\u8ACB\u8F38\u5165\u6709\u6548\u7684\u96FB\u5B50\u4FE1\u7BB1';
  @override
  String get passwordMinLength =>
      '\u5BC6\u78BC\u81F3\u5C11\u9700\u8981 6 \u500B\u5B57\u5143';
  @override
  String get noAccountSignUp => '\u6C92\u6709\u5E33\u865F\uFF1F\u8A3B\u518A';
  @override
  String get hasAccountLogIn => '\u5DF2\u6709\u5E33\u865F\uFF1F\u767B\u5165';
  @override
  String get skipGuest => '\u7565\u904E / \u8A2A\u5BA2\u6A21\u5F0F';

  // -- Study Modes --
  @override
  String get flashcards => '\u7FFB\u5361\u7247';
  @override
  String get flashcardsDesc =>
      '\u6ED1\u52D5\u700F\u89BD\u5361\u7247\uFF0C\u9EDE\u64CA\u7FFB\u8F49\u67E5\u770B\u7B54\u6848';
  @override
  String get quiz => '\u6E2C\u9A57';
  @override
  String get quizDesc =>
      '\u56DB\u9078\u4E00\u6E2C\u9A57\u4F60\u7684\u77E5\u8B58';
  @override
  String get matchingGame => '\u914D\u5C0D\u904A\u6232';
  @override
  String get matchingGameDesc =>
      '\u5C07\u8853\u8A9E\u8207\u5B9A\u7FA9\u914D\u5C0D';
  @override
  String nCards(int count) => '$count \u5F35\u5361\u7247';
  @override
  String get needAtLeast4Cards =>
      '\u81F3\u5C11\u9700\u8981 4 \u5F35\u5361\u7247\u624D\u80FD\u6E2C\u9A57';
  @override
  String get needAtLeast2Cards =>
      '\u81F3\u5C11\u9700\u8981 2 \u5F35\u5361\u7247\u624D\u80FD\u914D\u5C0D';
  @override
  String get studySetNotFound => '\u627E\u4E0D\u5230\u5B78\u7FD2\u96C6';
  @override
  String get noCardsAvailable => '\u6C92\u6709\u5361\u7247';
  @override
  String get swipeOrTapArrows => '\u6ED1\u52D5\u6216\u9EDE\u64CA\u7BAD\u982D';
  @override
  String get hard => '\u96E3';
  @override
  String get medium => '\u4E2D';
  @override
  String get easy => '\u7C21\u55AE';
  @override
  String get home => '\u9996\u9801';

  // -- Quiz --
  @override
  String get score => '\u5206\u6578';
  @override
  String scoreLabel(int score) => '\u5206\u6578\uFF1A$score';
  @override
  String get whatIsDefinitionOf =>
      '\u4EE5\u4E0B\u8A5E\u5F59\u7684\u5B9A\u7FA9\u662F\uFF1F';
  @override
  String get quizComplete => '\u6E2C\u9A57\u5B8C\u6210\uFF01';
  @override
  String quizResult(int score, int total) => '$score / $total';
  @override
  String percentCorrect(int percent) => '\u6B63\u78BA\u7387 $percent%';
  @override
  String get tryAgain => '\u518D\u8A66\u4E00\u6B21';
  @override
  String get done => '\u5B8C\u6210';

  // -- Matching --
  @override
  String matched(int matched, int total) =>
      '\u5DF2\u914D\u5C0D\uFF1A$matched / $total';
  @override
  String get restart => '\u91CD\u65B0\u958B\u59CB';
  @override
  String get gameComplete => '\u904A\u6232\u5B8C\u6210\uFF01';
  @override
  String timeSeconds(int seconds) => '$seconds\u79D2';
  @override
  String attemptsForPairs(int attempts, int pairs) =>
      '$attempts \u6B21\u5617\u8A66\uFF0C$pairs \u7D44\u914D\u5C0D';
  @override
  String get playAgain => '\u518D\u73A9\u4E00\u6B21';

  // -- Import --
  @override
  String get importTitle => '\u532F\u5165';
  @override
  String get useAppToImport =>
      '\u8ACB\u4F7F\u7528\u624B\u6A5F\u7248 App \u532F\u5165';
  @override
  String get webViewMobileOnly =>
      'WebView \u532F\u5165\u50C5\u9650\u624B\u6A5F\u88DD\u7F6E\u4F7F\u7528';
  @override
  String get goBack => '\u8FD4\u56DE';
  @override
  String get importSet => '\u532F\u5165\u5B78\u7FD2\u96C6';
  @override
  String get noFlashcardsFound =>
      '\u627E\u4E0D\u5230\u5361\u7247\u3002\u8ACB\u5148\u5411\u4E0B\u6372\u52D5\u8F09\u5165\u6240\u6709\u5361\u7247\u3002';
  @override
  String importFailed(String error) => '\u532F\u5165\u5931\u6557\uFF1A$error';
  @override
  String get reviewImport => '\u532F\u5165\u9810\u89BD';
  @override
  String get save => '\u5132\u5B58';
  @override
  String get setTitle => '\u5B78\u7FD2\u96C6\u6A19\u984C';
  @override
  String get addAtLeastOneCard =>
      '\u81F3\u5C11\u65B0\u589E\u4E00\u5F35\u5361\u7247';
  @override
  String get importedSet => '\u532F\u5165\u7684\u5B78\u7FD2\u96C6';

  // -- Language --
  @override
  String get language => '\u8A9E\u8A00';
  @override
  String get chinese => '\u7E41\u9AD4\u4E2D\u6587';
  @override
  String get english => 'English';

  // -- Study Set Card --
  @override
  String cards(int count) => '$count \u5F35\u5361\u7247';

  // -- New keys (R7) --
  @override
  String get editCards => '\u7DE8\u8F2F\u5361\u7247';
  @override
  String savedNCards(int count) => '\u5DF2\u5132\u5B58 $count \u5F35\u5361\u7247';
  @override
  String get start => '\u958B\u59CB';
  @override
  String get know => '\u77E5\u9053';
  @override
  String get dontKnow => '\u4E0D\u77E5\u9053';
  @override
  String get greatJob => '\u505A\u5F97\u5F88\u597D\uFF01';
  @override
  String get roundComplete => '\u56DE\u5408\u5B8C\u6210';
  @override
  String reviewNUnknownCards(int count) =>
      '\u8907\u7FD2 $count \u5F35\u4E0D\u77E5\u9053\u7684\u5361\u7247';
  @override
  String get swipeToSort => '\u6ED1\u52D5\u5206\u985E';
  @override
  String get importFromFile => '\u5F9E\u6A94\u6848\u532F\u5165 (JSON/CSV)';
  @override
  String get enterRecallUrl => '\u8F38\u5165\u5B78\u7FD2\u96C6\u7DB2\u5740';
  @override
  String get tapToFlip => '\u9EDE\u64CA\u7FFB\u9762';
  @override
  String get definitionLabel => '\u5B9A\u7FA9';
  @override
  String get listen => '\u64AD\u653E\u767C\u97F3';
  @override
  String get exportAsJson => '\u532F\u51FA JSON';
  @override
  String get exportAsCsv => '\u532F\u51FA CSV';
  @override
  String get howMany => '\u8981\u5E7E\u5F35\uFF1F';
  @override
  String get autoFetchImage => '\u81EA\u52D5\u6293\u5716';
  @override
  String get allTerms => '\u5168\u90E8\u8A5E\u689D';
  @override
  String get addCards => '\u65B0\u589E\u5361\u7247';
  @override
  String get pleaseEnterRecallUrl =>
      '\u8ACB\u8F38\u5165\u6709\u6548\u7684\u7DB2\u5740';

  // -- SRS --
  @override
  String get srsReview => 'SRS \u8907\u7FD2';
  @override
  String get srsReviewDesc => '\u9593\u9694\u91CD\u8907\u5B78\u7FD2\uFF0C\u66F4\u9AD8\u6548';
  @override
  String get quickBrowse => '\u5FEB\u901F\u700F\u89BD';
  @override
  String get quickBrowseDesc => '\u6ED1\u52D5\u700F\u89BD\u6240\u6709\u5361\u7247';
  @override
  String get speakingPractice => '\u53E3\u8AAA\u7DF4\u7FD2';
  @override
  String get speakingPracticeDesc =>
      '\u807D\u55AE\u5B57\u8207\u4F8B\u53E5\u5F8C\uFF0C\u8A9E\u97F3\u81EA\u52D5\u8FA8\u8B58\u8A55\u5206';
  @override
  String get todaySpeakingAvg => '\u4ECA\u65E5\u53E3\u8AAA\u5E73\u5747';
  @override
  String get last30SpeakingAvg => '\u8FD130\u5929\u53E3\u8AAA\u5E73\u5747';
  @override
  String get speakingAttempts => '\u53E3\u8AAA\u7DF4\u7FD2\u6B21\u6578';
  @override
  String get speakWord => '\u5FF5\u55AE\u5B57';
  @override
  String get speakSentence => '\u5FF5\u4F8B\u53E5';
  @override
  String get replaySequence => '\u91CD\u64AD\u55AE\u5B57+\u4F8B\u53E5';
  @override
  String get autoScore => '\u81EA\u52D5\u8A55\u5206';
  @override
  String get stopListening => '\u505C\u6B62\u8FA8\u8B58';
  @override
  String useScore(int score) => '\u4F7F\u7528\u5206\u6578 $score';
  @override
  String recognizedSpeech(String text) => '\u8FA8\u8B58\u7D50\u679C\uff1a$text';
  @override
  String get speechRecognitionUnavailable => '\u6B64\u88DD\u7F6E\u7121\u6CD5\u4F7F\u7528\u8A9E\u97F3\u8FA8\u8B58';
  @override
  String get exampleLabel => '\u4F8B\u53E5';
  @override
  String get autoGeneratedLabel => '\u81EA\u52D5\u751F\u6210';
  @override
  String get noExampleSentence => '\u6B64\u55AE\u5B57\u7121\u53EF\u7528\u4F8B\u53E5';
  @override
  String get rateSpeaking => '\u8ACB\u8A55\u5206\u4F60\u7684\u53E3\u8AAA';
  @override
  String get speakingComplete => '\u53E3\u8AAA\u7DF4\u7FD2\u5B8C\u6210';
  @override
  String averageScore(double score) => '\u5E73\u5747\u5206\u6578 $score';
  @override
  String get noDueCards => '\u4ECA\u5929\u6C92\u6709\u5F85\u8907\u7FD2\u5361\u7247';
  @override
  String get reviewComplete => '\u8907\u7FD2\u5B8C\u6210\uFF01';
  @override
  String reviewedNCards(int count) => '\u5DF2\u8907\u7FD2 $count \u5F35\u5361\u7247';
  @override
  String nDueCards(int count) => '$count \u5F35\u5F85\u8907\u7FD2';
  @override
  String get todayReview => '\u4ECA\u65E5\u8907\u7FD2';
  @override
  String get newCards => '\u65B0\u5361';
  @override
  String get learningCards => '\u5B78\u7FD2\u4E2D';
  @override
  String get reviewCards => '\u8907\u7FD2';

  // -- Stats --
  @override
  String get statistics => '\u7D71\u8A08';
  @override
  String get todayReviews => '\u4ECA\u5929';
  @override
  String get streak => '\u9023\u7E8C\u5929\u6578';
  @override
  String get totalReviews => '\u7E3D\u8907\u7FD2\u6578';
  @override
  String get last30Days => '\u6700\u8FD1 30 \u5929';
  @override
  String get ratingBreakdown => '\u96E3\u5EA6\u5206\u5E03';
  @override
  String nDays(int count) => '$count \u5929';

  // -- Tags / Search --
  @override
  String get tags => '\u6A19\u7C64';
  @override
  String get addTag => '\u65B0\u589E\u6A19\u7C64';
  @override
  String get search => '\u641C\u5C0B';
  @override
  String get customStudy => '\u81EA\u8A02\u5B78\u7FD2';
  @override
  String get selectTags => '\u9078\u64C7\u6A19\u7C64';
  @override
  String nMatchingCards(int count) => '$count \u5F35\u7B26\u5408\u689D\u4EF6\u7684\u5361\u7247';
  @override
  String get startReview => '\u958B\u59CB\u8907\u7FD2';
  @override
  String get noResults => '\u627E\u4E0D\u5230\u7D50\u679C';

  // -- Photo to Flashcard (F6) --
  @override
  String get photoToFlashcard => '\u62CD\u7167\u5EFA\u5361';
  @override
  String get vocabularyList => '\u55AE\u5B57\u8868';
  @override
  String get vocabularyListDesc => '\u8FA8\u8B58\u5716\u7247\u4E2D\u7684\u55AE\u5B57\u8207\u91CB\u7FA9';
  @override
  String get textbookPage => '\u8AB2\u672C\u9801\u9762';
  @override
  String get textbookPageDesc => '\u64F7\u53D6\u8AB2\u672C\u5167\u5BB9\u7684\u91CD\u9EDE\u6982\u5FF5';
  @override
  String get takePhoto => '\u62CD\u7167';
  @override
  String get chooseFromGallery => '\u5F9E\u76F8\u7C3F\u9078\u64C7';
  @override
  String get geminiApiKey => 'Gemini API Key';
  @override
  String get geminiApiKeyHint => '\u8F38\u5165\u4F60\u7684 Gemini API Key';
  @override
  String get geminiApiKeyNotSet => '\u8ACB\u5148\u5728\u8A2D\u5B9A\u9801\u8F38\u5165 Gemini API Key';
  @override
  String get geminiApiKeySaved => 'API Key \u5DF2\u5132\u5B58';
  @override
  String get analyzing => 'AI \u5206\u6790\u4E2D\u2026';
  @override
  String get noCardsExtracted => '\u7121\u6CD5\u64F7\u53D6\u5361\u7247\uFF0C\u8ACB\u63DB\u4E00\u5F35\u5716\u7247\u8A66\u8A66';
  @override
  String get photoScanFailed => '\u5206\u6790\u5931\u6557\uFF0C\u8ACB\u518D\u8A66\u4E00\u6B21';
  @override
  String get chooseMode => '\u9078\u64C7\u8FA8\u8B58\u6A21\u5F0F';
  @override
  String get chooseImageSource => '\u9078\u64C7\u5716\u7247\u4F86\u6E90';
  @override
  String get retryOrChooseAnother => '\u91CD\u8A66\u6216\u9078\u64C7\u5176\u4ED6\u5716\u7247';

  @override
  String get scanTimeout => '\u8ACB\u6C42\u903E\u6642\uFF0C\u8ACB\u6AA2\u67E5\u7DB2\u8DEF\u5F8C\u91CD\u8A66';
  @override
  String get scanQuotaExceeded => 'API \u984D\u5EA6\u5DF2\u7528\u5B8C\uFF0C\u8ACB\u7A0D\u5F8C\u518D\u8A66';
  @override
  String get scanParseError => 'AI \u56DE\u61C9\u683C\u5F0F\u7570\u5E38\uFF0C\u8ACB\u91CD\u8A66';
  @override
  String get scanNetworkError => '\u7DB2\u8DEF\u932F\u8AA4\uFF0C\u8ACB\u6AA2\u67E5\u9023\u7DDA';
  @override
  String get cancelAnalysis => '\u53D6\u6D88';

  // -- Multi-photo (F6+) --
  @override
  String cardsFromPhotos(int cards, int photos) => '$cards \u5F35\u5361\u7247 / $photos \u5F35\u7167\u7247';
  @override
  String get reviewAndSave => '\u9810\u89BD\u4E26\u5132\u5B58';
  @override
  String get addMorePhotos => '\u7E7C\u7E8C\u62CD\u7167';
  @override
  String photoAdded(int count) => '\u5DF2\u65B0\u589E $count \u5F35\u5361\u7247';

  // -- Daily Challenge --
  @override
  String get dailyChallenge => '\u6BCF\u65E5\u6311\u6230';
  @override
  String challengeStreak(int count) => '\u9023\u7E8C $count \u5929';
  @override
  String challengeTodayComplete(int target) => '\u4ECA\u65E5\u5B8C\u6210\uFF1A$target/$target';
  @override
  String challengeProgress(int reviewed, int target) => '\u9032\u5EA6\uFF1A$reviewed/$target';
  @override
  String get challengeCompleteMsg => '\u505A\u5F97\u597D\uFF01\u660E\u5929\u518D\u4F86\u6311\u6230\u5427\u3002';
  @override
  String get challengeNoDueCards => '\u76EE\u524D\u6C92\u6709\u5F85\u8907\u7FD2\u5361\u7247\uFF0C\u7A0D\u5F8C\u518D\u4F86\u3002';
  @override
  String challengeNextRun(int count) => '\u4E0B\u4E00\u8F2A\uFF1A$count \u5F35';
  @override
  String get play => '\u958B\u59CB';
  @override
  String get challengeCompletedToast => '\u592A\u68D2\u4E86\uFF01\u4ECA\u65E5\u6311\u6230\u5B8C\u6210 \uD83C\uDF89';

  // -- Revenge Mode --
  @override
  String get revengeMode => '\u932F\u984C\u8907\u7FD2';
  @override
  String revengeCount(int count) => '$count \u5F35\u7B54\u932F\u7684\u5361\u7247\u7B49\u4F60\u6311\u6230';
  @override
  String revengeClearedCount(int count) => '\u5DF2\u6E05\u9664 $count \u9053\u932F\u984C\uFF01';
  @override
  String get revengeDetail => '\u932F\u984C\u8907\u7FD2\u8A73\u60C5';
  @override
  String get revengeLookbackDays => '\u56DE\u9867\u5929\u6578';
  @override
  String revengeDaysOption(int days) => '$days \u5929';
  @override
  String get revengeFilterAll => '\u5168\u90E8';
  @override
  String get revengeStats => '\u7D71\u8A08';
  @override
  String get revengeClearRate => '\u6E05\u9664\u7387';
  @override
  String get revengeMostWrong => '\u6700\u5E38\u7B54\u932F';
  @override
  String revengeWrongTimes(int count) => '\u932F $count \u6B21';
  @override
  String get revengeStartFlip => '\u7FFB\u5361\u8907\u7FD2';
  @override
  String get revengeStartQuiz => '\u6E2C\u9A57\u6A21\u5F0F';
  @override
  String get revengeNeedMoreCards => '\u6E2C\u9A57\u81F3\u5C11\u9700\u8981 4 \u5F35\u932F\u984C\u5361';
  @override
  String get revengeSelectSets => '\u9078\u64C7\u5B78\u7FD2\u96C6';

  // -- Notifications --
  @override
  String get dailyReminder => '\u6BCF\u65E5\u8907\u7FD2\u63D0\u9192';
  @override
  String get dailyReminderDesc => '\u6BCF\u5929 20:00 \u63D0\u9192\u4F60\u8907\u7FD2';
  @override
  String get reminderTitle => '\u8A72\u4F86\u8907\u7FD2\u4E86\uFF01';
  @override
  String get reminderBody => '\u4F60\u6709\u5F85\u8907\u7FD2\u7684\u5361\u7247\uFF0C\u6253\u958B\u62FE\u61B6\u770B\u770B\u5427';

  // -- Folders (F7) --
  @override
  String get folders => '\u8CC7\u6599\u593E';
  @override
  String get noFoldersYet => '\u9084\u6C92\u6709\u8CC7\u6599\u593E';
  @override
  String get newFolder => '\u65B0\u8CC7\u6599\u593E';
  @override
  String get editFolder => '\u7DE8\u8F2F\u8CC7\u6599\u593E';
  @override
  String get folderName => '\u8CC7\u6599\u593E\u540D\u7A31';
  @override
  String get deleteFolder => '\u522A\u9664\u8CC7\u6599\u593E\uFF1F';
  @override
  String deleteFolderConfirm(String name) => '\u78BA\u5B9A\u8981\u522A\u9664\u300C$name\u300D\u55CE\uFF1F';
  @override
  String get color => '\u984F\u8272';
  @override
  String get icon => '\u5716\u793A';
  @override
  String get moveToFolder => '\u79FB\u5230\u8CC7\u6599\u593E';
  @override
  String get noFolder => '\u7121\u8CC7\u6599\u593E';
  @override
  String get pin => '\u91D8\u9078';
  @override
  String get unpin => '\u53D6\u6D88\u91D8\u9078';

  // -- Sorting (F8) --
  @override
  String get sortNewest => '\u6700\u65B0\u5EFA\u7ACB';
  @override
  String get sortAlpha => '\u5B57\u6BCD\u6392\u5E8F';
  @override
  String get sortMostDue => '\u6700\u591A\u5F85\u8907\u7FD2';
  @override
  String get sortLastStudied => '\u6700\u8FD1\u5B78\u7FD2';
  @override
  String get undo => '\u5FA9\u539F';

  // -- Onboarding (F9) --
  @override
  String get onboardingWelcome => '\u6B61\u8FCE\u4F86\u5230\u62FE\u61B6';
  @override
  String get onboardingWelcomeDesc => '\u667A\u6167\u8907\u7FD2\uFF0C\u9AD8\u6548\u8A18\u61B6';
  @override
  String get onboardingFeatures => '\u5F37\u5927\u529F\u80FD';
  @override
  String get onboardingFeaturesDesc => '\u9593\u9694\u91CD\u8907\u3001\u6BCF\u65E5\u6311\u6230\u3001\u62CD\u7167\u5EFA\u5361\n\u8B93\u5B78\u7FD2\u66F4\u6709\u6548\u7387';
  @override
  String get onboardingStart => '\u958B\u59CB\u5427\uFF01';
  @override
  String get onboardingStartDesc => '\u767B\u5165\u5E33\u865F\u540C\u6B65\u8CC7\u6599\uFF0C\u6216\u4EE5\u8A2A\u5BA2\u8EAB\u5206\u958B\u59CB';
  @override
  String get skip => '\u7565\u904E';
  @override
  String get next => '\u4E0B\u4E00\u6B65';
  @override
  String get getStarted => '\u958B\u59CB\u4F7F\u7528';

  // -- QR Share (F10) --
  @override
  String get shareSet => '\u5206\u4EAB\u5B78\u7FD2\u96C6';
  @override
  String get scanQr => '\u6383\u63CF QR Code';
  @override
  String get scanToImport => '\u8ACB\u5C0D\u65B9\u6383\u63CF\u6B64 QR Code \u5373\u53EF\u532F\u5165';
  @override
  String get linkCopied => '\u9023\u7D50\u5DF2\u8907\u88FD';
  @override
  String get copyLink => '\u8907\u88FD\u9023\u7D50';
  @override
  String get share => '\u5206\u4EAB';
  @override
  String get pointCameraAtQr => '\u5C07\u93E1\u982D\u5C0D\u6E96 QR Code';
  @override
  String get qrInvalidData => 'QR Code \u7121\u6CD5\u8FA8\u8B58';

  // -- Achievements (F11) --
  @override
  String get achievements => '\u6210\u5C31\u5FBD\u7AE0';
  @override
  String get badgesUnlocked => '\u5DF2\u89E3\u9396';
  @override
  String get badgeFirstReview => '\u521D\u6B21\u8907\u7FD2';
  @override
  String get badgeFirstReviewDesc => '\u5B8C\u6210\u7B2C\u4E00\u6B21\u8907\u7FD2';
  @override
  String get badgeStreak7 => '\u9023\u7E8C 7 \u5929';
  @override
  String get badgeStreak7Desc => '\u9023\u7E8C 7 \u5929\u8907\u7FD2';
  @override
  String get badgeStreak30 => '\u9023\u7E8C 30 \u5929';
  @override
  String get badgeStreak30Desc => '\u9023\u7E8C 30 \u5929\u8907\u7FD2';
  @override
  String get badgeReviews100 => '\u767E\u6B21\u8907\u7FD2';
  @override
  String get badgeReviews100Desc => '\u7D2F\u8A08\u8907\u7FD2 100 \u6B21';
  @override
  String get badgeReviews1000 => '\u5343\u6B21\u8907\u7FD2';
  @override
  String get badgeReviews1000Desc => '\u7D2F\u8A08\u8907\u7FD2 1000 \u6B21';
  @override
  String get badgeMastered50 => '\u7CBE\u901A 50';
  @override
  String get badgeMastered50Desc => '50 \u5F35\u5361\u7247\u9054\u5230\u7CBE\u901A';
  @override
  String get badgeRevengeClear => '\u6383\u6E05\u932F\u984C';
  @override
  String get badgeRevengeClearDesc => '\u6E05\u7A7A\u4E00\u6B21\u932F\u984C\u6C60';
  @override
  String get badgeSets10 => '\u5275\u5EFA\u5927\u5E2B';
  @override
  String get badgeSets10Desc => '\u5EFA\u7ACB 10 \u500B\u5B78\u7FD2\u96C6';
  @override
  String get badgePerfectQuiz => '\u6E80\u5206\u6E2C\u9A57';
  @override
  String get badgePerfectQuizDesc => '\u6E2C\u9A57\u5168\u5C0D';
  @override
  String get badgeChallenge30 => '\u6311\u6230 30 \u5929';
  @override
  String get badgeChallenge30Desc => '\u5B8C\u6210 30 \u6B21\u6BCF\u65E5\u6311\u6230';
  @override
  String get badgePhoto10 => '\u62CD\u7167\u9054\u4EBA';
  @override
  String get badgePhoto10Desc => '\u7528\u62CD\u7167\u5EFA\u5361\u5EFA\u7ACB 10 \u6B21';
  @override
  String get badgeSpeedrun => '\u6975\u901F\u914D\u5C0D';
  @override
  String get badgeSpeedrunDesc => '\u914D\u5C0D\u904A\u6232 30 \u79D2\u5167\u5B8C\u6210';
  @override
  String get badgeUnlocked => '\u89E3\u9396\u65B0\u5FBD\u7AE0\uFF01';

  // -- Pomodoro (F12) --
  @override
  String get pomodoro => '\u756A\u8304\u937E';
  @override
  String get pomodoroDesc => '\u5C08\u6CE8\u5B78\u7FD2\u8A08\u6642\u5668';
  @override
  String get pomodoroStudy => '\u5B78\u7FD2\u4E2D';
  @override
  String get pomodoroShortBreak => '\u77ED\u4F11\u606F';
  @override
  String get pomodoroLongBreak => '\u9577\u4F11\u606F';
  @override
  String get pomodoroReset => '\u91CD\u8A2D';
  @override
  String get pomodoroStarted => '\u756A\u8304\u937E\u5DF2\u555F\u52D5';
  @override
  String pomodoroSessions(int count) => '\u5DF2\u5B8C\u6210 $count \u500B\u756A\u8304';

  // -- Rating labels (SRS) --
  @override
  String get ratingAgain => '\u91CD\u4F86';
  @override
  String get ratingHard => '\u56F0\u96E3';
  @override
  String get ratingGood => '\u826F\u597D';
  @override
  String get ratingEasy => '\u5BB9\u6613';

  // -- Card Edit form --
  @override
  String get termLabel => '\u8853\u8A9E';
  @override
  String get definitionInput => '\u5B9A\u7FA9';
  @override
  String get exampleSentenceLabel => '\u4F8B\u53E5';
  @override
  String get deleteCard => '\u522A\u9664\u5361\u7247';
  @override
  String get add => '\u65B0\u589E';
  @override
  String get tagNameHint => '\u6A19\u7C64\u540D\u7A31';

  // -- Matching result --
  @override
  String get pairsLabel => '\u914D\u5C0D\u6578';
  @override
  String get attemptsLabel => '\u5617\u8A66\u6B21\u6578';

  // -- Challenge detail (review summary) --
  @override
  String challengeCompleteDetail(int target) => '\u6BCF\u65E5\u6311\u6230\u5B8C\u6210\uFF08$target \u5F35\u5361\u7247\uFF09';
  @override
  String challengeProgressDetail(int reviewed, int target) => '\u6BCF\u65E5\u6311\u6230\u9032\u5EA6\uFF1A$reviewed/$target';

  // -- Auto-image --
  @override
  String autoImageProgress(int done, int total) => '\u6293\u5716\u4E2D\u2026 $done/$total';
  @override
  String autoImageDone(int count) => '\u5DF2\u66F4\u65B0 $count \u5F35\u5716\u7247';
  @override
  String get autoImageCancelled => '\u5DF2\u53D6\u6D88\u6293\u5716';

  // -- Quiz Enhancement (A3) --
  @override
  String get typeYourAnswer => '\u8F38\u5165\u4F60\u7684\u7B54\u6848';
  @override
  String get submit => '\u63D0\u4EA4';
  @override
  String get trueLabel => '\u6B63\u78BA';
  @override
  String get falseLabel => '\u932F\u8AA4';
  @override
  String get isThisCorrect => '\u9019\u500B\u5B9A\u7FA9\u6B63\u78BA\u55CE\uFF1F';
  @override
  String get correctAnswer => '\u6B63\u78BA\u7B54\u6848';
  @override
  String get reinforcementRound => '\u932F\u984C\u8907\u7FD2';
  @override
  String get reinforcementDesc => '\u4F86\u8907\u7FD2\u7B54\u932F\u7684\u984C\u76EE\uFF01';
  @override
  String get almostCorrect => '\u5DEE\u4E00\u9EDE\uFF01\u6B63\u78BA\u7B54\u6848\u662F\uFF1A';
  @override
  String wrongCount(int n) => '$n \u984C\u7B54\u932F';

  // -- Editor Upgrade (B2) --
  @override
  String get selectMode => '\u9078\u53D6';
  @override
  String get selectAll => '\u5168\u9078';
  @override
  String get deselectAll => '\u53D6\u6D88\u5168\u9078';
  @override
  String get deleteSelected => '\u522A\u9664\u5DF2\u9078';
  @override
  String get addTagToSelected => '\u65B0\u589E\u6A19\u7C64';
  @override
  String get removeTagFromSelected => '\u79FB\u9664\u6A19\u7C64';
  @override
  String nSelected(int n) => '\u5DF2\u9078 $n \u5F35';
  @override
  String get undoAction => '\u5FA9\u539F';
  @override
  String get redoAction => '\u91CD\u505A';
  @override
  String get duplicateWarning => '\u767C\u73FE\u91CD\u8907\u5361\u7247';
  @override
  String get blankWarning => '\u767C\u73FE\u4E0D\u5B8C\u6574\u5361\u7247';
  @override
  String get saveAnyway => '\u4ECD\u7136\u5132\u5B58';
  @override
  String get goBackToFix => '\u8FD4\u56DE\u4FEE\u6539';
  @override
  String cardNMissingField(int n, String field) => '\u5361\u7247 #$n\uFF1A\u7F3A\u5C11$field';
  @override
  String cardsAreDuplicates(int a, int b) => '\u5361\u7247 #$a \u548C #$b \u91CD\u8907';
}

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn(super.locale);

  // -- Home --
  @override
  String get myStudySets => 'My Study Sets';
  @override
  String get noStudySetsYet => 'No study sets yet';
  @override
  String get importOrCreate => 'Import from Web or create your own';
  @override
  String get importBtn => 'Import';
  @override
  String get createBtn => 'Create';
  @override
  String get deleteStudySet => 'Delete Study Set?';
  @override
  String deleteStudySetConfirm(String title) =>
      'Are you sure you want to delete "$title"?';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get newStudySet => 'New Study Set';
  @override
  String get title => 'Title';
  @override
  String get descriptionOptional => 'Description (optional)';
  @override
  String get create => 'Create';
  @override
  String get createNewSet => 'Create New Set';
  @override
  String get importFromRecall => 'Web Import';
  @override
  String get profile => 'Profile';
  @override
  String get settings => 'Settings';
  @override
  String get theme => 'Theme';
  @override
  String get systemMode => 'System';
  @override
  String get lightMode => 'Light';
  @override
  String get darkMode => 'Dark';
  @override
  String signedInAs(String email) => 'Signed in as:\n$email';
  @override
  String get close => 'Close';
  @override
  String get signOut => 'Sign Out';
  @override
  String get sync => 'Sync';
  @override
  String get logIn => 'Log In';

  // -- Auth --
  @override
  String get signUp => 'Sign Up';
  @override
  String get welcomeBack => 'Welcome Back';
  @override
  String get createAccount => 'Create Account';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get enterValidEmail => 'Enter a valid email';
  @override
  String get passwordMinLength => 'Password must be at least 6 characters';
  @override
  String get noAccountSignUp => "Don't have an account? Sign Up";
  @override
  String get hasAccountLogIn => 'Already have an account? Log In';
  @override
  String get skipGuest => 'Skip / Continue as Guest';

  // -- Study Modes --
  @override
  String get flashcards => 'Flashcards';
  @override
  String get flashcardsDesc => 'Swipe through cards and flip to reveal answers';
  @override
  String get quiz => 'Quiz';
  @override
  String get quizDesc => 'Multiple choice questions to test your knowledge';
  @override
  String get matchingGame => 'Matching Game';
  @override
  String get matchingGameDesc => 'Match terms with their definitions';
  @override
  String nCards(int count) => '$count cards';
  @override
  String get needAtLeast4Cards => 'Need at least 4 cards for quiz';
  @override
  String get needAtLeast2Cards => 'Need at least 2 cards to match';
  @override
  String get studySetNotFound => 'Study set not found';
  @override
  String get noCardsAvailable => 'No cards available';
  @override
  String get swipeOrTapArrows => 'Swipe or tap arrows';
  @override
  String get hard => 'Hard';
  @override
  String get medium => 'Medium';
  @override
  String get easy => 'Easy';
  @override
  String get home => 'Home';

  // -- Quiz --
  @override
  String get score => 'Score';
  @override
  String scoreLabel(int score) => 'Score: $score';
  @override
  String get whatIsDefinitionOf => 'What is the definition of:';
  @override
  String get quizComplete => 'Quiz Complete!';
  @override
  String quizResult(int score, int total) => '$score / $total';
  @override
  String percentCorrect(int percent) => '$percent% correct';
  @override
  String get tryAgain => 'Try Again';
  @override
  String get done => 'Done';

  // -- Matching --
  @override
  String matched(int matched, int total) => 'Matched: $matched / $total';
  @override
  String get restart => 'Restart';
  @override
  String get gameComplete => 'Game Complete!';
  @override
  String timeSeconds(int seconds) => '${seconds}s';
  @override
  String attemptsForPairs(int attempts, int pairs) =>
      '$attempts attempts for $pairs pairs';
  @override
  String get playAgain => 'Play Again';

  // -- Import --
  @override
  String get importTitle => 'Import';
  @override
  String get useAppToImport => 'Use the mobile app to import';
  @override
  String get webViewMobileOnly =>
      'WebView import is only available on mobile devices.';
  @override
  String get goBack => 'Go Back';
  @override
  String get importSet => 'Import Set';
  @override
  String get noFlashcardsFound =>
      'No flashcards found. Try scrolling down to load all cards first.';
  @override
  String importFailed(String error) => 'Import failed: $error';
  @override
  String get reviewImport => 'Review Import';
  @override
  String get save => 'Save';
  @override
  String get setTitle => 'Set Title';
  @override
  String get addAtLeastOneCard => 'Add at least one card';
  @override
  String get importedSet => 'Imported Set';

  // -- Language --
  @override
  String get language => 'Language';
  @override
  String get chinese => '\u7E41\u9AD4\u4E2D\u6587';
  @override
  String get english => 'English';

  // -- Study Set Card --
  @override
  String cards(int count) => '$count cards';

  // -- New keys (R7) --
  @override
  String get editCards => 'Edit Cards';
  @override
  String savedNCards(int count) => 'Saved $count cards';
  @override
  String get start => 'Start';
  @override
  String get know => 'Know';
  @override
  String get dontKnow => "Don't know";
  @override
  String get greatJob => 'Great job!';
  @override
  String get roundComplete => 'Round Complete';
  @override
  String reviewNUnknownCards(int count) => 'Review $count unknown cards';
  @override
  String get swipeToSort => 'Swipe to sort';
  @override
  String get importFromFile => 'Import from File (JSON/CSV)';
  @override
  String get enterRecallUrl => 'Enter Web URL';
  @override
  String get tapToFlip => 'TAP TO FLIP';
  @override
  String get definitionLabel => 'DEFINITION';
  @override
  String get listen => 'Listen';
  @override
  String get exportAsJson => 'Export as JSON';
  @override
  String get exportAsCsv => 'Export as CSV';
  @override
  String get howMany => 'How many?';
  @override
  String get autoFetchImage => 'Auto Image';
  @override
  String get allTerms => 'All Terms';
  @override
  String get addCards => 'Add Cards';
  @override
  String get pleaseEnterRecallUrl => 'Please enter a valid URL';

  // -- SRS --
  @override
  String get srsReview => 'SRS Review';
  @override
  String get srsReviewDesc => 'Spaced repetition for efficient memorization';
  @override
  String get quickBrowse => 'Quick Browse (Swipe)';
  @override
  String get quickBrowseDesc => 'Swipe through all cards';
  @override
  String get speakingPractice => 'Speaking Practice';
  @override
  String get speakingPracticeDesc =>
      'Listen to word and sentence, then get an automatic speaking score';
  @override
  String get todaySpeakingAvg => 'Today Avg';
  @override
  String get last30SpeakingAvg => '30-Day Avg';
  @override
  String get speakingAttempts => 'Attempts';
  @override
  String get speakWord => 'Speak Word';
  @override
  String get speakSentence => 'Speak Sentence';
  @override
  String get replaySequence => 'Replay Word + Sentence';
  @override
  String get autoScore => 'Auto score';
  @override
  String get stopListening => 'Stop';
  @override
  String useScore(int score) => 'Use score $score';
  @override
  String recognizedSpeech(String text) => 'Recognized: $text';
  @override
  String get speechRecognitionUnavailable => 'Speech recognition is unavailable';
  @override
  String get exampleLabel => 'Example';
  @override
  String get autoGeneratedLabel => 'Auto';
  @override
  String get noExampleSentence => 'No example sentence available for this card.';
  @override
  String get rateSpeaking => 'Rate your speaking';
  @override
  String get speakingComplete => 'Speaking Complete';
  @override
  String averageScore(double score) => 'Average score $score';
  @override
  String get noDueCards => 'No cards due for review';
  @override
  String get reviewComplete => 'Review Complete!';
  @override
  String reviewedNCards(int count) => 'Reviewed $count cards';
  @override
  String nDueCards(int count) => '$count due';
  @override
  String get todayReview => "Today's Review";
  @override
  String get newCards => 'New';
  @override
  String get learningCards => 'Learning';
  @override
  String get reviewCards => 'Review';

  // -- Stats --
  @override
  String get statistics => 'Statistics';
  @override
  String get todayReviews => 'Today';
  @override
  String get streak => 'Streak';
  @override
  String get totalReviews => 'Total Reviews';
  @override
  String get last30Days => 'Last 30 Days';
  @override
  String get ratingBreakdown => 'Rating Breakdown';
  @override
  String nDays(int count) => '$count days';

  // -- Tags / Search --
  @override
  String get tags => 'Tags';
  @override
  String get addTag => 'Add Tag';
  @override
  String get search => 'Search';
  @override
  String get customStudy => 'Custom Study';
  @override
  String get selectTags => 'Select Tags';
  @override
  String nMatchingCards(int count) => '$count matching cards';
  @override
  String get startReview => 'Start Review';
  @override
  String get noResults => 'No results';

  // -- Photo to Flashcard (F6) --
  @override
  String get photoToFlashcard => 'Photo to Flashcard';
  @override
  String get vocabularyList => 'Vocabulary List';
  @override
  String get vocabularyListDesc => 'Extract words and definitions from the image';
  @override
  String get textbookPage => 'Textbook Page';
  @override
  String get textbookPageDesc => 'Extract key concepts from textbook content';
  @override
  String get takePhoto => 'Take Photo';
  @override
  String get chooseFromGallery => 'Choose from Gallery';
  @override
  String get geminiApiKey => 'Gemini API Key';
  @override
  String get geminiApiKeyHint => 'Enter your Gemini API Key';
  @override
  String get geminiApiKeyNotSet => 'Please set Gemini API Key in Settings first';
  @override
  String get geminiApiKeySaved => 'API Key saved';
  @override
  String get analyzing => 'AI analyzing...';
  @override
  String get noCardsExtracted => 'No cards extracted. Try a different image.';
  @override
  String get photoScanFailed => 'Analysis failed. Please try again.';
  @override
  String get chooseMode => 'Choose scan mode';
  @override
  String get chooseImageSource => 'Choose image source';
  @override
  String get retryOrChooseAnother => 'Retry or choose another image';

  @override
  String get scanTimeout => 'Request timed out. Check your connection and retry.';
  @override
  String get scanQuotaExceeded => 'API quota exceeded. Please try again later.';
  @override
  String get scanParseError => 'AI response was unexpected. Please retry.';
  @override
  String get scanNetworkError => 'Network error. Check your connection.';
  @override
  String get cancelAnalysis => 'Cancel';

  // -- Multi-photo (F6+) --
  @override
  String cardsFromPhotos(int cards, int photos) => '$cards cards / $photos photos';
  @override
  String get reviewAndSave => 'Review & Save';
  @override
  String get addMorePhotos => 'Add more photos';
  @override
  String photoAdded(int count) => 'Added $count cards';

  // -- Daily Challenge --
  @override
  String get dailyChallenge => 'Daily Challenge';
  @override
  String challengeStreak(int count) => '$count day streak';
  @override
  String challengeTodayComplete(int target) => 'Today complete: $target/$target';
  @override
  String challengeProgress(int reviewed, int target) => 'Progress: $reviewed/$target';
  @override
  String get challengeCompleteMsg => 'Great work. Come back tomorrow for a new run.';
  @override
  String get challengeNoDueCards => 'No due cards now. Review later to continue.';
  @override
  String challengeNextRun(int count) => 'Next run: $count cards';
  @override
  String get play => 'Play';
  @override
  String get challengeCompletedToast => 'Awesome! Daily challenge completed \uD83C\uDF89';

  // -- Revenge Mode --
  @override
  String get revengeMode => 'Revenge Mode';
  @override
  String revengeCount(int count) => '$count wrong cards waiting for you';
  @override
  String revengeClearedCount(int count) =>
      'Cleared $count wrong ${count == 1 ? "answer" : "answers"}!';
  @override
  String get revengeDetail => 'Revenge Detail';
  @override
  String get revengeLookbackDays => 'Lookback';
  @override
  String revengeDaysOption(int days) => '$days days';
  @override
  String get revengeFilterAll => 'All';
  @override
  String get revengeStats => 'Stats';
  @override
  String get revengeClearRate => 'Clear Rate';
  @override
  String get revengeMostWrong => 'Most Wrong';
  @override
  String revengeWrongTimes(int count) => '$count ${count == 1 ? "time" : "times"} wrong';
  @override
  String get revengeStartFlip => 'Flip Review';
  @override
  String get revengeStartQuiz => 'Quiz Mode';
  @override
  String get revengeNeedMoreCards => 'Need at least 4 wrong cards for quiz';
  @override
  String get revengeSelectSets => 'Select Study Sets';

  // -- Notifications --
  @override
  String get dailyReminder => 'Daily Review Reminder';
  @override
  String get dailyReminderDesc => 'Remind you to review at 20:00 daily';
  @override
  String get reminderTitle => 'Time to review!';
  @override
  String get reminderBody => 'You have cards to review. Open Recall now!';

  // -- Folders (F7) --
  @override
  String get folders => 'Folders';
  @override
  String get noFoldersYet => 'No folders yet';
  @override
  String get newFolder => 'New Folder';
  @override
  String get editFolder => 'Edit Folder';
  @override
  String get folderName => 'Folder Name';
  @override
  String get deleteFolder => 'Delete Folder?';
  @override
  String deleteFolderConfirm(String name) => 'Are you sure you want to delete "$name"?';
  @override
  String get color => 'Color';
  @override
  String get icon => 'Icon';
  @override
  String get moveToFolder => 'Move to Folder';
  @override
  String get noFolder => 'No Folder';
  @override
  String get pin => 'Pin';
  @override
  String get unpin => 'Unpin';

  // -- Sorting (F8) --
  @override
  String get sortNewest => 'Newest First';
  @override
  String get sortAlpha => 'Alphabetical';
  @override
  String get sortMostDue => 'Most Due';
  @override
  String get sortLastStudied => 'Last Studied';
  @override
  String get undo => 'Undo';

  // -- Onboarding (F9) --
  @override
  String get onboardingWelcome => 'Welcome to Recall';
  @override
  String get onboardingWelcomeDesc => 'Smart review, efficient memory';
  @override
  String get onboardingFeatures => 'Powerful Features';
  @override
  String get onboardingFeaturesDesc => 'Spaced repetition, daily challenges, photo to flashcard\nLearn more efficiently';
  @override
  String get onboardingStart => 'Let\'s Go!';
  @override
  String get onboardingStartDesc => 'Sign in to sync your data, or start as a guest';
  @override
  String get skip => 'Skip';
  @override
  String get next => 'Next';
  @override
  String get getStarted => 'Get Started';

  // -- QR Share (F10) --
  @override
  String get shareSet => 'Share Study Set';
  @override
  String get scanQr => 'Scan QR Code';
  @override
  String get scanToImport => 'Scan this QR code to import';
  @override
  String get linkCopied => 'Link copied';
  @override
  String get copyLink => 'Copy Link';
  @override
  String get share => 'Share';
  @override
  String get pointCameraAtQr => 'Point camera at QR code';
  @override
  String get qrInvalidData => 'Invalid QR code data';

  // -- Achievements (F11) --
  @override
  String get achievements => 'Achievements';
  @override
  String get badgesUnlocked => 'unlocked';
  @override
  String get badgeFirstReview => 'First Review';
  @override
  String get badgeFirstReviewDesc => 'Complete your first review';
  @override
  String get badgeStreak7 => '7-Day Streak';
  @override
  String get badgeStreak7Desc => 'Review for 7 consecutive days';
  @override
  String get badgeStreak30 => '30-Day Streak';
  @override
  String get badgeStreak30Desc => 'Review for 30 consecutive days';
  @override
  String get badgeReviews100 => '100 Reviews';
  @override
  String get badgeReviews100Desc => 'Complete 100 total reviews';
  @override
  String get badgeReviews1000 => '1000 Reviews';
  @override
  String get badgeReviews1000Desc => 'Complete 1000 total reviews';
  @override
  String get badgeMastered50 => 'Master 50';
  @override
  String get badgeMastered50Desc => 'Master 50 flashcards';
  @override
  String get badgeRevengeClear => 'Revenge Clear';
  @override
  String get badgeRevengeClearDesc => 'Clear the wrong answer pool once';
  @override
  String get badgeSets10 => 'Set Creator';
  @override
  String get badgeSets10Desc => 'Create 10 study sets';
  @override
  String get badgePerfectQuiz => 'Perfect Quiz';
  @override
  String get badgePerfectQuizDesc => 'Score 100% on a quiz';
  @override
  String get badgeChallenge30 => '30 Challenges';
  @override
  String get badgeChallenge30Desc => 'Complete 30 daily challenges';
  @override
  String get badgePhoto10 => 'Photo Pro';
  @override
  String get badgePhoto10Desc => 'Use photo import 10 times';
  @override
  String get badgeSpeedrun => 'Speed Match';
  @override
  String get badgeSpeedrunDesc => 'Finish matching game in under 30 seconds';
  @override
  String get badgeUnlocked => 'Badge unlocked!';

  // -- Pomodoro (F12) --
  @override
  String get pomodoro => 'Pomodoro';
  @override
  String get pomodoroDesc => 'Focus study timer';
  @override
  String get pomodoroStudy => 'Study';
  @override
  String get pomodoroShortBreak => 'Short Break';
  @override
  String get pomodoroLongBreak => 'Long Break';
  @override
  String get pomodoroReset => 'Reset';
  @override
  String get pomodoroStarted => 'Pomodoro started';
  @override
  String pomodoroSessions(int count) => '$count sessions completed';

  // -- Rating labels (SRS) --
  @override
  String get ratingAgain => 'Again';
  @override
  String get ratingHard => 'Hard';
  @override
  String get ratingGood => 'Good';
  @override
  String get ratingEasy => 'Easy';

  // -- Card Edit form --
  @override
  String get termLabel => 'Term';
  @override
  String get definitionInput => 'Definition';
  @override
  String get exampleSentenceLabel => 'Example sentence';
  @override
  String get deleteCard => 'Delete card';
  @override
  String get add => 'Add';
  @override
  String get tagNameHint => 'Tag name';

  // -- Matching result --
  @override
  String get pairsLabel => 'Pairs';
  @override
  String get attemptsLabel => 'Attempts';

  // -- Challenge detail (review summary) --
  @override
  String challengeCompleteDetail(int target) => 'Daily Challenge complete ($target cards).';
  @override
  String challengeProgressDetail(int reviewed, int target) => 'Daily Challenge progress: $reviewed/$target';

  // -- Auto-image --
  @override
  String autoImageProgress(int done, int total) => 'Fetching images... $done/$total';
  @override
  String autoImageDone(int count) => 'Updated $count images';
  @override
  String get autoImageCancelled => 'Image fetch cancelled';

  // -- Quiz Enhancement (A3) --
  @override
  String get typeYourAnswer => 'Type your answer';
  @override
  String get submit => 'Submit';
  @override
  String get trueLabel => 'True';
  @override
  String get falseLabel => 'False';
  @override
  String get isThisCorrect => 'Is this the correct definition?';
  @override
  String get correctAnswer => 'Correct answer';
  @override
  String get reinforcementRound => 'Reinforcement Round';
  @override
  String get reinforcementDesc => "Let's review the ones you missed!";
  @override
  String get almostCorrect => 'Almost! The correct answer is:';
  @override
  String wrongCount(int n) => '$n wrong';

  // -- Editor Upgrade (B2) --
  @override
  String get selectMode => 'Select';
  @override
  String get selectAll => 'Select All';
  @override
  String get deselectAll => 'Deselect All';
  @override
  String get deleteSelected => 'Delete Selected';
  @override
  String get addTagToSelected => 'Add Tag';
  @override
  String get removeTagFromSelected => 'Remove Tag';
  @override
  String nSelected(int n) => '$n selected';
  @override
  String get undoAction => 'Undo';
  @override
  String get redoAction => 'Redo';
  @override
  String get duplicateWarning => 'Duplicate cards found';
  @override
  String get blankWarning => 'Incomplete cards found';
  @override
  String get saveAnyway => 'Save Anyway';
  @override
  String get goBackToFix => 'Go Back';
  @override
  String cardNMissingField(int n, String field) => 'Card #$n: missing $field';
  @override
  String cardsAreDuplicates(int a, int b) => 'Cards #$a and #$b are duplicates';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations._create(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

