/// Decimal rounding helpers shared by the offline conversion kernels.
///
/// The server quantizes decimal input with Python's `ROUND_HALF_UP`. Parsing
/// the shortest decimal representation of a Dart double before rounding avoids
/// binary floating-point values such as `1.005 * 100 == 100.499...` changing a
/// boundary result.
library;

/// Scale a decimal input by an integer ratio without first multiplying it as
/// a binary floating-point number. This matches
/// `Decimal(str(value)) * numerator / denominator` on the server.
double scaleByIntegerRatio(
  double value,
  int numerator,
  int denominator, {
  int fractionDigits = 12,
}) {
  if (numerator < 0 || denominator <= 0) {
    throw ArgumentError('比例必须是非负分子和正分母');
  }
  if (!value.isFinite) {
    throw ArgumentError.value(value, 'value', '必须是有限数');
  }
  if (fractionDigits < 0) {
    throw ArgumentError.value(fractionDigits, 'fractionDigits', '必须是非负整数');
  }

  final (digits, decimalScale) = _decimalParts(value.abs());
  var scaledNumerator = digits * BigInt.from(numerator);
  var scaledDenominator = BigInt.from(denominator);
  if (decimalScale >= 0) {
    scaledDenominator *= _tenPower(decimalScale);
  } else {
    scaledNumerator *= _tenPower(-decimalScale);
  }
  return _scaleRational(
    scaledNumerator,
    scaledDenominator,
    fractionDigits: fractionDigits,
    negative: value.isNegative,
  );
}

/// Multiply two finite doubles as the decimals they print as, matching the
/// server's `Decimal(str(value)) * Decimal(str(ratio))`, then keep
/// [fractionDigits] places (half-up) so later display rounding sees the exact
/// product instead of a binary approximation such as `1.7249999999999999`.
double scaleByDecimalRatio(
  double value,
  double ratio, {
  int fractionDigits = 12,
}) {
  if (!value.isFinite || !ratio.isFinite) {
    throw ArgumentError('数值和比例都必须是有限数');
  }
  if (fractionDigits < 0) {
    throw ArgumentError.value(fractionDigits, 'fractionDigits', '必须是非负整数');
  }
  final (valueDigits, valueScale) = _decimalParts(value.abs());
  final (ratioDigits, ratioScale) = _decimalParts(ratio.abs());
  var numerator = valueDigits * ratioDigits;
  var denominator = BigInt.one;
  final scale = valueScale + ratioScale;
  if (scale >= 0) {
    denominator = _tenPower(scale);
  } else {
    numerator *= _tenPower(-scale);
  }
  return _scaleRational(
    numerator,
    denominator,
    fractionDigits: fractionDigits,
    negative: value.isNegative != ratio.isNegative,
  );
}

/// Divide two finite doubles as the decimals they print as, matching the
/// server's `Decimal(str(value)) / Decimal(str(divisor))` before rounding.
double divideByDecimalRatio(
  double value,
  double divisor, {
  int fractionDigits = 12,
}) {
  if (!value.isFinite || !divisor.isFinite) {
    throw ArgumentError('数值和除数都必须是有限数');
  }
  if (divisor == 0) {
    throw ArgumentError.value(divisor, 'divisor', '除数不能为零');
  }
  if (fractionDigits < 0) {
    throw ArgumentError.value(fractionDigits, 'fractionDigits', '必须是非负整数');
  }
  final (valueDigits, valueScale) = _decimalParts(value.abs());
  final (divisorDigits, divisorScale) = _decimalParts(divisor.abs());
  var numerator = valueDigits;
  var denominator = divisorDigits;
  if (divisorScale >= 0) {
    numerator *= _tenPower(divisorScale);
  } else {
    denominator *= _tenPower(-divisorScale);
  }
  if (valueScale >= 0) {
    denominator *= _tenPower(valueScale);
  } else {
    numerator *= _tenPower(-valueScale);
  }
  return _scaleRational(
    numerator,
    denominator,
    fractionDigits: fractionDigits,
    negative: value.isNegative != divisor.isNegative,
  );
}

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
    throw ArgumentError.value(fractionDigits, 'fractionDigits', '必须是非负整数');
  }

  final text = value.abs().toString().toLowerCase();
  final exponentParts = text.split('e');
  final mantissa = exponentParts.first;
  final exponent = exponentParts.length == 2 ? int.parse(exponentParts[1]) : 0;
  final dot = mantissa.indexOf('.');
  final mantissaFractionDigits = dot == -1 ? 0 : mantissa.length - dot - 1;
  final digitsText = mantissa.replaceAll('.', '');
  final digits = BigInt.parse(digitsText);
  final shift = exponent - mantissaFractionDigits + fractionDigits;

  final scaled = shift >= 0
      ? digits * _tenPower(shift)
      : _roundQuotient(digits, _tenPower(-shift));
  final rounded = _scaledIntegerToDouble(scaled, fractionDigits);
  return value.isNegative ? -rounded : rounded;
}

(BigInt, int) _decimalParts(double value) {
  final text = value.toString().toLowerCase();
  final exponentParts = text.split('e');
  final mantissa = exponentParts.first;
  final exponent = exponentParts.length == 2 ? int.parse(exponentParts[1]) : 0;
  final dot = mantissa.indexOf('.');
  final mantissaFractionDigits = dot == -1 ? 0 : mantissa.length - dot - 1;
  return (
    BigInt.parse(mantissa.replaceAll('.', '')),
    mantissaFractionDigits - exponent,
  );
}

double _scaleRational(
  BigInt numerator,
  BigInt denominator, {
  required int fractionDigits,
  required bool negative,
}) {
  final scaledNumerator = numerator * _tenPower(fractionDigits);
  final rounded = _roundRational(scaledNumerator, denominator);
  final result = _scaledIntegerToDouble(rounded, fractionDigits);
  return negative ? -result : result;
}

double _scaledIntegerToDouble(BigInt value, int fractionDigits) {
  if (fractionDigits == 0) return value.toDouble();
  final padded = value.toString().padLeft(fractionDigits + 1, '0');
  final split = padded.length - fractionDigits;
  return double.parse(
    '${padded.substring(0, split)}.${padded.substring(split)}',
  );
}

BigInt _roundRational(BigInt numerator, BigInt denominator) {
  final quotient = numerator ~/ denominator;
  final remainder = numerator % denominator;
  return remainder * BigInt.from(2) >= denominator
      ? quotient + BigInt.one
      : quotient;
}

BigInt _roundQuotient(BigInt numerator, BigInt denominator) =>
    _roundRational(numerator, denominator);

BigInt _tenPower(int exponent) {
  var result = BigInt.one;
  for (var i = 0; i < exponent; i++) {
    result *= BigInt.from(10);
  }
  return result;
}
