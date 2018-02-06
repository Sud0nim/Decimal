import math, bigints, strutils

type
  Rounding* {. pure .} = enum
    Down, 
    HalfUp, 
    HalfEven,
    Ceiling, 
    Floor, 
    HalfDown,
    Up, 
    Up05,
  Signal* {. pure .} = enum
    Clamped, 
    DivisionByZero, 
    Inexact, 
    Overflow, 
    Rounded,
    Underflow, 
    InvalidOperation, 
    Subnormal, 
    FloatOperation,
  SpecialValue* {. pure .} = enum
    None,
    QNaN = "NaN",
    SNaN = "sNaN",
    Inf = "Infinity",
  Decimal* = object
    sign, exponent: int
    coefficient: BigInt
    special: SpecialValue
  Context* = object
    precision: int
    rounding: Rounding
    flags, traps: set[Signal]
  ClampedError* = object of Exception
  InvalidOperationError* = object of Exception
  ConversionSyntaxError* = object of Exception
  DivisionByZeroError* = object of Exception
  DivisionImpossibleError* = object of Exception
  DivisionUndefinedError* = object of Exception
  InexactError* = object of Exception
  InvalidContextError* = object of Exception
  RoundedError* = object of Exception
  SubnormalError* = object of Exception
  OverflowError* = object of Exception
  UnderflowError* = object of Exception
  FloatOperationError* = object of Exception

# Initialise commonly used BigInt values.

const 
  bigZero = initBigInt(0)
  bigOne = initBigInt(1)
  bigTwo = initBigInt(2)
  bigFive = initBigInt(5)
  bigTen = initBigInt(10)
  decQNAN = Decimal(sign: 0,
                   coefficient: bigZero,
                   exponent: 0,
                   special: SpecialValue.QNaN,
                   )
  decSNAN = Decimal(sign: 0,
                   coefficient: bigZero,
                   exponent: 0,
                   special: SpecialValue.SNaN,
                   )
  decINF = Decimal(sign: 0,
                   coefficient: bigZero,
                   exponent: 0,
                   special: SpecialValue.Inf,
                   )

# Default context settings.

const
  defaultFlags = {}
  defaultTraps = {Signal.Clamped,
                  Signal.DivisionByZero,
                  Signal.Overflow,
                  Signal.Underflow,
                  Signal.InvalidOperation,
                  Signal.FloatOperation,
                  }
  defaultContext = Context(precision: 28, 
                           rounding: Rounding.HalfEven,
                           flags: defaultFlags, 
                           traps: defaultTraps,
                           )

var context* = defaultContext

proc setContext*(context: var Context,
                 precision: int = 28, 
                 rounding: Rounding = Rounding.HalfEven,
                 flags: set[Signal] = defaultFlags,
                 traps: set[Signal] = defaultTraps,
                 ) =
  context.precision = precision
  context.rounding = rounding
  context.flags = flags
  context.traps = traps

proc setPrecision*(context: var Context, precision: int) =
  context.precision = precision

proc setRounding*(context: var Context, rounding: Rounding) =
  context.rounding = rounding

proc allZeros(numericalString: string, precision: int): bool =
  for character in numericalString[precision..numericalString.high]:
    if character != '0':
      return false
  true

proc allNines(numericalString: string, precision: int): bool =
  for character in numericalString[precision..numericalString.high]:
    if character != '9':
      return false
  true

proc exactHalf(numericalString: string, precision: int): bool =
  if numericalString[precision] != '5':
    return false
  for character in numericalString[precision + 1..numericalString.high]:
    if character != '0':
      return false
  true

proc stripLeadingZeros(digits: string): string =
  ## Returns a copy of the input string with any
  ## leading zeros removed. Only iterates to the second last digit as at least
  ## one digit is required for a valid Decimal coefficient, even if it is zero.
  var zeros = 0
  for number in digits[0..(digits.high - 1)]:
    if number != '0':
      break
    else:
      zeros += 1
  digits[zeros..digits.high]

proc initDecimal(coefficient: BigInt, sign, exponent: int, special: SpecialValue): Decimal =
  ## Returns an instance of a Decimal with all fields of the instance populated 
  ## explicitly. A positive coefficient must be given, never negative.
  result.coefficient = coefficient
  result.sign = sign
  result.exponent = exponent
  result.special = special

proc initDecimal*(coefficient: BigInt): Decimal =
  ## Returns an instance of a Decimal with all fields
  ## of the instance populated explicitly by the user.
  if coefficient < 0:
    result.sign = 1
    result.coefficient =  -coefficient
  else:
    result.sign = 0
    result.coefficient = coefficient
  result.exponent = 0
  result.special = SpecialValue.None

proc adjusted(a: Decimal): int =
  a.exponent + len($a.coefficient) - 1

proc isInfinite*(a: Decimal): int =
  if a.special == SpecialValue.Inf:
    if a.sign == 1:
      -1
    else:
      1
  else:
    0

proc isNan*(a: Decimal): int =
  if a.special == SpecialValue.SNaN or a.special == SpecialValue.QNaN:
    if a.sign == 1:
      -1
    else:
      1
  else:
    0

proc isQnan*(a: Decimal): int =
  if a.special == SpecialValue.QNaN:
    if a.sign == 1:
      -1
    else:
      1
  else:
    0

proc isSnan*(a: Decimal): int =
  if a.special == SpecialValue.SNaN:
    if a.sign == 1:
      -1
    else:
      1
  else:
    0

proc isLogical*(a: Decimal): bool =
  if a.sign != 0 or a.exponent != 0:
    return false
  for character in $a.coefficient:
    if character notin {'0','1'}:
      return false
  result = true

proc toNumber(input: string): Decimal =
  ## Takes a string as an input and attempts to parse
  ## a valid integer or decimal number from it, returning a new Decimal 
  ## instance with the parsed value. 
  ## 
  ## A valid decimal string may not have any whitespaces and may only accept
  ## the following inputs:
  ## 
  ## sign             =  '+' | '-'
  ## digit            =  '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' |
  ##                     '8' | '9'
  ## decimal-part     =  digits '.' [digits] | ['.'] digits | digits ['.']
  var
    start = 0
    dotCount = 0
    index = 0

  result.sign = 0
  result.exponent = 0
  result.special = SpecialValue.None

  if input[0] == '-':
    start = 1
    result.sign = 1
  elif input[0] == '+':
    start = 1

  var digits = ""
  
  for character in input[start..input.high]:
    if character in {'0','1','2','3','4','5','6','7','8','9'}:
      digits.add(character)
      index += 1
    elif character == '.':
      if dotCount > 0:
        raise newException(ConversionSyntaxError, "Too many decimal places.")
      result.exponent = index - len(input[start..input.high]) + 1
      dotCount += 1
    elif character in {'e', 'E'}:
  # `parseInt` handles further input errors
      try:
        var 
          shift = start + index
        if dotCount == 0:
          shift -= 1
        result.exponent += parseInt(input[(shift + 2)..input.high])
        if dotCount != 0:
          result.exponent += len(input[shift..input.high]) - 1
        break
      except ValueError:
        raise newException(ConversionSyntaxError, "Invalid numerical string format.")
    else:
      let sign = result.sign
      if input[start..input.high].toLowerAscii() in ["inf", "infinity"]:
        result = decINF
      elif input[start..<(3 + start)].toLowerAscii() == "nan":
        result = decQNAN
      elif input[start..<(4 + start)].toLowerAscii() == "snan":
        result = decSNAN
      else:
        raise newException(ConversionSyntaxError, "Invalid numerical string format.")
      result.sign = sign
      return result
  # `initBigInt` handles leading zeros, so no need to double up.
  result.coefficient = initBigInt(digits)

proc roundDown(a: string, sign, precision: int): int =
  if allZeros(a, precision):
      result = 0
  else:
      result = -1

proc roundUp(a: string, sign, precision: int): int =
  result = -roundDown(a, sign, precision)

proc roundHalfUp(a: string, sign, precision: int): int =
  if a[precision] in {'5','6','7','8','9'}:
      result = 1
  elif allZeros(a, precision):
      result = 0
  else:
      result = -1

proc roundHalfDown(a: string, sign, precision: int): int =
  if exactHalf(a, precision):
    result = -1
  else:
    result = roundHalfUp(a, sign, precision)

proc roundHalfEven(a: string, sign, precision: int): int =
  if exactHalf(a, precision) and 
       (precision == 0 or 
       a[precision - 1] in {'0','2','4','6','8'}):
    result = -1
  else:
    result = roundHalfUp(a, sign, precision)

proc roundCeiling(a: string, sign, precision: int): int =
  if sign == 1 or allZeros(a, precision):
    result = 0
  else:
    result = 1

proc roundFloor(a: string, sign, precision: int): int =
  if sign == 0 or allZeros(a, precision):
    result = 0
  else:
    result = 1

proc round05Up(a: string, sign, precision: int): int =
  if a[precision - 1] notin {'0','5'} and
    $precision notin ["0","5"]:
      result = roundDown(a, sign, precision)
  else:
      result = -roundDown(a, sign, precision)

const roundingProcs = [roundDown, roundHalfUp, roundHalfEven, roundCeiling,
                       roundFloor, roundHalfDown, roundUp, round05Up]

proc round*(a: var Decimal, roundingType: Rounding, precision: int) =
  # This is the major bottleneck on performance, need to do without
  # converting to and from a string as it is slow
  var 
    coef = $a.coefficient
    coefficientLength = coef.len
  if coefficientLength > precision:
    let rounding = roundingProcs[ord(roundingType)](coef, a.sign, precision)
    a.coefficient = initBigInt(coef[0..<precision])
    a.exponent += coefficientLength - precision
    if rounding > 0:
      a.coefficient = a.coefficient + bigOne
      if coef.allNines(0):
        a.coefficient = a.coefficient div 10

proc reduce(a: var Decimal) =
  var index = ($a.coefficient).high
  while index > context.precision:
    if ($a.coefficient)[index] == '0':
      index -= 1
      a.exponent += 1
    else:
      break
  a.coefficient = initBigInt(($a.coefficient)[0..index])

proc initDecimal*(numericalString: string): Decimal =
  result = toNumber(numericalString)
    
proc initDecimal*(number: SomeNumber): Decimal =
  result = toNumber($number)

proc initDecimal*(number: Decimal): Decimal =
  result = number

proc pyModulus(a, b: int): int =
  ## This is needed because the behaviour of CPython's
  ## `%` operator (modulus) is different to Nim's
  ((a mod b) + b) mod b

proc toString(b: Decimal, eng: bool = false): string =
  var a = b
  a.reduce
  let sign = ["", "-"][a.sign]
  if a.special != SpecialValue.None:
    return sign & $a.special
  let 
    aCoefficientStr = $a.coefficient
    aCoefficientLen = aCoefficientStr.len
    leftdigits = a.exponent + aCoefficientLen
  var
    dotplace: int
    intpart, fracpart, exp: string
  if a.exponent <= 0 and leftdigits > -6:
     dotplace = leftdigits
  elif not eng:
     dotplace = 1
  elif a.coefficient == bigZero:
     dotplace = (leftdigits + 1).pyModulus(3) - 1
  else:
     dotplace = (leftdigits - 1).pyModulus(3) + 1
  if dotplace <= 0:
     intpart = "0"
     fracpart = "." & repeat('0', -dotplace) & aCoefficientStr
  elif dotplace >= aCoefficientLen:
     intpart = aCoefficientStr & repeat('0', dotplace - aCoefficientLen)
     fracpart = ""
  else:
     intpart = aCoefficientStr[0..<dotplace]
     fracpart = "." & aCoefficientStr[dotplace..aCoefficientStr.high]
  if leftdigits == dotplace:
     exp = ""
  else:
     let
       exponentValue = (leftdigits - dotplace)
       exponentSign = if exponentValue > 0: "+" else: ""
     exp = "E" & exponentSign & $exponentValue
  result = sign & intpart & fracpart & exp

proc toScientificString*(a: Decimal): string =
  result = a.toString()

proc toEngineeringString*(a: Decimal): string =
  result = a.toString(eng = true)

proc `$`*(number: Decimal): string =
  result = number.toScientificString

proc `echo`*(number: Decimal) =
  echo(number.toScientificString)

proc normalise(a, b: Decimal, precision: int): tuple[a, b: Decimal] =
  var dec1, dec2: Decimal
  if a.exponent < b.exponent:
    dec1 = b
    dec2 = a
  else:
    dec1 = a
    dec2 = b
  var 
    dec1Length = ($dec1.coefficient).len
    dec2Length = ($dec2.coefficient).len
    exponent = dec1.exponent + min(-1, dec1Length - precision - 2)
  if dec2Length + dec2.exponent - 1 < exponent:
    dec2.coefficient = bigOne
    dec2.exponent = exponent
  dec1.coefficient = initBigInt(dec1.coefficient) * pow(bigTen, 
                       initBigInt(dec1.exponent - dec2.exponent))
  dec1.exponent = dec2.exponent
  if a.exponent < b.exponent:
    result = (dec2, dec1)
  else:
    result = (dec1, dec2)

proc multiply(a, b: Decimal): Decimal =
  result.exponent = a.exponent + b.exponent
  result.sign = a.sign xor b.sign
  result.coefficient = a.coefficient * b.coefficient
  result.round(context.rounding, context.precision)

proc `*`*(a, b: Decimal): Decimal =
  result = a.multiply(b)

proc `*`*(a: Decimal, b: int): Decimal =
  result = a * initDecimal(b)

proc `*`*(a: int, b: Decimal): Decimal =
  result = initDecimal(a) * b

proc `*`*(a: Decimal, b: float): Decimal =
  result = a * initDecimal(b)

proc `*`*(a: float, b: Decimal): Decimal =
  result = initDecimal(a) * b

proc `*`*(a: Decimal, b: BigInt): Decimal =
  result = a * initDecimal(b)

proc `*`*(a: BigInt, b: Decimal): Decimal =
  result = initDecimal(a) * b

proc divide(a, b: Decimal): Decimal =
  var
    quotient, remainder: BigInt
    shift = ($b.coefficient).len - ($a.coefficient).len + context.precision + 1
  if shift >= 0:
    (quotient, remainder) = divmod(initBigInt(a.coefficient) * 
                                   pow(initBigInt(10), 
                                   initBigInt(shift)), 
                                   initBigInt(b.coefficient))
  else:
    (quotient, remainder) = divmod(initBigInt(a.coefficient), 
                            initBigInt(b.coefficient) * 
                            pow(initBigInt(10), initBigInt(-1 * shift)))
  if remainder != bigZero:
    if quotient mod 5 == bigZero:
      quotient += 1
  result.sign = a.sign xor b.sign 
  result.coefficient = quotient
  result.exponent = a.exponent - b.exponent - shift
  result.round(context.rounding, context.precision)

proc `/`*(a, b: Decimal): Decimal =
  result = a.divide(b)

proc `/`*(a: Decimal, b: int): Decimal =
  result = a / initDecimal(b)

proc `/`*(a: int, b: Decimal): Decimal =
  result = initDecimal(a) / b

proc `/`*(a: Decimal, b: float): Decimal =
  result = a/ initDecimal(b)

proc `/`*(a: float, b: Decimal): Decimal =
  result = initDecimal(a) / b

proc `/`*(a: Decimal, b: BigInt): Decimal =
  result = a / initDecimal(b)

proc `/`*(a: BigInt, b: Decimal): Decimal =
  result = initDecimal(a) / b

proc add(a, b: Decimal): Decimal =
  var (aNormalised, bNormalised) = normalise(a, b, context.precision)
  if aNormalised.sign != bNormalised.sign:
    if aNormalised.coefficient == bNormalised.coefficient:
      return initDecimal("0")
    if aNormalised.coefficient < bNormalised.coefficient:
      (aNormalised, bNormalised) = (bNormalised, aNormalised)
    if aNormalised.sign == 1:
      result.sign = 1
      (aNormalised.sign, bNormalised.sign) = (bNormalised.sign, aNormalised.sign)
    else:
      result.sign = 0
  elif aNormalised.sign == 1:
    result.sign = 1
    (aNormalised.sign, bNormalised.sign) = (0, 0)
  else:
    result.sign = 0
  if bNormalised.sign == 0:
    result.coefficient = initBigInt(aNormalised.coefficient) + 
                           initBigInt(bNormalised.coefficient)
  else:
    result.coefficient = initBigInt(aNormalised.coefficient) - 
                           initBigInt(bNormalised.coefficient)
  result.exponent = aNormalised.exponent
  result.round(context.rounding, context.precision)

proc `+`*(a, b: Decimal): Decimal =
  result = a.add(b)

proc `+`*(a: Decimal, b: int): Decimal =
  result = a + initDecimal(b)

proc `+`*(a: int, b: Decimal): Decimal =
  result = initDecimal(a) + b

proc `+`*(a: Decimal, b: float): Decimal =
  result = a + initDecimal(b)

proc `+`*(a: float, b: Decimal): Decimal =
  result = initDecimal(a) + b

proc `+`*(a: Decimal, b: BigInt): Decimal =
  result = a + initDecimal(b)

proc `+`*(a: BigInt, b: Decimal): Decimal =
  result = initDecimal(a) + b

proc subtract(a, b: Decimal): Decimal =
  var b = b
  if b.sign == 0:
    b.sign = 1
  else:
    b.sign = 0
  result = a + b
  result.round(context.rounding, context.precision)

proc `-`*(a, b: Decimal): Decimal =
  result = a.subtract(b)

proc `-`*(a: Decimal, b: int): Decimal =
  result = a - initDecimal(b)

proc `-`*(a: int, b: Decimal): Decimal =
  result = initDecimal(a) - b

proc `-`*(a: Decimal, b: float): Decimal =
  result = a - initDecimal(b)

proc `-`*(a: float, b: Decimal): Decimal =
  result = initDecimal(a) - b

proc `-`*(a: Decimal, b: BigInt): Decimal =
  result = a - initDecimal(b)

proc `-`*(a: BigInt, b: Decimal): Decimal =
  result = initDecimal(a) - b

proc `+=`*(a: var Decimal, b: Decimal) =
  a = a + b

proc `-=`*(a: var Decimal, b: Decimal) =
  a = a - b

proc `*=`*(a: var Decimal, b: Decimal) =
  a = a * b

proc `/=`*(a: var Decimal, b: Decimal) =
  a = a / b

proc `^`*(a: Decimal, b: int): Decimal =
  result = a
  for i in 1..<abs(b):
    result = result * a
  if b < 0:
    result = initDecimal("1") / result
  elif b == 0:
    result = initDecimal("1")

proc pow*(a: Decimal, b: int): Decimal =
  result = a
  for i in 1..<abs(b):
    result = result * a
  if b < 0:
    result = initDecimal("1") / result
  elif b == 0:
    result = initDecimal("1")

proc cmp(a, b: Decimal): int =
  if a.coefficient == bigZero:
      if b.coefficient == bigZero:
        result = 0
      else:
        result = -((-1) ^ b.sign)
  elif b.coefficient == bigZero:
        result = (-1) ^ a.sign
  elif a.sign < b.sign:
    result = 1
  elif a.sign > b.sign:
    result = -1
  elif a.special == SpecialValue.Inf or b.special == SpecialValue.Inf:
    let
      isInfA = a.isInfinite()
      isInfB = b.isInfinite()
    if isInfA == isInfB:
      result = 0
    elif isInfA < isInfB:
      result = -1
    else:
      result = 1
  else:
    let
      aAdjusted = a.adjusted()
      bAdjusted = b.adjusted()
    if aAdjusted == bAdjusted:
      let
        aPadded = a.coefficient * pow(bigTen, initBigInt(a.exponent - b.exponent))
        bPadded = b.coefficient * pow(bigTen, initBigInt(b.exponent - a.exponent))
      if aPadded == bPadded:
        result = 0
      elif aPadded < bPadded:
        result = -((-1) ^ a.sign)
      else:
        result = (-1) ^ a.sign
    elif aAdjusted > bAdjusted:
      result = (-1) ^ a.sign
    else:
      result = -((-1) ^ a.sign)

proc `==`*(a, b: Decimal): bool =
  if a.special in {SpecialValue.SNaN, SpecialValue.QNaN} or 
     b.special in {SpecialValue.SNaN, SpecialValue.QNaN}:
    if a.special == b.special and a.sign == b.sign:
      true
    else:
      false
  elif cmp(a, b) == 0:
    true
  else:
    false

proc `!=`*(a, b: Decimal): bool =
  if a == b:
    false
  else:
    true

proc `>`*(a, b: Decimal): bool =
  if a.special in {SpecialValue.SNaN, SpecialValue.QNaN} or 
     b.special in {SpecialValue.SNaN, SpecialValue.QNaN}:
    raise newException(InvalidOperationError, "NaN comparison not possible.")
  elif cmp(a, b) == 1:
    result = true
  else:
    result = false

proc `>`*(a: Decimal, b: int): bool =
  result = a > initDecimal(b)

proc `>`*(a: Decimal, b: float): bool =
  result = a > initDecimal(b)

proc `>`*(a: Decimal, b: string): bool =
  result = a > initDecimal(b)

proc `>`*(a: Decimal, b: BigInt): bool =
  result = a > initDecimal(b)

proc `>`*(a: int, b: Decimal): bool =
  result = initDecimal(a) > b

proc `>`*(a: float, b: Decimal): bool =
  result = initDecimal(a) > b

proc `>`*(a: string, b: Decimal): bool =
  result = initDecimal(a) > b

proc `>`*(a: BigInt, b: Decimal): bool =
  let aDecimal = initDecimal(a)
  result = aDecimal > b

proc `>=`*(a, b: Decimal): bool =
  if a.special in {SpecialValue.SNaN, SpecialValue.QNaN} or 
     b.special in {SpecialValue.SNaN, SpecialValue.QNaN}:
    raise newException(InvalidOperationError, "NaN comparison not possible.")
  elif cmp(a, b) != -1:
    result = true
  else:
    result = false

proc `>=`*(a: Decimal, b: int): bool =
  result = a >= initDecimal(b)

proc `>=`*(a: Decimal, b: float): bool =
  result = a >= initDecimal(b)

proc `>=`*(a: Decimal, b: string): bool =
  result = a >= initDecimal(b)

proc `>=`*(a: Decimal, b: BigInt): bool =
  result = a >= initDecimal(b)

proc `>=`*(a: int, b: Decimal): bool =
  result = initDecimal(a) >= b

proc `>=`*(a: float, b: Decimal): bool =
  result = initDecimal(a) >= b

proc `>=`*(a: string, b: Decimal): bool =
  result = initDecimal(a) >= b

proc `>=`*(a: BigInt, b: Decimal): bool =
  result = initDecimal(a) >= b

proc `<`*(a, b: Decimal): bool =
  if a.special in {SpecialValue.SNaN, SpecialValue.QNaN} or 
     b.special in {SpecialValue.SNaN, SpecialValue.QNaN}:
    raise newException(InvalidOperationError, "NaN comparison not possible.")
  elif cmp(a, b) == -1:
    result = true
  else:
    result = false

proc `<`*(a: Decimal, b: int): bool =
  result = a < initDecimal(b)

proc `<`*(a: Decimal, b: float): bool =
  result = a < initDecimal(b)

proc `<`*(a: Decimal, b: string): bool =
  result = a < initDecimal(b)

proc `<`*(a: Decimal, b: BigInt): bool =
  result = a < initDecimal(b)

proc `<`*(a: int, b: Decimal): bool =
  result = initDecimal(a) < b

proc `<`*(a: float, b: Decimal): bool =
  result = initDecimal(a) < b

proc `<`*(a: string, b: Decimal): bool =
  result = initDecimal(a) < b

proc `<`*(a: BigInt, b: Decimal): bool =
  result = initDecimal(a) < b

proc `<=`*(a, b: Decimal): bool =
  if a.special in {SpecialValue.SNaN, SpecialValue.QNaN} or 
     b.special in {SpecialValue.SNaN, SpecialValue.QNaN}:
    raise newException(InvalidOperationError, "NaN comparison not possible.")
  elif cmp(a, b) != 1:
    result = true
  else:
    result = false

proc `<=`*(a: Decimal, b: int): bool =
  result = a <= initDecimal(b)

proc `<=`*(a: Decimal, b: float): bool =
  result = a <= initDecimal(b)

proc `<=`*(a: Decimal, b: string): bool =
  result = a <= initDecimal(b)

proc `<=`*(a: Decimal, b: BigInt): bool =
  result = a <= initDecimal(b)

proc `<=`*(a: int, b: Decimal): bool =
  result = initDecimal(a) <= b

proc `<=`*(a: float, b: Decimal): bool =
  result = initDecimal(a) <= b

proc `<=`*(a: string, b: Decimal): bool =
  result = initDecimal(a) <= b

proc `<=`*(a: BigInt, b: Decimal): bool =
  result = initDecimal(a) <= b
 
proc abs*(a: Decimal): Decimal =
  result = a
  result.sign = 0

proc divideInteger*(a, b: Decimal): BigInt =
  (a.coefficient * pow(bigTen, initBigInt(a.exponent))) div 
    (b.coefficient * pow(bigTen, initBigInt(b.exponent)))
    
proc max*(a, b: Decimal): Decimal =
  if a > b: a else: b

proc min*(a, b: Decimal): Decimal =
  if a < b: a else: b

proc minMagnitude*(a, b: Decimal): Decimal =
  if abs(a) > abs(b):
    b
  else:
    a

proc maxMagnitude*(a, b: Decimal): Decimal =
  if abs(a) > abs(b):
    a
  else:
    b
  
when isMainModule:
  import unittest

  test "Proc initDecimal (String Initialisation)":
    check($initDecimal("123") == "123")
    check($initDecimal("-123") == "-123")
    check($initDecimal("1.23E+3") == "1.23E+3")
    check($initDecimal("1.23E+5") == "1.23E+5")
    check($initDecimal("12.3") == "12.3")
    check($initDecimal("0.00123") == "0.00123")
    check($initDecimal("1.23E-8") == "1.23E-8")
    check($initDecimal("-1.23E-10") == "-1.23E-10")
    check($initDecimal("0") == "0")
    check($initDecimal("0.00") == "0.00")
    check($initDecimal("0E+2") == "0E+2")
    check($initDecimal("-0") == "-0")
    check($initDecimal("0.000005") == "0.000005")
    check($initDecimal("0.0000050") == "0.0000050")
    check($initDecimal("5E-7") == "5E-7")
    check($initDecimal("Infinity") == "Infinity")
    check($initDecimal("-Infinity") == "-Infinity")
    check($initDecimal("NaN") == "NaN")
    check($initDecimal("NaN123") == "NaN")
    check($initDecimal("-sNaN") == "-sNaN")
    check($(initDecimal("0")) == "0")
    check($(initDecimal("-0")) == "-0")
    check($(initDecimal("+0")) ==  "0")
    check($(initDecimal("0E0")) ==  "0")
    check($(initDecimal("0E-0")) ==  "0")
    check($(initDecimal("0E+0")) == "0")
    check($(initDecimal("+0E0")) == "0")
    check($(initDecimal("+0E-0")) == "0")
    check($(initDecimal("+0E+0")) == "0")
    check($(initDecimal("-0E0")) == "-0")
    check($(initDecimal("-0E-0")) == "-0")
    check($(initDecimal("-0E+0")) == "-0")
    check($(initDecimal("0.0")) == "0.0")
    check($(initDecimal("-0.0")) == "-0.0")
    check($(initDecimal("+0.0")) == "0.0")
    check($(initDecimal("0.00000000000000000000000000000000000000000000000000000000000000000000000000")) == "0E-74")
    check($(initDecimal("+0.00000000000000000000000000000000000000000000000000000000000000000000000000")) == "0E-74")
    check($(initDecimal("-0.00000000000000000000000000000000000000000000000000000000000000000000000000")) == "-0E-74")
    check($(initDecimal("0.0E100")) == "0E+99")
    check($(initDecimal("-0.0E-100")) == "-0E-101")
    check($(initDecimal("+0.0E+100")) == "0E+99")
    check($(initDecimal("00000000")) == "0")
    check($(initDecimal("00000000E10")) == "0E+10")
    check($(initDecimal("00000000E-10")) == "0E-10")
    check($(initDecimal("-00000000E10")) == "-0E+10")
    check($(initDecimal("+00000000E-10")) == "0E-10")
    check($(initDecimal("+01000000E-10")) == "0.0001000000")
    check($(initDecimal("-01000000E-10")) == "-0.0001000000")
    check($(initDecimal("+01000000E+10")) == "1.000000E+16")
    check($(initDecimal("+01000000E10")) == "1.000000E+16")
    check($(initDecimal("+10000000E-10")) == "0.0010000000")
    check($(initDecimal("+00000001E-10")) == "1E-10")
    check($(initDecimal("-10000000E-10")) == "-0.0010000000")
    check($(initDecimal("-00000001E-10")) == "-1E-10")
    check($(initDecimal("+00000001E10")) == "1E+10")
    check($(initDecimal("-00000001E10")) == "-1E+10")

  test "Proc allZeros":
    check("0000000000".allZeros(0) == true)
    check("0".allZeros(0) == true)
    check("0001000000000000000000000000000000".allZeros(4) == true)
    check("10".allZeros(1) == true)
    check("0000000000O".allZeros(0) == false)
    check("0h".allZeros(0) == false)
    check("00000000010000000000000000000000000".allZeros(0) == false)
    check("001".allZeros(0) == false)

  test "Proc allNines":
    check("99999999999999999".allNines(0) == true)
    check("9".allNines(0) == true)
    check("35235235999999999999999999999999999999999999".allNines(8) == true)
    check("09".allNines(1) == true)
    check("9999989999".allNines(0) == false)
    check("9h".allNines(0) == false)
    check("9999999999959999999999999".allNines(3) == false)
    check("991".allNines(0) == false)

  test "Proc exactHalf":
    check("5000000000".exactHalf(0) == true)
    check("50".exactHalf(0) == true)
    check("0000000523324500000000000".exactHalf(13) == true)
    check("005".exactHalf(2) == true)
    check("00000000004".exactHalf(3) == false)
    check("40".exactHalf(0) == false)
    check("00000032523300000000000000000000".exactHalf(11) == false)
    check("001".exactHalf(2) == false)

  test "Proc stripLeadingZeros":
    check("000000000".stripLeadingZeros() == "0")
    check("50".stripLeadingZeros() == "50")
    check("0000000523324500000000000".stripLeadingZeros() == "523324500000000000")
    check("005".stripLeadingZeros() == "5")
    check("00000000004".stripLeadingZeros() == "4")
    check("40".stripLeadingZeros() == "40")
    check("00000032523300000000000000000000".stripLeadingZeros() == "32523300000000000000000000")
    check("001".stripLeadingZeros() == "1")

  test "Proc initDecimal (BigInt Initialisation)":
    check($initDecimal(initBigInt(12928)) == "12928")
    check($initDecimal(initBigInt(12928) - initBigInt(12928)) == "0")
    check($initDecimal(initBigInt("-12928") - initBigInt("-12928")) == "0")
    check($initDecimal(initBigInt("-12928") + initBigInt("-12928")) == "-25856")
    check($initDecimal(initBigInt("12928") + initBigInt("12928")) == "25856")
    check($initDecimal(initBigInt("787878787878787878787878787878787878787878787878787878787878787878787878787878")) == "787878787878787878787878787878787878787878787878787878787878787878787878787878")

  test "Combined Arithmetic (Positive Numbers, Round Half-Even)":
    check($(initDecimal("0.0000000000000000000001928374272") * initDecimal("92222222222222222") * initDecimal("2")) == "0.0000355677921279999999142944768")
    check($(initDecimal("0.0000000000000000000001928374272") * initDecimal("92222222222222222.00000000") / initDecimal("0.02")) == "0.0008891948031999999978573619200")
    check($(initDecimal("0.10") * initDecimal("1212522222") + initDecimal("36236.02")) == "121288458.22")
    check($(initDecimal("1000020002002000200020002001929824") * initDecimal("5843255") - initDecimal("27843")) == "5.843371876798197678767876798E+39")
    check($(initDecimal("100000000000000000000001928374272") / initDecimal("87257") * initDecimal("23")) == "2.635891676312502148824786953E+28")
    check($(initDecimal("0.00000000000000000000001") / initDecimal("9222228387822222222222") / initDecimal("262346246")) == "4.133227141563679397385840448E-54")
    check($(initDecimal("0.000000000000000000000000000000001") / initDecimal("27882782") - initDecimal("2097545647")) == "-2097545647.000000000000000000")
    check($(initDecimal("0.0000745472") / initDecimal("7889489.4717") + initDecimal("223675")) == "223675.0000000000094489257217")
    check($(initDecimal("0.7667786") + initDecimal("132465") * initDecimal("234677347")) == "31086534770355.7667786")
    check($(initDecimal("232320.0000000000000000000001928374272") + initDecimal("922222237872222222222142") / initDecimal("34574752.784")) == "26673285088737559.68571152980")
    check($(initDecimal("0.8") + initDecimal("92222222837373222222222344") - initDecimal("2252")) == "92222222837373222222220092.8")
    check($(initDecimal("1232332.113422232322") + initDecimal("78454") + initDecimal("2673346.55652")) == "3984132.669942232322")
    check($(initDecimal("0.445") - initDecimal("97635") * initDecimal("488442")) == "-47689034669.555")
    check($(initDecimal("50") - initDecimal("14235.11242") / initDecimal("234784")) == "49.93936932491140793239743764")
    check($(initDecimal("9999999999999999") - initDecimal("784555555688.89456752") - initDecimal("345332")) == "9999215444098978.10543248")
    check($(initDecimal("19283722.127") - initDecimal("7744.22222") + initDecimal("88984562")) == "108260539.90478")
    check(initDecimal("0.1") + initDecimal("0.1") + initDecimal("0.1") + initDecimal("0.1") + 
      initDecimal("0.1") + initDecimal("0.1") + initDecimal("0.1") + initDecimal("0.1") == initDecimal("0.8"))
    check(initDecimal("0.1") * initDecimal("0.1") * initDecimal("0.1") * initDecimal("0.1") * 
      initDecimal("0.1") * initDecimal("0.1") * initDecimal("0.1") * initDecimal("0.1") == initDecimal("1E-8"))

  test "Combined Arithmetic (Negative Numbers, Round Half-Even)":
    check($(initDecimal("-0.0000000000000000000001928374272") * initDecimal("-92222222222222222") * initDecimal("-2")) == "-0.0000355677921279999999142944768")
    check($(initDecimal("-0.0000000000000000000001928374272") * initDecimal("-92222222222222222.00000000") / initDecimal("-0.02")) == "-0.0008891948031999999978573619200")
    check($(initDecimal("-0.10") * initDecimal("-1212522222") + initDecimal("-36236.02")) == "121215986.18")
    check($(initDecimal("-1000020002002000200020002001929824") * initDecimal("-5843255") - initDecimal("-27843")) == "5.843371876798197678767876798E+39")
    check($(initDecimal("-100000000000000000000001928374272") / initDecimal("-87257") * initDecimal("-23")) == "-2.635891676312502148824786953E+28")
    check($(initDecimal("-0.00000000000000000000001") / initDecimal("-9222228387822222222222") / initDecimal("-262346246")) == "-4.133227141563679397385840448E-54")
    check($(initDecimal("-0.000000000000000000000000000000001") / initDecimal("-27882782") - initDecimal("-2097545647")) == "2097545647.000000000000000000")
    check($(initDecimal("-0.0000745472") / initDecimal("-7889489.4717") + initDecimal("-223675")) == "-223674.9999999999905510742783")
    check($(initDecimal("-0.7667786") + initDecimal("-132465") * initDecimal("-234677347")) == "31086534770354.2332214")
    check($(initDecimal("-232320.0000000000000000000001928374272") + initDecimal("-922222237872222222222142") / initDecimal("-34574752.784")) == "26673285088272919.68571152980")
    check($(initDecimal("-0.8") + initDecimal("-92222222837373222222222344") - initDecimal("-2252")) == "-92222222837373222222220092.8")
    check($(initDecimal("-1232332.113422232322") + initDecimal("-78454") + initDecimal("-2673346.55652")) == "-3984132.669942232322")
    check($(initDecimal("-0.445") - initDecimal("-97635") * initDecimal("-488442")) == "-47689034670.445" )
    check($(initDecimal("-50") - initDecimal("-14235.11242") / initDecimal("-234784")) == "-50.06063067508859206760256236")
    check($(initDecimal("-9999999999999999") - initDecimal("-784555555688.89456752") - initDecimal("-345332")) == "-9999215444098978.10543248")
    check($(initDecimal("-19283722.127") - initDecimal("-7744.22222") + initDecimal("-88984562")) == "-108260539.90478" )
    check(initDecimal("-0.1") + initDecimal("-0.1") + initDecimal("-0.1") + initDecimal("-0.1") + 
      initDecimal("-0.1") + initDecimal("-0.1") + initDecimal("-0.1") + initDecimal("-0.1") == initDecimal("-0.8"))
    check(initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("-0.1") * 
      initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("-0.1") == initDecimal("1E-8"))

  test "Combined Arithmetic (Mixed-Sign Numbers, Round Half-Even)":
    check($(initDecimal("-0.0000000000000000000001928374272") * initDecimal("92222222222222222") * initDecimal("2")) == "-0.0000355677921279999999142944768")
    check($(initDecimal("0.0000000000000000000001928374272") * initDecimal("-92222222222222222.00000000") / initDecimal("0.02")) == "-0.0008891948031999999978573619200")
    check($(initDecimal("0.10") * initDecimal("1212522222") + initDecimal("-36236.02")) == "121215986.18" )
    check($(initDecimal("1000020002002000200020002001929824") * initDecimal("-5843255") - initDecimal("27843")) == "-5.843371876798197678767876798E+39")
    check($(initDecimal("-100000000000000000000001928374272") / initDecimal("87257") * initDecimal("23")) == "-2.635891676312502148824786953E+28")
    check($(initDecimal("0.00000000000000000000001") / initDecimal("-9222228387822222222222") / initDecimal("262346246")) == "-4.133227141563679397385840448E-54")
    check($(initDecimal("0.000000000000000000000000000000001") / initDecimal("27882782") - initDecimal("-2097545647")) == "2097545647.000000000000000000")
    check($(initDecimal("0.0000745472") / initDecimal("-7889489.4717") + initDecimal("-223675")) == "-223675.0000000000094489257217")
    check($(initDecimal("-0.7667786") + initDecimal("-132465") * initDecimal("234677347")) == "-31086534770355.7667786")
    check($(initDecimal("-232320.0000000000000000000001928374272") + initDecimal("-922222237872222222222142") / initDecimal("34574752.784")) == "-26673285088737559.68571152980")
    check($(initDecimal("0.8") + initDecimal("92222222837373222222222344") - initDecimal("2252")) == "92222222837373222222220092.8")
    check($(initDecimal("1232332.113422232322") + initDecimal("-78454") + initDecimal("-2673346.55652")) == "-1519468.443097767678")
    check($(initDecimal("0.445") - initDecimal("-97635") * initDecimal("488442")) == "47689034670.445")
    check($(initDecimal("50") - initDecimal("-14235.11242") / initDecimal("234784")) == "50.06063067508859206760256236")
    check($(initDecimal("9999999999999999") - initDecimal("-784555555688.89456752") - initDecimal("345332")) == "10000784555210355.89456752")
    check($(initDecimal("19283722.127") - initDecimal("-7744.22222") + initDecimal("-88984562")) == "-69693095.65078")
    check(initDecimal("-0.1") + initDecimal("+0.1") + initDecimal("-0.1") + initDecimal("+0.1") + 
      initDecimal("-0.1") + initDecimal("+0.1") + initDecimal("-0.1") + initDecimal("-0.1") == initDecimal("-0.2"))
    check(initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("+0.1") * initDecimal("-0.1") * 
      initDecimal("-0.1") * initDecimal("+0.1") * initDecimal("-0.1") * initDecimal("-0.1") == initDecimal("1E-8"))

  test "Operator `==`":
    check(initDecimal("99999999999") == initDecimal("99999999999"))
    check(initDecimal(99999999999) == initDecimal("99999999999"))
    check(initDecimal(initBigInt("99999999999")) == initDecimal("99999999999"))
    check(initDecimal("99999.999999") == initDecimal("99999.999999"))
    check(initDecimal("0.000000000000000001213131310001313") == initDecimal("0.000000000000000001213131310001313"))
    check(initDecimal("9999999999928923998289239.29") == initDecimal("9999999999928923998289239.29"))
    check(initDecimal(initBigInt("0")) == initDecimal("-0"))

  test "Operator `!=`":
    check(initDecimal("99999999999") != initDecimal("99899999999"))
    check(initDecimal(999999) != initDecimal("99999999999"))
    check(initDecimal(initBigInt("1")) != initDecimal("99999999999"))
    check(initDecimal("99999.999999") != initDecimal("999999.99999"))
    check(initDecimal("0.000000000000000001213131310001313") != initDecimal("1.000000000000000001213131310001313"))

  test "Operator `>`":
    check(initDecimal("99999999999") > initDecimal("99899999999"))
    check(initDecimal(9999999) > initDecimal("999999"))
    check(initDecimal(initBigInt("99999999999")) > initDecimal("1"))
    check(initDecimal("999999.99999") > initDecimal("999999.99998"))
    check(initDecimal("1.000000000000000001213131310001313") > initDecimal("0.000000000000000001213131310001313"))

  test "Operator `>=`":
    check(initDecimal("99999999999") >= initDecimal("99899999999"))
    check(initDecimal(9999999) >= initDecimal("999999"))
    check(initDecimal(initBigInt("99999999999")) >= initDecimal("1"))
    check(initDecimal("999999.99999") >= initDecimal("999999.99999"))
    check(initDecimal("0.000000000000000001213131310001313") >= initDecimal("0.000000000000000001213131310001313"))
    check(initDecimal(initBigInt("0")) >= initDecimal("-0"))

  test "Operator `<`":
    check(initDecimal("99999999999") < initDecimal("999999999999"))
    check(initDecimal(9999999) < initDecimal("99933999"))
    check(initDecimal(initBigInt("99999999999")) < initDecimal("11111111121111.0000"))
    check(initDecimal("699999.99999") < initDecimal("899999.99998"))
    check(initDecimal("1.000000000000000001213131310001313") < initDecimal("2.000000000000000001213131310001313"))

  test "Operator `<=`":
    check(initDecimal("99999999999") <= initDecimal("999999999999"))
    check(initDecimal(9999999) <= initDecimal("99933999"))
    check(initDecimal(initBigInt("99999999999")) <= initDecimal("11111111121111.0000"))
    check(initDecimal("899999.99998") <= initDecimal("899999.99998"))
    check(initDecimal("2.000000000000000001213131310001313") <= initDecimal("2.000000000000000001213131310001313"))
    check(initDecimal(initBigInt("-0")) <= initDecimal("0"))

  context.setRounding(Rounding.Down)

  test "Combined Arithmetic (Positive Numbers, Round Down)":
    check($(initDecimal("0.0000000000000000000001928374272") * initDecimal("92222222222222222") * initDecimal("2")) == "0.0000355677921279999999142944768")
    check($(initDecimal("0.0000000000000000000001928374272") * initDecimal("92222222222222222.00000000") / initDecimal("0.02")) == "0.0008891948031999999978573619200")
    check($(initDecimal("0.10") * initDecimal("1212522222") + initDecimal("36236.02")) == "121288458.22")
    check($(initDecimal("1000020002002000200020002001929824") * initDecimal("5843255") - initDecimal("27843")) == "5.843371876798197678767876796E+39")
    check($(initDecimal("100000000000000000000001928374272") / initDecimal("87257") * initDecimal("23")) == "2.635891676312502148824786953E+28")
    check($(initDecimal("0.00000000000000000000001") / initDecimal("9222228387822222222222") / initDecimal("262346246")) == "4.133227141563679397385840443E-54")
    check($(initDecimal("0.000000000000000000000000000000001") / initDecimal("27882782") - initDecimal("2097545647")) == "-2097545646.999999999999999999")
    check($(initDecimal("0.0000745472") / initDecimal("7889489.4717") + initDecimal("223675")) == "223675.0000000000094489257216")
    check($(initDecimal("0.7667786") + initDecimal("132465") * initDecimal("234677347")) == "31086534770355.7667786")
    check($(initDecimal("232320.0000000000000000000001928374272") + initDecimal("922222237872222222222142") / initDecimal("34574752.784")) == "26673285088737559.68571152980")
    check($(initDecimal("0.8") + initDecimal("92222222837373222222222344") - initDecimal("2252")) == "92222222837373222222220092.8")
    check($(initDecimal("1232332.113422232322") + initDecimal("78454") + initDecimal("2673346.55652")) == "3984132.669942232322")
    check($(initDecimal("0.445") - initDecimal("97635") * initDecimal("488442")) == "-47689034669.555")
    check($(initDecimal("50") - initDecimal("14235.11242") / initDecimal("234784")) == "49.93936932491140793239743764")
    check($(initDecimal("9999999999999999") - initDecimal("784555555688.89456752") - initDecimal("345332")) == "9999215444098978.10543248")
    check($(initDecimal("19283722.127") - initDecimal("7744.22222") + initDecimal("88984562")) == "108260539.90478")
    check(initDecimal("0.1") + initDecimal("0.1") + initDecimal("0.1") + initDecimal("0.1") + 
      initDecimal("0.1") + initDecimal("0.1") + initDecimal("0.1") + initDecimal("0.1") == initDecimal("0.8"))
    check(initDecimal("0.1") * initDecimal("0.1") * initDecimal("0.1") * initDecimal("0.1") * 
      initDecimal("0.1") * initDecimal("0.1") * initDecimal("0.1") * initDecimal("0.1") == initDecimal("1E-8"))

  test "Combined Arithmetic (Negative Numbers, Round Down)":
    check($(initDecimal("-0.0000000000000000000001928374272") * initDecimal("-92222222222222222") * initDecimal("-2")) == "-0.0000355677921279999999142944768")
    check($(initDecimal("-0.0000000000000000000001928374272") * initDecimal("-92222222222222222.00000000") / initDecimal("-0.02")) == "-0.0008891948031999999978573619200")
    check($(initDecimal("-0.10") * initDecimal("-1212522222") + initDecimal("-36236.02")) == "121215986.18")
    check($(initDecimal("-1000020002002000200020002001929824") * initDecimal("-5843255") - initDecimal("-27843")) == "5.843371876798197678767876797E+39")
    check($(initDecimal("-100000000000000000000001928374272") / initDecimal("-87257") * initDecimal("-23")) == "-2.635891676312502148824786953E+28")
    check($(initDecimal("-0.00000000000000000000001") / initDecimal("-9222228387822222222222") / initDecimal("-262346246")) == "-4.133227141563679397385840443E-54")
    check($(initDecimal("-0.000000000000000000000000000000001") / initDecimal("-27882782") - initDecimal("-2097545647")) == "2097545647.000000000000000000")
    check($(initDecimal("-0.0000745472") / initDecimal("-7889489.4717") + initDecimal("-223675")) == "-223674.9999999999905510742783")
    check($(initDecimal("-0.7667786") + initDecimal("-132465") * initDecimal("-234677347")) == "31086534770354.2332214")
    check($(initDecimal("-232320.0000000000000000000001928374272") + initDecimal("-922222237872222222222142") / initDecimal("-34574752.784")) == "26673285088272919.68571152979")
    check($(initDecimal("-0.8") + initDecimal("-92222222837373222222222344") - initDecimal("-2252")) == "-92222222837373222222220092.8")
    check($(initDecimal("-1232332.113422232322") + initDecimal("-78454") + initDecimal("-2673346.55652")) == "-3984132.669942232322")
    check($(initDecimal("-0.445") - initDecimal("-97635") * initDecimal("-488442")) == "-47689034670.445" )
    check($(initDecimal("-50") - initDecimal("-14235.11242") / initDecimal("-234784")) == "-50.06063067508859206760256235")
    check($(initDecimal("-9999999999999999") - initDecimal("-784555555688.89456752") - initDecimal("-345332")) == "-9999215444098978.10543248")
    check($(initDecimal("-19283722.127") - initDecimal("-7744.22222") + initDecimal("-88984562")) == "-108260539.90478" )
    check(initDecimal("-0.1") + initDecimal("-0.1") + initDecimal("-0.1") + initDecimal("-0.1") + 
      initDecimal("-0.1") + initDecimal("-0.1") + initDecimal("-0.1") + initDecimal("-0.1") == initDecimal("-0.8"))
    check(initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("-0.1") * 
      initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("-0.1") == initDecimal("1E-8"))

  test "Combined Arithmetic (Mixed-Sign Numbers, Round Down)":
    check($(initDecimal("-0.0000000000000000000001928374272") * initDecimal("92222222222222222") * initDecimal("2")) == "-0.0000355677921279999999142944768")
    check($(initDecimal("0.0000000000000000000001928374272") * initDecimal("-92222222222222222.00000000") / initDecimal("0.02")) == "-0.0008891948031999999978573619200")
    check($(initDecimal("0.10") * initDecimal("1212522222") + initDecimal("-36236.02")) == "121215986.18" )
    check($(initDecimal("1000020002002000200020002001929824") * initDecimal("-5843255") - initDecimal("27843")) == "-5.843371876798197678767876797E+39")
    check($(initDecimal("-100000000000000000000001928374272") / initDecimal("87257") * initDecimal("23")) == "-2.635891676312502148824786953E+28")
    check($(initDecimal("0.00000000000000000000001") / initDecimal("-9222228387822222222222") / initDecimal("262346246")) == "-4.133227141563679397385840443E-54")
    check($(initDecimal("0.000000000000000000000000000000001") / initDecimal("27882782") - initDecimal("-2097545647")) == "2097545647.000000000000000000")
    check($(initDecimal("0.0000745472") / initDecimal("-7889489.4717") + initDecimal("-223675")) == "-223675.0000000000094489257216")
    check($(initDecimal("-0.7667786") + initDecimal("-132465") * initDecimal("234677347")) == "-31086534770355.7667786")
    check($(initDecimal("-232320.0000000000000000000001928374272") + initDecimal("-922222237872222222222142") / initDecimal("34574752.784")) == "-26673285088737559.68571152980")
    check($(initDecimal("0.8") + initDecimal("92222222837373222222222344") - initDecimal("2252")) == "92222222837373222222220092.8")
    check($(initDecimal("1232332.113422232322") + initDecimal("-78454") + initDecimal("-2673346.55652")) == "-1519468.443097767678")
    check($(initDecimal("0.445") - initDecimal("-97635") * initDecimal("488442")) == "47689034670.445")
    check($(initDecimal("50") - initDecimal("-14235.11242") / initDecimal("234784")) == "50.06063067508859206760256235")
    check($(initDecimal("9999999999999999") - initDecimal("-784555555688.89456752") - initDecimal("345332")) == "10000784555210355.89456752")
    check($(initDecimal("19283722.127") - initDecimal("-7744.22222") + initDecimal("-88984562")) == "-69693095.65078")
    check(initDecimal("-0.1") + initDecimal("+0.1") + initDecimal("-0.1") + initDecimal("+0.1") + 
      initDecimal("-0.1") + initDecimal("+0.1") + initDecimal("-0.1") + initDecimal("-0.1") == initDecimal("-0.2"))
    check(initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("+0.1") * initDecimal("-0.1") * 
      initDecimal("-0.1") * initDecimal("+0.1") * initDecimal("-0.1") * initDecimal("-0.1") == initDecimal("1E-8"))
