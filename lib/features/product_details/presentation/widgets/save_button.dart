part of 'scan_result_widgets.dart';

/// Save action presentation component.

class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.isSaved, required this.isLoading, required this.onTap});
  final bool isSaved;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      margin: EdgeInsets.only(right: 10.w),
      width: 40.w,
      height: 40.w,
      child: isLoading
          ? const Center(
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.black)),
            )
          : Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? AppPalette.red : AppPalette.black, size: 20),
    ),
  );
}
