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
    None = "",
    QNaN = "NaN",
    SNaN = "sNaN",
    Inf = "Infinity",
  Decimal* = object
    sign*, exponent*: int
    coefficient*: BigInt
    special*: SpecialValue
  Context* = object
    precision*: int
    rounding*: Rounding
    flags*, traps*: set[Signal]
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


proc allZeros(numericalString: string, precision: int): bool =
  for character in numericalString[precision..numericalString.high]:
    if character != '0':
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
  ## Internal Procedure: returns a copy of the input string with any
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

proc initDecimal(coefficient: BigInt): Decimal =
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
      result.exponent = index - len(input[start..input.high]) + 1#digits.len + 1
      dotCount += 1
    elif character in {'e', 'E'}:
  # `parseInt` should handle further input errors, so try and raise conversion syntax on fail.
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
        result.sign = sign
        return result
      elif input[start..(3 + start)].toLowerAscii() == "nan":
        result = decQNAN
        result.sign = sign
        return result
      elif input[start..(4 + start)].toLowerAscii() == "snan":
        result = decSNAN
        result.sign = sign
        return result
      else:
        raise newException(ConversionSyntaxError, "conversionsyntax etc...")
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

proc round(a: var Decimal, roundingType: Rounding, precision: int) =
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
      if coef[precision-1] == '9':
        a.coefficient = a.coefficient div 10

proc getRoundedValue(a: Decimal, roundingType: Rounding, precision: int): Decimal =
  # move rounding to end
  result = a
  var 
    coef = $result.coefficient
    coefficientLength = coef.len
  if coefficientLength > precision:
    let rounding = roundingProcs[ord(roundingType)](coef, result.sign, precision)
    result.coefficient = initBigInt(coef[0..<precision])
    result.exponent += coefficientLength - precision
    if rounding > 0:
      result.coefficient = result.coefficient + bigOne
      if coef[precision-1] == '9':
        result.coefficient = result.coefficient div 10

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

proc toString(b: Decimal, eng: bool=false): string =
  var a = b
  a.reduce
  let sign = ["", "-"][a.sign]
  if a.special != SpecialValue.None:
    return $a.sign & $a.special
  let leftdigits = a.exponent + len($a.coefficient)
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
     fracpart = "." & repeat('0', -dotplace) & $a.coefficient
  elif dotplace >= len($a.coefficient):
     intpart = $a.coefficient & repeat('0', dotplace - len($a.coefficient))
     fracpart = ""
  else:
     intpart = ($a.coefficient)[0..<dotplace]
     fracpart = "." & ($a.coefficient)[dotplace..($a.coefficient).high]
  if leftdigits == dotplace:
     exp = ""
  else:
     let
       exponentValue = (leftdigits-dotplace)
       exponentSign = if exponentValue > 0: "+" else: ""
     exp = "E" & exponentSign & $exponentValue
  result = sign & intpart & fracpart & exp

proc toScientificString(a: Decimal): string =
  result = a.toString()

proc toEngineeringString(a: Decimal): string =
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

proc `*`*(a, b: Decimal): Decimal =
  result.exponent = a.exponent + b.exponent
  result.sign = a.sign xor b.sign
  result.coefficient = a.coefficient * b.coefficient
  result.round(context.rounding, context.precision)

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

proc `/`*(a, b: Decimal): Decimal =
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

proc `+`*(a, b: Decimal): Decimal =
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

proc `-`*(a, b: Decimal): Decimal =
  var b = b
  if b.sign == 0:
    b.sign = 1
  else:
    b.sign = 0
  result = a + b
  result.round(context.rounding, context.precision)

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

proc `==`*(a, b: Decimal): bool =
  result = 
    if a.sign != b.sign:
      false
    elif a.coefficient == bigZero and b.coefficient == bigZero:
      true
    elif a.special == b.special:
      if (a.exponent == b.exponent) and (a.sign == b.sign):
        true
      else:
        false
    elif initBigInt(a.coefficient) * pow(bigTen, initBigInt(a.exponent)) == 
         initBigInt(b.coefficient) * pow(bigTen, initBigInt(b.exponent)):
      true
    else:
      false

proc `!=`*(a, b: Decimal): bool =
  if a == b:
    result = false
  else:
    result = true

proc `>`*(a, b: Decimal): bool =
  result = 
    if a.coefficient == bigZero and b.coefficient == bigZero:
      false
    elif a.sign > b.sign:
      false
    elif initBigInt(a.coefficient) * pow(bigTen, initBigInt(a.exponent)) > 
         initBigInt(b.coefficient) * pow(bigTen, initBigInt(b.exponent)):
      if a.sign == 1:
        false
      else:
        true
    elif initBigInt(a.coefficient) * pow(bigTen, initBigInt(a.exponent)) < 
         initBigInt(b.coefficient) * pow(bigTen, initBigInt(b.exponent)):
      if a.sign == 1:
        true
      else:
        false
    else:
      false

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
  result = 
    if a.coefficient == bigZero and b.coefficient == bigZero:
      true
    elif a.sign > b.sign:
      false
    elif initBigInt(a.coefficient) * pow(bigTen, initBigInt(a.exponent)) > 
         initBigInt(b.coefficient) * pow(bigTen, initBigInt(b.exponent)):
      if a.sign == 1:
        false
      else:
        true
    elif initBigInt(a.coefficient) * pow(bigTen, initBigInt(a.exponent)) < 
         initBigInt(b.coefficient) * pow(bigTen, initBigInt(b.exponent)):
      if a.sign == 1:
        true
      else:
        false
    else:
      true

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
  result = 
    if a.coefficient == bigZero and b.coefficient == bigZero:
      false
    elif a.sign < b.sign:
      false
    elif initBigInt(b.coefficient) * pow(bigTen, initBigInt(b.exponent)) > 
         initBigInt(a.coefficient) * pow(bigTen, initBigInt(a.exponent)):
      if b.sign == 1:
        false
      else:
        true
    elif initBigInt(b.coefficient) * pow(bigTen, initBigInt(b.exponent)) < 
         initBigInt(a.coefficient) * pow(bigTen, initBigInt(a.exponent)):
      if b.sign == 1:
        true
      else:
        false
    else:
      false

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
  let 
    aCoefficient = initBigInt(a.coefficient)
    bCoefficient = initBigInt(b.coefficient)
  result = 
    if a.sign < b.sign:
      false
    elif abs(a.exponent) > abs(b.exponent):
      aCoefficient <= bCoefficient * 
                      pow(bigTen, initBigInt(abs(a.exponent - b.exponent)))
    elif abs(a.exponent) < abs(b.exponent):
      bCoefficient >= aCoefficient * 
                      pow(bigTen, initBigInt(abs(b.exponent - a.exponent)))
    else:
      aCoefficient <= bCoefficient

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

proc abs(a: BigInt): BigInt =
  result = a
  result.flags = {}

proc compare*(a, b: Decimal): int =
  result = 
    if a < b: 
      -1
    elif a > b:
      1
    else:
      0

proc divideInteger*(a, b: Decimal): BigInt =
  result = (initBigInt(a.coefficient) * pow(bigTen, initBigInt(a.exponent))) div 
    (initBigInt(b.coefficient) * pow(bigTen, initBigInt(b.exponent)))
    
proc max*(a, b: Decimal): Decimal =
  result = if a > b: a else: b

proc min*(a, b: Decimal): Decimal =
  result = if a < b: a else: b

proc minMagnitude*(a, b: Decimal): Decimal =
  result =
    if initBigInt(a.coefficient) * pow(bigTen, initBigInt(a.exponent)) > 
       initBigInt(b.coefficient) * pow(bigTen, initBigInt(b.exponent)):
      b
    else:
      a

proc maxMagnitude*(a, b: Decimal): Decimal =
  result =
    if initBigInt(a.coefficient) * pow(bigTen, initBigInt(a.exponent)) > 
       initBigInt(b.coefficient) * pow(bigTen, initBigInt(b.exponent)):
      a
    else:
      b

proc isLogical*(a: Decimal): bool =
  if a.sign != 0 or a.exponent != 0:
    return false
  for character in $a.coefficient:
    if character notin {'0','1'}:
      return false
  result = true
