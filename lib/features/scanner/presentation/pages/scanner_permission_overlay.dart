part of 'super_scanner_screen.dart';

/// Scanner permission overlay component.

class _PermissionOverlay extends StatelessWidget {
  const _PermissionOverlay();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    appBar: AppBar(
      backgroundColor: AppPalette.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(AppIcons.x, color: context.appColorScheme.textPrimary),
        onPressed: () => context.pop(),
      ),
    ),
    body: Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.r20),
              child: Image.asset(AppAssets.appIcon, height: AppSizes.p100, width: AppSizes.p100),
            ),
            Gap.h32,
            Text(
              AppStrings.allowCameraAccess,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMd.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.bold),
            ),
            Gap.h16,
            Text(
              AppStrings.cameraAccessSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.4),
            ),
            Gap.h32,
            GutButton(
              label: AppStrings.allowCameraAccess,
              onTap: () async {
                final state = context.findAncestorStateOfType<_SuperScannerScreenState>();
                await state?._requestPermission();
              },
            ),
            Gap.h10,
            GutButton(
              isOutlined: true,
              label: AppStrings.openSettings,
              onTap: () async {
                unawaited(openAppSettings());
              },
            ),
          ],
        ),
      ),
    ),
  );
}
