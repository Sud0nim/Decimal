import strutils except toLower
import math, bigints
from unicode import toLower

type
  Rounding* = enum
    RoundDown, RoundHalfUp, RoundHalfEven,
    RoundCeiling, RoundFloor, RoundHalfDown,
    RoundUp, Round05Up
  Signal* = enum
    Clamped, DivisionByZero, Inexact, Overflow, Rounded,
    Underflow, InvalidOperation, Subnormal, FloatOperation
  Decimal* = object
    sign*, exponent*: int
    coefficient*: string
    isSpecial*: bool
  Context* = object
    precision*: int
    rounding*: Rounding
    flags*, traps*: seq[Signal]
const 
  bigZero = initBigInt(0)
  bigTen = initBigInt(10)
  defaultContext = Context(precision: 28, rounding: RoundHalfEven)

proc setContext*(context: var Context,
                 precision: int = 28, 
                 rounding: Rounding = RoundHalfEven) =
  context.precision = precision
  context.rounding = rounding

var context = defaultContext

proc allZeros(numericalString: string, precision: int): bool =
  for character in numericalString[precision..numericalString.high]:
    if character != '0':
      return false
  result = true

proc exactHalf(numericalString: string, precision: int): bool =
  if numericalString[precision] != '5':
    return false
  for character in numericalString[precision + 1..numericalString.high]:
    if character != '0':
      return false
  result = true

proc isDecimalString(numericalString: string): bool =
  if numericalString.len == 0:
    return false
  var 
    dotCount = 0
    cleanedString = numericalString
  if cleanedString[0] in {'+','-'}:
    cleanedString = cleanedString[1..cleanedString.high]
  if cleanedString.len == 0:
    return false
  for character in cleanedString:
    if character notin {'.','1','2','3','4','5','6','7','8','9','0'}:
      return false
    if character == '.':
      if dotCount != 0:
        return false
      dotCount += 1
  result = true

proc isScientificString(numericalString: string): bool = 
  var stringParts = numericalString.toLower.split('e')
  if stringParts.len != 2:
    return false
  if not stringParts[0].isDecimalString:
    return false
  if stringParts[1][0] in {'+','-'}:
    stringParts[1] = stringParts[1][1..stringParts[1].high]
  for character in stringParts[1]:
    if character notin {'1','2','3','4','5','6','7','8','9','0'}:
      return false
  result = true

proc roundDown(a: Decimal, precision: int): int =
  if allZeros(a.coefficient, precision):
      result = 0
  else:
      result = -1

proc roundUp(a: Decimal, precision: int): int =
  result = -roundDown(a, precision)

proc roundHalfUp(a: Decimal, precision: int): int =
  if a.coefficient[precision] in {'5','6','7','8','9'}:
      result = 1
  elif allZeros(a.coefficient, precision):
      result = 0
  else:
      result = -1

proc roundHalfDown(a: Decimal, precision: int): int =
  if exactHalf(a.coefficient, precision):
    result = -1
  else:
    result = roundHalfUp(a, precision)

proc roundHalfEven(a: Decimal, precision: int): int =
  if exactHalf(a.coefficient, precision) and 
       (precision == 0 or 
       a.coefficient[precision - 1] in {'0','2','4','6','8'}):
    result = -1
  else:
    result = roundHalfUp(a, precision)

proc roundCeiling(a: Decimal, precision: int): int =
  if a.sign == 1 or allZeros(a.coefficient, precision):
    result = 0
  else:
    result = 1

proc roundFloor(a: Decimal, precision: int): int =
  if a.sign == 0 or allZeros(a.coefficient, precision):
    result = 0
  else:
    result = 1

proc round05Up(a: Decimal, precision: int): int =
  if a.coefficient[precision - 1] notin {'0','5'} and
    $precision notin ["0","5"]:
      result = roundDown(a, precision)
  else:
      result = -roundDown(a, precision)

const roundingProcs = [roundDown, roundHalfUp, roundHalfEven, roundCeiling,
                       roundFloor, roundHalfDown, roundUp, round05Up]

proc round(a: var Decimal, roundingType: Rounding, precision: int) =
  let coefficientLength = a.coefficient.len
  if not (coefficientLength <= precision):
    let rounding = roundingProcs[ord(roundingType)](a, precision)
    a.coefficient = a.coefficient[0..<precision]
    if rounding > 0:
      a.coefficient = $(initBigInt(a.coefficient) + 1)
    if a.coefficient.len > precision:
      a.coefficient = a.coefficient[0..<precision]
    a.exponent += coefficientLength - precision

proc reduce(a: var Decimal) =
  var index = a.coefficient.high
  while index > context.precision:
    if a.coefficient[index] == '0':
      index -= 1
      a.exponent += 1
    else:
      break
  a.coefficient = a.coefficient[0..index]

proc parseSign(numericalString: var string): int =
  if numericalString[0] == '-':
    numericalString = numericalString[1..numericalString.high]
    result = 1
  else:
    if numericalString[0] == '+':
      numericalString = numericalString[1..numericalString.high]
    result = 0

proc stripLeadingZeros(numericalString: var string): int =
  result = 0
  while result < numericalString.high:
    if numericalString[result] == '0':
      result += 1
    else:
      break
  numericalString = numericalString[result..numericalString.high]

proc parseDecimalString(numericalString: var string): int =
  let numberParts = numericalString.split('.')
  if numberParts.len == 1:
    result = 0
    discard numericalString.stripLeadingZeros
  elif numberParts.len == 2:
    numericalString = numberParts[0] & numberParts[1]
    result = 1 - numericalString.stripLeadingZeros - len(numericalString)
    if numericalString != "0":
      result = numberParts[1].len * -1
  else:
    raise newException(IOError, "Invalid decimal string format.")

proc parseScientificString(numericalString: var string): int =
  let numberParts = numericalString.toLower.split('e')
  if numberParts.len == 2:
    numericalString = numberParts[0]
    result = parseDecimalString(numericalString)
    result += parseInt(numberParts[1])
  else:
    raise newException(IOError, "Invalid scientific string format.")

proc parseSpecialString(numericalString: var string): int =
  numericalString = numericalString.tolower
  if numericalString in ["inf", "infinity"]:
    numericalString = "infinity"
  elif numericalString == "snan":
    numericalString = "sNaN"
  else:
    numericalString = "qNaN"
  result = 0

proc toNumber(numericalString: string): Decimal =
  result.coefficient = numericalString
  result.sign = parseSign(result.coefficient)
  result.isSpecial = false
  if numericalString.isDecimalString:
    result.exponent = parseDecimalString(result.coefficient)
  elif numericalString.isScientificString:
    result.exponent = parseScientificString(result.coefficient)
  else:
    result.exponent = parseSpecialString(result.coefficient)
    result.isSpecial = true
  
proc initDecimal*(numericalString: string): Decimal =
  result = toNumber(numericalString)
    
proc initDecimal*(number: SomeNumber): Decimal =
  result = toNumber($number)

proc initDecimal*(number: BigInt): Decimal =
  result = toNumber($number)

proc initDecimal*(number: Decimal): Decimal =
  result = number

proc toScientificString*(a: Decimal): string =
  var
    adjustedExponent = a.exponent + (a.coefficient.len - 1)
  if a.exponent <= 0 and adjustedExponent >= -6:
    if a.exponent == 0:
      result = a.coefficient
    else:
      if adjustedExponent < 0:
        result = "0." & repeat('0', abs(a.exponent) - a.coefficient.len) & 
                 a.coefficient
      elif adjustedExponent >= 0:
        result = a.coefficient[0..adjustedExponent] & "." & 
                 a.coefficient[adjustedExponent + 1..a.coefficient.high]
  else:
    let exponentSign = if adjustedExponent > 0: "+" else: ""
    if a.coefficient.len > 1:
      result = a.coefficient[0] & "." & a.coefficient[1..a.coefficient.high] & 
               "E" & exponentSign & $adjustedExponent
    else:
      result = a.coefficient & "E" & exponentSign & $adjustedExponent
  result = ["", "-"][a.sign] & result

proc toEngineeringString*(a: Decimal): string =
  var
    adjustedExponent = a.exponent + (a.coefficient.len - 1)
  if a.exponent <= 0 and adjustedExponent >= -6:
    if a.exponent == 0:
      result = a.coefficient
    else:
      if adjustedExponent < 0:
        result = "0." & repeat('0', abs(a.exponent) - a.coefficient.len) &
                 a.coefficient
      elif adjustedExponent >= 0:
        result = a.coefficient[0..adjustedExponent] & "." & 
                 a.coefficient[adjustedExponent + 1..a.coefficient.high]
  else:
    var
      modulus = 3 - abs(adjustedExponent mod 3)
      adjustedExponent = if modulus == 3: adjustedExponent 
                         else: adjustedExponent - modulus
      decimalPosition = 1 + abs(modulus)
    if a.coefficient.len >= decimalPosition:
      var rightPart = a.coefficient[decimalPosition..a.coefficient.high]
      result = a.coefficient[0..<decimalPosition] & "." & rightPart & 
               "E" & $adjustedExponent
    else:
      result = a.coefficient & "E" & $adjustedExponent
  result = ["", "-"][a.sign] & result

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
    dec1Length = dec1.coefficient.len
    dec2Length = dec2.coefficient.len
    exponent = dec1.exponent + min(-1, dec1Length - precision - 2)
  if dec2Length + dec2.exponent - 1 < exponent:
    dec2.coefficient = "1"
    dec2.exponent = exponent
  dec1.coefficient = $(initBigInt(dec1.coefficient) * pow(bigTen, 
                       initBigInt(dec1.exponent - dec2.exponent)))
  dec1.exponent = dec2.exponent
  if a.exponent < b.exponent:
    result = (dec2, dec1)
  else:
    result = (dec1, dec2)

proc `*`*(a, b: Decimal): Decimal =
  result.exponent = a.exponent + b.exponent
  result.sign = a.sign xor b.sign
  result.coefficient = $(initBigInt(a.coefficient)*initBigInt(b.coefficient))
  result.round(context.rounding, context.precision)
  result.reduce

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
    shift = b.coefficient.len - a.coefficient.len + context.precision + 1
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
  result.coefficient = $quotient
  result.exponent = a.exponent - b.exponent - shift
  result.round(context.rounding, context.precision)
  result.reduce

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
    if initBigInt(aNormalised.coefficient) == initBigInt(bNormalised.coefficient):
      return initDecimal("0")
    if initBigInt(aNormalised.coefficient) < initBigInt(bNormalised.coefficient):
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
    result.coefficient = $(initBigInt(aNormalised.coefficient) + 
                           initBigInt(bNormalised.coefficient))
  else:
    result.coefficient = $(initBigInt(aNormalised.coefficient) - 
                           initBigInt(bNormalised.coefficient))
  result.exponent = aNormalised.exponent
  result.round(context.rounding, context.precision)
  result.reduce

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
  result = b
  if result.sign == 1:
    result.sign = 0
  else:
    result.sign = 1
  result = a + result
  result.round(context.rounding, context.precision)
  result.reduce

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
    elif a.coefficient == "0" and b.coefficient == "0":
      true
    elif a.coefficient == "infinity" and b.coefficient == "infinity":
      true
    elif a.coefficient == "qNaN" and b.coefficient == "qNaN":
      true
    elif a.coefficient == "sNaN" and b.coefficient == "sNaN":
      true
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
    if a.coefficient == "0" and b.coefficient == "0":
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
    if a.coefficient == "0" and b.coefficient == "0":
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
    if a.coefficient == "0" and b.coefficient == "0":
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
  for character in a.coefficient:
    if character notin {'0','1'}:
      return false
  result = true
  
