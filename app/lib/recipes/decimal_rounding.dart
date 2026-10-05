/// Decimal rounding helpers shared by the offline conversion kernels.
///
/// The server quantizes decimal input with Python's `ROUND_HALF_UP`. Parsing
/// the shortest decimal representation of a Dart double before rounding avoids
/// binary floating-point values such as `1.005 * 100 == 100.499...` changing a
/// boundary result.
library;

/// Scale a decimal input by an integer ratio without first multiplying it as
/// a binary floating-point number. This matches
/// `Decimal(str(value)) * (Decimal(numerator) / Decimal(denominator))`
/// in the server's default 28-significant-digit context.
double scaleByIntegerRatio(
  double value,
  int numerator,
  int denominator, {
  int fractionDigits = 12,
  int contextPrecision = 28,
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

  final ratio = DecimalValue.fromNum(
    numerator,
  ).dividedBy(DecimalValue.fromNum(denominator), precision: contextPrecision);
  final product = DecimalValue.fromNum(value.abs())
      .multipliedBy(ratio, precision: contextPrecision);
  final rounded = product.quantizedHalfUp(fractionDigits).toDouble();
  return value.isNegative ? -rounded : rounded;
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

/// Non-negative Decimal arithmetic matching Python's default context: 28
/// significant digits with half-even arithmetic, then half-up quantization.
class DecimalValue {
  const DecimalValue._(this.coefficient, this.exponent);

  factory DecimalValue.fromNum(num value) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(value, 'value', '必须是有限非负数');
    }
    if (value is int) return DecimalValue._(BigInt.from(value), 0);
    final (digits, scale) = _decimalParts(value.toDouble());
    return DecimalValue._(digits, -scale);
  }

  final BigInt coefficient;
  final int exponent;

  bool get isZero => coefficient == BigInt.zero;

  bool get isOne => compareTo(DecimalValue.fromNum(1)) == 0;

  DecimalValue multipliedBy(DecimalValue other, {int precision = 28}) =>
      _contextMultiply(this, other, precision);

  DecimalValue dividedBy(DecimalValue other, {int precision = 28}) =>
      _contextDivide(this, other, precision);

  DecimalValue quantizedHalfUp(int fractionDigits) {
    if (fractionDigits < 0) {
      throw ArgumentError.value(fractionDigits, 'fractionDigits', '必须是非负整数');
    }
    final shift = exponent + fractionDigits;
    final rounded = shift >= 0
        ? coefficient * _tenPower(shift)
        : _roundRational(coefficient, _tenPower(-shift));
    return DecimalValue._(rounded, -fractionDigits);
  }

  int compareTo(DecimalValue other) {
    final commonExponent = exponent < other.exponent
        ? exponent
        : other.exponent;
    final left = coefficient * _tenPower(exponent - commonExponent);
    final right =
        other.coefficient * _tenPower(other.exponent - commonExponent);
    return left.compareTo(right);
  }

  double toDouble() => double.parse(toString());

  @override
  String toString() {
    final digits = coefficient.toString();
    if (exponent >= 0) return '$digits${'0' * exponent}';
    final scale = -exponent;
    final padded = digits.padLeft(scale + 1, '0');
    final split = padded.length - scale;
    return '${padded.substring(0, split)}.${padded.substring(split)}';
  }
}

DecimalValue _contextMultiply(
  DecimalValue left,
  DecimalValue right,
  int precision,
) => _roundSignificant(
  DecimalValue._(
    left.coefficient * right.coefficient,
    left.exponent + right.exponent,
  ),
  precision,
);

DecimalValue _contextDivide(
  DecimalValue numerator,
  DecimalValue denominator,
  int precision,
) {
  if (precision < 1) throw ArgumentError.value(precision, 'precision');
  if (denominator.coefficient == BigInt.zero) {
    throw ArgumentError('除数不能为零');
  }
  if (numerator.coefficient == BigInt.zero) {
    return DecimalValue._(BigInt.zero, 0);
  }
  final numeratorDigits = numerator.coefficient.toString().length;
  final denominatorDigits = denominator.coefficient.toString().length;
  var order = numeratorDigits - denominatorDigits;
  final belowPower = order >= 0
      ? numerator.coefficient < denominator.coefficient * _tenPower(order)
      : numerator.coefficient * _tenPower(-order) < denominator.coefficient;
  if (belowPower) order--;
  // Round the exact quotient once at its final significant-digit position.
  // Rounding guard digits first could move a value onto a half-even tie.
  final shift = precision - 1 - order;
  final scaledNumerator = shift >= 0
      ? numerator.coefficient * _tenPower(shift)
      : numerator.coefficient;
  final scaledDenominator = shift >= 0
      ? denominator.coefficient
      : denominator.coefficient * _tenPower(-shift);
  return DecimalValue._(
    _roundRationalHalfEven(scaledNumerator, scaledDenominator),
    numerator.exponent - denominator.exponent - shift,
  );
}

DecimalValue _roundSignificant(DecimalValue value, int precision) {
  if (precision < 1) throw ArgumentError.value(precision, 'precision');
  final digits = value.coefficient.toString().length;
  if (value.coefficient == BigInt.zero || digits <= precision) return value;
  final remove = digits - precision;
  final divisor = _tenPower(remove);
  return DecimalValue._(
    _roundRationalHalfEven(value.coefficient, divisor),
    value.exponent + remove,
  );
}

BigInt _roundRationalHalfEven(BigInt numerator, BigInt denominator) {
  final quotient = numerator ~/ denominator;
  final remainder = numerator % denominator;
  final doubled = remainder * BigInt.from(2);
  if (doubled > denominator) return quotient + BigInt.one;
  if (doubled < denominator) return quotient;
  return quotient.isEven ? quotient : quotient + BigInt.one;
}
