/// Defines the available scanning modes in the GutGood app.
enum ScannerMode { barcode, food, menu, label }

class ScannerModeOption {
  const ScannerModeOption({required this.mode, required this.label});
  final ScannerMode mode;
  final String label;
}
