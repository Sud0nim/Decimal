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
  bigOne = initBigInt(1)
  bigTen = initBigInt(10)
  context = Context(precision: 28, rounding: RoundHalfUp)

proc allZeros(coefficient: string, precision: int): bool =
  for number in coefficient[precision..coefficient.high]:
    if number != '0':
      return false
  result = true

proc exactHalf(coefficient: string, precision: int): bool =
  if coefficient[precision] != '5':
    return false
  for number in coefficient[precision+1..coefficient.high]:
    if number != '0':
      return false
  result = true

proc isDecimalString(numericalString: string): bool =
  var 
    dotCount = 0
    cleanedString = numericalString.replace(",","").replace("_","")
  if cleanedString[0] in {'+', '-'}:
    cleanedString = cleanedString[1..cleanedString.high]
  for character in cleanedString:
    if character notin {'.','1','2','3','4','5','6','7','8','9','0'}:
      return false
    if character == '.':
      dotCount += 1
    if dotCount > 1:
      return false
  result = true

proc isScientificString(numericalString: string): bool = 
  var 
    dotCount = 0
    stringParts = numericalString.toLower().split('e')
  if stringParts.len() != 2:
    return false
  if not stringParts[0].isDecimalString():
    return false
  if stringParts[1][0] in {'+', '-'}:
    stringParts[1] = stringParts[1][1..stringParts[1].high]
  for character in stringParts[1]:
    if character notin {'1','2','3','4','5','6','7','8','9','0'}:
      return false
  result = true

proc roundDown*(a: Decimal, precision: int): int =
  if allZeros(a.coefficient, precision):
      result = 0
  else:
      result = -1

proc roundUp*(a: Decimal, precision: int): int =
  result = -roundDown(a, precision)

proc roundHalfUp*(a: Decimal, precision: int): int =
  if a.coefficient[precision] in {'5','6','7','8','9'}:
      result = 1
  elif allZeros(a.coefficient, precision):
      result = 0
  else:
      result = -1

proc roundHalfDown*(a: Decimal, precision: int): int =
  if exactHalf(a.coefficient, precision):
    result = -1
  else:
    result = roundHalfUp(a, precision)

proc roundHalfEven*(a: Decimal, precision: int): int =
  if exactHalf(a.coefficient, precision) and 
       (precision == 0 or 
       a.coefficient[precision-1] in {'0','2','4','6','8'}):
    result = -1
  else:
    result = roundHalfUp(a, precision)

proc roundCeiling*(a: Decimal, precision: int): int =
  if a.sign == 1 or allZeros(a.coefficient, precision):
    result = 0
  else:
    result = 1

proc roundFloor*(a: Decimal, precision: int): int =
  if a.sign == 0 or allZeros(a.coefficient, precision):
    result = 0
  else:
    result = 1

proc round05Up*(a: Decimal, precision: int): int =
  if a.coefficient[precision-1] notin {'0','5'} and
    $precision notin ["0","5"]:
      result = roundDown(a, precision)
  else:
      result = -roundDown(a, precision)

let roundingProcs = [roundDown, roundHalfUp, roundHalfEven, roundCeiling,
                     roundFloor, roundHalfDown, roundUp, round05Up]

proc round*(a: var Decimal, roundingType: Rounding,
            precision: int) =
  let coefficientLength = len(a.coefficient)
  if coefficientLength <= precision:
    return
  else:
    var
      rounding = roundingProcs[ord(roundingType)](a, precision)
    a.coefficient = a.coefficient[0..<precision]
    if rounding > 0:
      a.coefficient = $(initBigInt(a.coefficient)+1)
    if len(a.coefficient) > precision:
      a.coefficient = a.coefficient[0..<precision]
    a.exponent += coefficientLength - len(a.coefficient)

proc reduce(a: var Decimal) =
  var index = a.coefficient.len() - 1
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

proc parseDecimalString(numericalString: var string): int =
  var numberParts = numericalString.split('.')
  if numberParts.len == 1:
    result = 0
    numericalString = strip(numericalString, trailing=false, chars={'0'})
    if numericalString == "":
      numericalString = "0"
  elif numberParts.len == 2:
    numericalString = numberParts[0] & numberParts[1]
    if numericalString.allZeros(0):
      result = 1 - len(numericalString)
      numericalString = "0"
    else:
      numericalString = strip(numericalString, trailing=false, chars={'0'})
      result = numberParts[1].len * -1
  else:
    raise newException(IOError, "Invalid numerical string format.")

proc parseScientificString(numericalString: var string): int =
  let numberParts = toLower(numericalString).split('e')
  if numberParts.len == 2:
    numericalString = numberParts[0]
    result = parseDecimalString(numericalString)
    result += parseInt(numberParts[1])
  else:
    raise newException(IOError, "Invalid scientific string format.")

proc parseSpecialString(numericalString: var string): int =
  numericalString = numericalString.tolower()
  if numericalString in ["inf", "infinity"]:
    numericalString = "inf"
  elif numericalString == "snan":
    numericalString = "sNaN"
  else:
    numericalString = "qNaN"
  result = 0

proc toNumber*(numericalString: string): Decimal =
  if numericalString.len() == 0:
    raise newException(IOError, "Invalid string format (empty string).")
  result.coefficient = numericalString
  result.sign = parseSign(result.coefficient)
  result.isSpecial = false
  if numericalString.isDecimalString():
    result.exponent = parseDecimalString(result.coefficient)
  elif numericalString.isScientificString():
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
        result = "0." & repeat('0', abs(a.exponent) - a.coefficient.len) & a.coefficient
      elif adjustedExponent >= 0:
        result = a.coefficient[0..adjustedExponent] & "." & a.coefficient[adjustedExponent+1 .. a.coefficient.high]
  else:
    let exponentSign = if adjustedExponent > 0: "+" else: ""
    if a.coefficient.len > 1:
      result = a.coefficient[0] & "." & a.coefficient[1..a.coefficient.high] & "E" & exponentSign & $adjustedExponent
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
        result = "0." & repeat('0', abs(a.exponent) - a.coefficient.len) & a.coefficient
      elif adjustedExponent >= 0:
        result = a.coefficient[0..adjustedExponent] & "." & a.coefficient[adjustedExponent+1 .. a.coefficient.high]
  else:
    var
      modulus = 3 - abs(adjustedExponent mod 3)
      adjustedExponent = if modulus == 3: adjustedExponent else: adjustedExponent - modulus
      decimalPosition: int = 1 + abs(modulus)
    if a.coefficient.len >= decimalPosition:
      var rightPart = a.coefficient[decimalPosition..a.coefficient.high]
      result = a.coefficient[0..<decimalPosition] & "." & rightPart & "E" & $adjustedExponent
    else:
      result = a.coefficient & "E" & $adjustedExponent
  result = ["", "-"][a.sign] & result

proc `$`*(number: Decimal): string =
  result = number.toScientificString

proc `echo`*(number: Decimal) =
  echo number.toScientificString

proc `*`*(a, b: Decimal): Decimal =
  result.exponent = a.exponent + b.exponent
  result.sign = a.sign xor b.sign
  result.coefficient = $(initBigInt(a.coefficient) * initBigInt(b.coefficient))
  result.round(context.rounding, context.precision)
  result.reduce()

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

proc `^`(base, exp: int): int =
  # Only use positive integers
  var 
    b = base
    e = exp
  result = 1
  while e != 0:
    if (e and 1) != 0:
        result *= b
    e = e shr 1
    b *= b

proc `/`*(a, b: Decimal): Decimal =
  var
    precision = 28 # replace with a context object
    quotient, remainder: BigInt
    sign = a.sign xor b.sign 
    shift = len(b.coefficient) - len(a.coefficient) + precision + 1
    exp = a.exponent - b.exponent - shift
  if shift >= 0:
    quotient = (initBigInt(a.coefficient) * pow(initBigInt(10), initBigInt(shift))) div initBigInt(b.coefficient)
    remainder = (initBigInt(a.coefficient) * pow(initBigInt(10), initBigInt(shift))) mod initBigInt(b.coefficient)
  else:
    quotient = initBigInt(a.coefficient) div (initBigInt(b.coefficient) * pow(initBigInt(10), initBigInt(-1 * shift)))
    remainder = initBigInt(a.coefficient) mod (initBigInt(b.coefficient) * pow(initBigInt(10), initBigInt(-1 * shift))) 
  if remainder != bigZero:
    if quotient mod 5 == bigZero:
      quotient = quotient + 1
  result.sign = sign
  result.coefficient = $quotient
  result.exponent = exp
  result.round(context.rounding, context.precision)
  result.reduce()

proc `/`*(a: Decimal, b: int): Decimal =
  result = initDecimal(b)
  result = a / result

proc `/`*(a: int, b: Decimal): Decimal =
  result = initDecimal(a)
  result = result / b

proc `/`*(a: Decimal, b: float): Decimal =
  result = initDecimal($b)
  result = a / result

proc `/`*(a: float, b: Decimal): Decimal =
  result = initDecimal($a)
  result = result / b

proc `/`*(a: Decimal, b: BigInt): Decimal =
  result = initDecimal(b)
  result = a / result

proc `/`*(a: BigInt, b: Decimal): Decimal =
  result = initDecimal(a)
  result = result / b

proc `+`*(a, b: Decimal): Decimal =
  # TODO: Refactor out if/else nested in favour of simplified handling
  if abs(a.exponent) > abs(b.exponent):
    var 
      bCoefficient = initBigInt(b.coefficient) * pow(initBigInt(10), initBigInt(abs(a.exponent - b.exponent)))
      aCoefficient = initBigInt(a.coefficient)
    if a.sign == b.sign:
      result.sign = a.sign
      result.coefficient = $(aCoefficient + bCoefficient)
      result.exponent = a.exponent
    else:
      if aCoefficient > bCoefficient:
        result.sign = a.sign
        result.coefficient = $(aCoefficient - bCoefficient)
        result.exponent = a.exponent
      elif aCoefficient < bCoefficient:
        result.sign = b.sign
        result.coefficient = $(bCoefficient - aCoefficient)
        result.exponent = a.exponent
      else:
        result.sign = 0
        result.coefficient = $bigZero
        result.exponent = 0
  elif abs(a.exponent) < abs(b.exponent):
    var 
      aCoefficient = initBigInt(a.coefficient) * pow(initBigInt(10), initBigInt(abs(b.exponent - a.exponent)))
      bCoefficient = initBigInt(b.coefficient)
    if b.sign == a.sign:
      result.sign = b.sign
      result.coefficient = $(bCoefficient + aCoefficient)
      result.exponent = b.exponent
    else:
      if bCoefficient > aCoefficient:
        result.sign = b.sign
        result.coefficient = $(bCoefficient - aCoefficient)
        result.exponent = b.exponent
      elif bCoefficient < aCoefficient:
        result.sign = a.sign
        result.coefficient = $(aCoefficient - bCoefficient)
        result.exponent = b.exponent
      else:
        result.sign = 0
        result.coefficient = $bigZero
        result.exponent = 0
  else:
    result.exponent = a.exponent
    var
      bCoefficient = initBigInt(b.coefficient)
      aCoefficient = initBigInt(a.coefficient)
    if a.sign == b.sign:
      result.sign = a.sign
      result.coefficient = $(aCoefficient + bCoefficient)
    else:
      if a.coefficient > b.coefficient:
        result.sign = a.sign
        result.coefficient = $(aCoefficient - bCoefficient)
      elif a.coefficient < b.coefficient:
        result.sign = b.sign
        result.coefficient = $(bCoefficient - aCoefficient)
      else:
        result.sign = 0
        result.coefficient = $bigZero
  result.round(context.rounding, context.precision)
  result.reduce()

proc `+`*(a: Decimal, b: int): Decimal =
  result = initDecimal(b)
  result = a + result

proc `+`*(a: int, b: Decimal): Decimal =
  result = initDecimal(a)
  result = result + b

proc `+`*(a: Decimal, b: float): Decimal =
  result = initDecimal($b)
  result = a + result

proc `+`*(a: float, b: Decimal): Decimal =
  result = initDecimal($a)
  result = result + b

proc `+`*(a: Decimal, b: BigInt): Decimal =
  result = initDecimal(b)
  result = a + result

proc `+`*(a: BigInt, b: Decimal): Decimal =
  result = initDecimal(a)
  result = result + b

proc `-`*(a,b: Decimal): Decimal =
  result = b
  if result.sign == 1:
    result.sign = 0
  else:
    result.sign = 1
  result = a + result
  result.round(context.rounding, context.precision)
  result.reduce()

proc `-`*(a: Decimal, b: int): Decimal =
  result = initDecimal(b)
  result = a - result

proc `-`*(a: int, b: Decimal): Decimal =
  result = initDecimal(a)
  result = result - b

proc `-`*(a: Decimal, b: float): Decimal =
  result = initDecimal($b)
  result = a - result

proc `-`*(a: float, b: Decimal): Decimal =
  result = initDecimal($a)
  result = result - b

proc `-`*(a: Decimal, b: BigInt): Decimal =
  result = initDecimal(b)
  result = a - result

proc `-`*(a: BigInt, b: Decimal): Decimal =
  result = initDecimal(a)
  result = result - b

proc `^`*(a: Decimal, b: int): Decimal =
  result = a
  for i in 1..<abs(b):
    result = result * a
  if b < 0:
    result = initDecimal(1) / result
  elif b == 0:
    result = initDecimal(1)

proc pow*(a: Decimal, b: int): Decimal =
  result = a
  for i in 1..<abs(b):
    result = result * a
  if b < 0:
    result = initDecimal(1) / result
  elif b == 0:
    result = initDecimal(1)

proc `==`*(a, b: Decimal): bool =
  result = 
    if a.sign != b.sign:
      false
    elif a.coefficient == "0" and b.coefficient == "0":
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
  let bDecimal = initDecimal(b)
  result = a > bDecimal

proc `>`*(a: Decimal, b: float): bool =
  let bDecimal = initDecimal($b)
  result = a > bDecimal

proc `>`*(a: Decimal, b: string): bool =
  # try, raise exception if not valid number
  let bDecimal = initDecimal(b)
  result = a > bDecimal

proc `>`*(a: Decimal, b: BigInt): bool =
  let bDecimal = initDecimal(b)
  result = a > bDecimal

proc `>`*(a: int, b: Decimal): bool =
  let aDecimal = initDecimal(a)
  result = aDecimal > b

proc `>`*(a: float, b: Decimal): bool =
  let aDecimal = initDecimal($a)
  result = aDecimal > b

proc `>`*(a: string, b: Decimal): bool =
  # try, raise exception if not valid number
  let aDecimal = initDecimal(a)
  result = aDecimal > b

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
  let bDecimal = initDecimal(b)
  result = a >= bDecimal

proc `>=`*(a: Decimal, b: float): bool =
  let bDecimal = initDecimal($b)
  result = a >= bDecimal

proc `>=`*(a: Decimal, b: string): bool =
  # try, raise exception if not valid number
  let bDecimal = initDecimal(b)
  result = a >= bDecimal

proc `>=`*(a: Decimal, b: BigInt): bool =
  let bDecimal = initDecimal(b)
  result = a >= bDecimal

proc `>=`*(a: int, b: Decimal): bool =
  let aDecimal = initDecimal(a)
  result = aDecimal >= b

proc `>=`*(a: float, b: Decimal): bool =
  let aDecimal = initDecimal($a)
  result = aDecimal >= b

proc `>=`*(a: string, b: Decimal): bool =
  # try, raise exception if not valid number
  let aDecimal = initDecimal(a)
  result = aDecimal >= b

proc `>=`*(a: BigInt, b: Decimal): bool =
  let aDecimal = initDecimal(a)
  result = aDecimal >= b

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
  let bDecimal = initDecimal(b)
  result = a < bDecimal

proc `<`*(a: Decimal, b: float): bool =
  let bDecimal = initDecimal($b)
  result = a < bDecimal

proc `<`*(a: Decimal, b: string): bool =
  # try, raise exception if not valid number
  let bDecimal = initDecimal(b)
  result = a < bDecimal

proc `<`*(a: Decimal, b: BigInt): bool =
  let bDecimal = initDecimal(b)
  result = a < bDecimal

proc `<`*(a: int, b: Decimal): bool =
  let aDecimal = initDecimal(a)
  result = aDecimal < b

proc `<`*(a: float, b: Decimal): bool =
  let aDecimal = initDecimal($a)
  result = aDecimal < b

proc `<`*(a: string, b: Decimal): bool =
  # try, raise exception if not valid number
  let aDecimal = initDecimal(a)
  result = aDecimal < b

proc `<`*(a: BigInt, b: Decimal): bool =
  let aDecimal = initDecimal(a)
  result = aDecimal < b

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
  let bDecimal = initDecimal(b)
  result = a <= bDecimal

proc `<=`*(a: Decimal, b: float): bool =
  let bDecimal = initDecimal($b)
  result = a <= bDecimal

proc `<=`*(a: Decimal, b: string): bool =
  # try, raise exception if not valid number
  let bDecimal = initDecimal(b)
  result = a <= bDecimal

proc `<=`*(a: Decimal, b: BigInt): bool =
  let bDecimal = initDecimal(b)
  result = a <= bDecimal

proc `<=`*(a: int, b: Decimal): bool =
  let aDecimal = initDecimal(a)
  result = aDecimal <= b

proc `<=`*(a: float, b: Decimal): bool =
  let aDecimal = initDecimal($a)
  result = aDecimal <= b

proc `<=`*(a: string, b: Decimal): bool =
  # try, raise exception if not valid number
  let aDecimal = initDecimal(a)
  result = aDecimal <= b

proc `<=`*(a: BigInt, b: Decimal): bool =
  let aDecimal = initDecimal(a)
  result = aDecimal <= b
  
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

# Logical Operations

proc isLogical*(a: Decimal): bool =
  if a.sign != 0 or a.exponent != 0:
    return false
  for number in $a.coefficient:
    if number notin {'0', '1'}:
      return false
  true
