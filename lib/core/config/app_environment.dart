import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppFlavor { development, production }

class AppEnvironment {
  const AppEnvironment({required this.apiBaseUrl, required this.flavor});

  factory AppEnvironment.fromDefines() {
    const flavorValue = String.fromEnvironment(
      'APP_FLAVOR',
      defaultValue: 'development',
    );
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.frankfurter.dev',
    );

    return AppEnvironment(
      apiBaseUrl: Uri.parse(apiBaseUrl),
      flavor: flavorValue == 'production'
          ? AppFlavor.production
          : AppFlavor.development,
    );
  }

  final Uri apiBaseUrl;
  final AppFlavor flavor;
}

final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => AppEnvironment.fromDefines(),
);
