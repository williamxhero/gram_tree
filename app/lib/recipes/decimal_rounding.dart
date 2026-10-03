/// Decimal rounding helpers shared by the offline conversion kernels.
///
/// The server quantizes decimal input with Python's `ROUND_HALF_UP`. Parsing
/// the shortest decimal representation of a Dart double before rounding avoids
/// binary floating-point values such as `1.005 * 100 == 100.499...` changing a
/// boundary result.
library;

/// Round [value] to [fractionDigits] decimal places, half away from zero.
///
/// This matches `Decimal(str(value)).quantize(..., ROUND_HALF_UP)` for finite
/// values received from JSON. Conversion inputs are non-negative, but the
/// sign is retained so the helper remains useful for general numeric output.
double roundHalfUp(double value, {int fractionDigits = 2}) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, 'value', '必须是有限数');
  }
  if (fractionDigits < 0) {
    throw ArgumentError.value(
      fractionDigits,
      'fractionDigits',
      '必须是非负整数',
    );
  }

  final text = value.abs().toString().toLowerCase();
  final exponentParts = text.split('e');
  final mantissa = exponentParts.first;
  final exponent = exponentParts.length == 2
      ? int.parse(exponentParts[1])
      : 0;
  final dot = mantissa.indexOf('.');
  final mantissaFractionDigits = dot == -1 ? 0 : mantissa.length - dot - 1;
  final digitsText = mantissa.replaceAll('.', '');
  final digits = BigInt.parse(digitsText);
  final shift = exponent - mantissaFractionDigits + fractionDigits;

  final scaled = shift >= 0
      ? digits * _tenPower(shift)
      : _roundQuotient(digits, _tenPower(-shift));
  final scale = _tenPower(fractionDigits);
  final rounded = scaled.toDouble() / scale.toDouble();
  return value.isNegative ? -rounded : rounded;
}

BigInt _roundQuotient(BigInt numerator, BigInt denominator) {
  final quotient = numerator ~/ denominator;
  final remainder = numerator % denominator;
  return remainder * BigInt.from(2) >= denominator
      ? quotient + BigInt.one
      : quotient;
}

BigInt _tenPower(int exponent) {
  var result = BigInt.one;
  for (var i = 0; i < exponent; i++) {
    result *= BigInt.from(10);
  }
  return result;
}
