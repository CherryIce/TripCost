# Temporary startup artwork

These assets are temporary and can be replaced without changing the startup
state or routing logic:

- `branding/launch_mark.png`: Flutter startup mark.
- `onboarding/scan_price.png`: scan-prices onboarding illustration.
- `onboarding/compare_payments.png`: payment-comparison illustration.
- `onboarding/track_budget.png`: trip-budget illustration.

The native iOS launch mark is stored separately as light/dark 1x, 2x, and 3x
files under `ios/Runner/Assets.xcassets/LaunchImage.imageset`. Keep its visible
size at 96 points and preserve transparent padding when replacing it so the
native screen and Flutter first frame remain aligned.
