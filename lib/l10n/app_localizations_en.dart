// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TripCost';

  @override
  String get homeTab => 'Home';

  @override
  String get tripsTab => 'Trips';

  @override
  String get ledgerTab => 'Ledger';

  @override
  String get settingsTab => 'Settings';

  @override
  String get scanAction => 'Scan';

  @override
  String get homeTitle => 'Understand the real cost';

  @override
  String get homeSubtitle =>
      'Convert a local price and compare payment methods.';

  @override
  String get tripsTitle => 'Trips';

  @override
  String get tripsSubtitle =>
      'Trip budgets and offline packs will appear here.';

  @override
  String get ledgerTitle => 'Ledger';

  @override
  String get ledgerSubtitle =>
      'Saved expenses and actual charges will appear here.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle =>
      'Currency, rates, payments, sync, and privacy.';

  @override
  String get scanTitle => 'Scan a price';

  @override
  String get scanSubtitle =>
      'Choose a camera photo or an image, then confirm every detected price before comparing payment methods.';

  @override
  String get scanCamera => 'Camera';

  @override
  String get scanPhotoLibrary => 'Photos';

  @override
  String get scanPrivacy =>
      'Recognition runs on this device. The original image is not uploaded.';

  @override
  String get scanRecognizing => 'Recognizing text on this device…';

  @override
  String get scanDetectedPrices => 'Detected prices';

  @override
  String get scanSelectHint =>
      'Select one price, or select several to add them together.';

  @override
  String get scanLowConfidence => 'Low confidence · review this value';

  @override
  String get scanManualEntry => 'Enter an amount manually';

  @override
  String get scanAmount => 'Amount';

  @override
  String get scanChooseCurrency => 'Choose currency';

  @override
  String get scanInvalidEdit => 'Enter a valid amount and choose a currency.';

  @override
  String get scanCurrencyRequired =>
      'Choose a currency for every selected price.';

  @override
  String get scanMixedCurrencies =>
      'Selected prices use different currencies. Edit them before continuing.';

  @override
  String scanSelectedTotal(String currency, String amount) {
    return 'Selected total · $currency $amount';
  }

  @override
  String get scanContinue => 'Compare payment methods';

  @override
  String get scanPermissionDenied =>
      'Access was not granted. Choose the other image source or enter the amount manually.';

  @override
  String get scanImageUnavailable =>
      'This image is no longer available. Choose it again or enter the amount manually.';

  @override
  String get scanRecognitionFailed =>
      'The image could not be recognized. Try another image or enter the amount manually.';

  @override
  String get scanNoCandidates =>
      'No prices were found. Try another image or enter the amount manually.';

  @override
  String get scanRateUnavailable =>
      'No reference rate is available for this currency. Enter a manual rate on Home, then try again.';

  @override
  String get languageTitle => 'Language';

  @override
  String get systemLanguage => 'System default';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get scaffoldNotice => 'Project scaffold ready';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start exploring';

  @override
  String get onboardingScanTitle => 'Understand prices instantly';

  @override
  String get onboardingScanSubtitle =>
      'Scan price tags, menus, and receipts to make foreign prices easier to understand.';

  @override
  String get onboardingCompareTitle => 'Compare the cost to pay';

  @override
  String get onboardingCompareSubtitle =>
      'Include fees and rewards to compare the estimated cost of each payment method.';

  @override
  String get onboardingBudgetTitle => 'Keep every trip on budget';

  @override
  String get onboardingBudgetSubtitle =>
      'Add expenses to a trip and see how much of your travel budget remains.';

  @override
  String get converterInputLabel => 'Local price or expression';

  @override
  String get converterInputHint => 'For example: 1200 * 3 + 500';

  @override
  String get converterResultLabel => 'Reference conversion';

  @override
  String get converterInvalidExpression =>
      'Check the expression and edit it in place.';

  @override
  String get converterPositiveAmount => 'Enter an amount greater than zero.';

  @override
  String get converterRateLoading => 'Finding the latest reference rate…';

  @override
  String get converterRateUnavailable =>
      'No reference rate is available. Add a manual rate to continue.';

  @override
  String converterRateLive(String source, String time) {
    return 'Latest reference rate · $source · $time';
  }

  @override
  String converterRateCached(String time, String source) {
    return 'Cached at $time · $source';
  }

  @override
  String converterRateStale(String time) {
    return 'Older cache from $time · review before paying';
  }

  @override
  String get converterRateManual => 'Using your manual reference rate';

  @override
  String converterRateCard(String source, String time) {
    return 'Card-network reference · $source · $time';
  }

  @override
  String get converterRateIdentity => 'Same currency · rate 1';

  @override
  String get converterManualRate => 'Enter manual rate';

  @override
  String get converterManualRateHint =>
      '1 local currency = how much home currency';

  @override
  String get converterRefresh => 'Refresh rate';

  @override
  String get converterCompare => 'Compare payment methods';

  @override
  String get converterDcc => 'Check DCC';

  @override
  String get converterRecentTitle => 'Recent expenses';

  @override
  String get converterRecentEmpty => 'Saved expenses will appear here.';

  @override
  String get currencyLocal => 'Transaction currency';

  @override
  String get currencyHome => 'Home currency';

  @override
  String get currencyFavorite => 'Favorite currency';

  @override
  String get currencyUnfavorite => 'Remove favorite';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDone => 'Done';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonEstimated => 'Estimated';

  @override
  String get paymentMethodsTitle => 'Payment methods';

  @override
  String get paymentMethodsSubtitle =>
      'Store fee rules only. Never enter card numbers, expiry dates, CVV, identity, or banking credentials.';

  @override
  String get paymentMethodsEmpty =>
      'Add cash or a card to compare estimated costs.';

  @override
  String get paymentAddTitle => 'Add payment method';

  @override
  String get paymentEditName => 'Name';

  @override
  String get paymentType => 'Type';

  @override
  String get paymentNetwork => 'Card network';

  @override
  String get paymentBillingCurrency => 'Billing currency';

  @override
  String get paymentTemplate => 'Template';

  @override
  String get paymentForeignFee => 'Foreign conversion fee %';

  @override
  String get paymentCrossBorderFee => 'Cross-border fee %';

  @override
  String get paymentRateMarkup => 'Exchange-rate markup %';

  @override
  String get paymentFixedFee => 'Fixed fee';

  @override
  String get paymentCashback => 'Cashback %';

  @override
  String get paymentMinimumFee => 'Minimum variable fee (optional)';

  @override
  String get paymentMaximumFee => 'Maximum variable fee (optional)';

  @override
  String get paymentCashRate => 'Actual cash exchange rate (optional)';

  @override
  String get paymentNotes => 'Notes (optional)';

  @override
  String get paymentTransactionScope => 'Applies to';

  @override
  String get paymentPurchase => 'Purchases';

  @override
  String get paymentAtm => 'ATM';

  @override
  String get paymentAll => 'Purchases and ATM';

  @override
  String get paymentTypeCredit => 'Credit card';

  @override
  String get paymentTypeDebit => 'Debit card';

  @override
  String get paymentTypeCash => 'Cash';

  @override
  String get paymentTypeWallet => 'Digital wallet';

  @override
  String get paymentTypeCustom => 'Custom';

  @override
  String get paymentNetworkUnknown => 'Unknown';

  @override
  String get paymentNetworkOther => 'Other';

  @override
  String get paymentInvalidForm =>
      'Check the name, non-negative rates and fee limits.';

  @override
  String get paymentDeleteTitle => 'Delete this payment method?';

  @override
  String get paymentDeleteMessage =>
      'Historical expense snapshots remain unchanged.';

  @override
  String get paymentPolicyNotice =>
      'Generic estimate only. Bank and card-network policies may change.';

  @override
  String get paymentComparisonTitle => 'Estimated payment costs';

  @override
  String get paymentComparisonMissing =>
      'Start from a valid conversion to compare costs.';

  @override
  String get paymentComparisonNeedTwo =>
      'Add at least two applicable methods for a useful comparison.';

  @override
  String get paymentRecommended => 'Lowest estimated cost';

  @override
  String paymentDifference(String amount) {
    return '+$amount vs lowest';
  }

  @override
  String get paymentBaseAmount => 'Base conversion';

  @override
  String get paymentRateMarkupAmount => 'Rate markup';

  @override
  String get paymentForeignFeeAmount => 'Foreign conversion fee';

  @override
  String get paymentCrossBorderFeeAmount => 'Cross-border fee';

  @override
  String get paymentVariableFee => 'Variable fee after limits';

  @override
  String get paymentFixedFeeAmount => 'Fixed fee';

  @override
  String get paymentCashbackAmount => 'Estimated cashback';

  @override
  String get paymentEstimatedTotal => 'Estimated total';

  @override
  String get paymentCashRateUsed => 'Uses your actual cash exchange rate';

  @override
  String get paymentEstimateDisclaimer =>
      'All figures are estimates. Final charges depend on the merchant, card network, issuer and posting date.';

  @override
  String get dccTitle => 'DCC check';

  @override
  String get dccLocalAmount => 'Local-currency amount';

  @override
  String get dccMerchantQuote => 'Merchant home-currency quote';

  @override
  String get dccOptionalPayment => 'Payment method (optional)';

  @override
  String get dccNoPayment => 'No payment method';

  @override
  String get dccImpliedRate => 'Merchant implied rate';

  @override
  String get dccReferenceRate => 'Reference rate';

  @override
  String get dccReferenceAmount => 'Reference conversion';

  @override
  String get dccExtraAmount => 'DCC extra amount';

  @override
  String get dccExtraPercent => 'DCC extra percentage';

  @override
  String get dccLocalPaymentEstimate =>
      'Estimated cost if paying in local currency';

  @override
  String dccGuidanceHigher(String percent) {
    return 'The merchant quote is about $percent% above the current reference conversion. Paying in local currency is usually more transparent, but the final charge still depends on the issuer.';
  }

  @override
  String get dccGuidanceLower =>
      'The merchant quote is not above the current reference conversion. This is still only a comparison; verify the currency and final amount on the terminal.';

  @override
  String get dccInvalidLocal => 'Enter a local amount greater than zero.';

  @override
  String get dccInvalidQuote => 'Enter a merchant quote greater than zero.';

  @override
  String get dccSameCurrency => 'DCC requires two different currencies.';

  @override
  String get dccMissingRate =>
      'A reference rate is required before checking DCC.';

  @override
  String get templateNoForeignFee => 'No foreign-fee card';

  @override
  String get templateOnePercent => '1% fee card';

  @override
  String get templateOnePointFivePercent => '1.5% fee card';

  @override
  String get templateTwoPercent => '2% fee card';

  @override
  String get templateUnionPayCny => 'UnionPay CNY billing card';

  @override
  String get templateCash => 'Cash exchange';

  @override
  String get templateCustom => 'Fully custom';

  @override
  String get onboardingHomeCurrency => 'Suggested home currency';

  @override
  String get onboardingCreateTrip => 'Create a trip';

  @override
  String get onboardingAddPayment => 'Add payment method';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonNone => 'None';

  @override
  String get commonAll => 'All';

  @override
  String get tripCreate => 'New trip';

  @override
  String get tripEdit => 'Edit trip';

  @override
  String get tripCopy => 'Copy configuration';

  @override
  String get tripArchive => 'Archive';

  @override
  String get tripDeleteTitle => 'Delete this trip?';

  @override
  String get tripDeleteMessage =>
      'Expenses and receipt references stay in the ledger without this trip. This cannot be undone.';

  @override
  String get tripName => 'Trip name';

  @override
  String get tripDestinations => 'Countries or regions';

  @override
  String get tripDestinationsHint => 'For example: JP, KR';

  @override
  String get tripStartDate => 'Start date';

  @override
  String get tripEndDate => 'End date';

  @override
  String get tripLocalCurrencies => 'Local currencies';

  @override
  String get tripBudget => 'Total budget';

  @override
  String get tripBudgetOptional => 'Optional; zero is allowed';

  @override
  String get tripParticipants => 'Travelers';

  @override
  String get tripDefaultPayment => 'Default payment method';

  @override
  String get tripOfflinePack => 'Offline rate pack';

  @override
  String get tripOfflinePackHint =>
      'Prepare the selected local and home currency pair without requesting location.';

  @override
  String get tripInvalid =>
      'Check the name, dates, currencies, budget and traveler count.';

  @override
  String get tripActive => 'In progress';

  @override
  String get tripUpcoming => 'Upcoming';

  @override
  String get tripHistory => 'History';

  @override
  String get tripMissing => 'This trip is no longer available.';

  @override
  String get tripNoBudget => 'No budget';

  @override
  String get tripSpent => 'Spent';

  @override
  String get tripRemaining => 'Remaining';

  @override
  String get tripDailyRemaining => 'Remaining per day';

  @override
  String get tripDayProgress => 'Trip days';

  @override
  String get tripDailyAverage => 'Current daily average';

  @override
  String get tripPaymentBreakdown => 'Payment-method breakdown';

  @override
  String get tripOfflineReady => 'Offline pack ready';

  @override
  String get tripOfflineMissing => 'Offline pack not downloaded';

  @override
  String get expenseManualAdd => 'Add expense';

  @override
  String get expenseSave => 'Save expense';

  @override
  String get expenseRecent => 'Recent expenses';

  @override
  String get expenseTitle => 'Merchant or item';

  @override
  String get expenseTrip => 'Trip';

  @override
  String get expenseCategory => 'Category';

  @override
  String get expenseTransactionAmount => 'Original amount';

  @override
  String get expenseReferenceAmount => 'Reference conversion';

  @override
  String get expenseEstimatedAmount => 'Estimated final amount';

  @override
  String get expenseActualAmount => 'Actual posted amount';

  @override
  String get expensePaymentMethod => 'Payment method';

  @override
  String get expenseTax => 'Tax in home currency';

  @override
  String get expenseTip => 'Tip in home currency';

  @override
  String get expenseDiscount => 'Discount in home currency';

  @override
  String get expenseDate => 'Transaction date';

  @override
  String get expenseReceiptPath => 'Receipt local path (optional)';

  @override
  String get expenseNotes => 'Notes';

  @override
  String get expenseBudgetIncluded => 'Include in trip budget';

  @override
  String get expenseStatus => 'Status';

  @override
  String get expenseConfirmed => 'Confirmed';

  @override
  String get expenseInvalid =>
      'Check the title, positive amounts, currencies and traveler count.';

  @override
  String get expenseDuplicateTitle => 'Possible duplicate expense';

  @override
  String get expenseDuplicateMessage =>
      'A matching expense was saved within five minutes. Save another copy?';

  @override
  String get expenseSaveAnyway => 'Save anyway';

  @override
  String get expenseMissing => 'This expense is no longer available.';

  @override
  String get expenseDifference => 'Difference from estimate';

  @override
  String get expenseRateSnapshot => 'Saved rate snapshot';

  @override
  String get expensePaymentSnapshot => 'Saved fee-rule snapshot';

  @override
  String get expenseActualConflict =>
      'Two actual posted amounts need conflict resolution before sync can continue.';

  @override
  String get expenseRecordActual => 'Record actual amount';

  @override
  String get expenseAdjust => 'Refund or void';

  @override
  String get expenseRefund => 'Refund';

  @override
  String get expensePartialRefund => 'Partial refund';

  @override
  String get expenseVoid => 'Voided';

  @override
  String get expenseRefundInvalid =>
      'The refund must be greater than zero and cannot exceed the original posted or estimated amount.';

  @override
  String get expenseManualRateSource => 'Manual ledger rate';

  @override
  String get expenseManualPaymentRule => 'Manual entry';

  @override
  String get ledgerTimeline => 'Timeline';

  @override
  String get ledgerCalendar => 'Calendar';

  @override
  String get ledgerCategories => 'Categories';

  @override
  String get ledgerFilters => 'Filters';

  @override
  String get ledgerClearFilters => 'Clear';

  @override
  String get ledgerEmpty => 'No matching expenses yet.';

  @override
  String get ledgerMinimumAmount => 'Minimum amount';

  @override
  String get ledgerMaximumAmount => 'Maximum amount';

  @override
  String get ledgerInvalidFilters => 'Enter a valid non-negative amount range.';

  @override
  String ledgerFilteredCount(int count) {
    return '$count expenses';
  }

  @override
  String ledgerRecentDays(int count) {
    return 'Last $count days';
  }

  @override
  String get calibrationNone =>
      'Record an actual amount to build a local fee comparison.';

  @override
  String calibrationRange(int count, String minimum, String maximum) {
    return 'Recent $count comparable charges: $minimum% to $maximum% markup. Three or more records are required before suggesting a rule change.';
  }

  @override
  String calibrationRangeReady(int count, String minimum, String maximum) {
    return 'Recent $count comparable charges: $minimum% to $maximum% markup. Review them before manually changing the rule.';
  }

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryHotel => 'Hotel';

  @override
  String get categoryTickets => 'Tickets';

  @override
  String get categoryOther => 'Other';

  @override
  String get syncTitle => 'iCloud sync';

  @override
  String get syncEnable => 'Sync structured data with iCloud';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncStatusDisabled => 'Sync is off. Local data is unchanged.';

  @override
  String get syncStatusIdle => 'Ready to sync';

  @override
  String get syncStatusWorking => 'Syncing…';

  @override
  String get syncStatusSucceeded => 'Up to date';

  @override
  String get syncStatusWaiting => 'Waiting to retry';

  @override
  String get syncStatusFailed => 'Sync failed. Local data remains available.';

  @override
  String get syncStatusNoAccount => 'Sign in to iCloud to sync.';

  @override
  String get syncStatusRestricted => 'iCloud is restricted on this device.';

  @override
  String syncLastSuccess(String value) {
    return 'Last successful sync: $value';
  }

  @override
  String syncFailureReason(String value) {
    return 'Reason: $value';
  }

  @override
  String get syncActualConflict => 'Two posted amounts need your choice.';

  @override
  String syncConflictValues(String local, String remote) {
    return 'On this device: $local · In iCloud: $remote';
  }

  @override
  String get syncKeepLocal => 'Keep this device';

  @override
  String get syncUseCloud => 'Use iCloud';
}
