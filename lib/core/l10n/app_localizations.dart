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

