abstract final class AppRoutes {
  static const startup = '/startup';
  static const onboarding = '/onboarding';
  static const home = '/';
  static const trips = '/trips';
  static const ledger = '/ledger';
  static const settings = '/settings';
  static const scan = '/scan';
  static const paymentMethods = '/settings/payment-methods';
  static const paymentComparison = '/payment-comparison';
  static const dcc = '/dcc';
  static const tripCreate = '/trips/new';
  static String tripDetail(String id) => '/trips/$id';
  static String tripEdit(String id) => '/trips/$id/edit';
  static const expenseCreate = '/ledger/new';
  static String expenseDetail(String id) => '/ledger/$id';
}
