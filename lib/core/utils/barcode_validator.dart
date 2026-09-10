/// Barcode normalization + validation aligned with the official Open Food
/// Facts smooth-app (`ContinuousScanModel._fixBarcodeIfNecessary` / `onScan`):
///
///  - formatting characters are stripped (dashes removed, whitespace trimmed);
///  - 12-character UPC-A codes are promoted to EAN-13 with a leading '0'
///    (OFF indexes both forms under the EAN-13 form);
///  - codes shorter than [minLength] are not product barcodes and are ignored.
class BarcodeValidator {
  const BarcodeValidator._();

  /// Minimum length accepted by the smooth-app scan pipeline.
  static const int minLength = 4;

  /// Returns the normalized barcode, or null when the raw scanner value cannot
  /// be a product barcode (mirrors smooth-app's silent ignore — no user
  /// feedback, the scanner simply keeps searching).
  static String? normalizeForScan(String? code) {
    if (code == null) return null;
    var fixed = code.replaceAll('-', '').trim();
    if (fixed.isEmpty) return null;
    if (fixed.length == 12) fixed = '0$fixed';
    return fixed.length < minLength ? null : fixed;
  }
}
