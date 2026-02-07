class AppStrings {
  AppStrings._();

  static const amountUnit = 'えん';

  static String amountWithUnit(String amount) => '$amount$amountUnit';
  static String amountWithUnitInt(int amount) => '$amount$amountUnit';
}
