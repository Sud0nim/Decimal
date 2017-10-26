import strutils, math, bigints

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
    coefficient*: BigInt
  Context* = object
    precision*: int
    rounding*: Rounding
    flags*, traps*: seq[Signal]

const 
  bigZero = initBigInt(0)
  bigTen = initBigInt(10)
  defaultContext = Context(precision: 9, rounding: RoundHalfUp)

proc newDecimal*(number: string): Decimal =
  var 
    inputString = number
  if inputString.startsWith("-"):
    result.sign = 1
    inputString = inputString[1..inputString.high]
  else:
    result.sign = 0
  let
    components = inputString.split('.', maxsplit = 1)
  if components.len == 1:
    result.coefficient = initBigInt(components[0])
    result.exponent = 0
  else:
    result.coefficient =  initBigInt(components[0] & components[1])
    result.exponent = components[1].len * -1 
    
proc newDecimal*(number: float): Decimal =
  result = newDecimal($number)

proc newDecimal*(number: int): Decimal =
  if number < 0:
    result.sign = 1
    result.coefficient = initBigInt(number * -1)
  else:
    result.sign = 0
    result.coefficient = initBigInt(number)
  result.exponent = 0

proc newDecimal*(number: BigInt): Decimal =
  if number < 0:
    result.sign = 1
  else:
    result.sign = 0
  result.coefficient = number
  result.exponent = 0

proc `toDecimalString`*(number: Decimal): string =
  var
    value = $number.coefficient
    precision = 28
    sign = ["", "-"][number.sign]
    decimalPosition = value.len + number.exponent
    trailingZeros = precision
  if number.exponent < 0:
    trailingZeros = trailingZeros + number.exponent
  #if number.sign == 1:
  #  sign = "-"
  if decimalPosition < 0:
    result = value[decimalPosition..value.high]
    for i in 0..<abs(decimalPosition):
      result = "0" & result
    result = "0" & "." & result
  else:
    result = value[0..<decimalPosition]
    for i in 0..<(decimalPosition - value.len):
      result = result & "0"
    result = result & "." #& value[decimalPosition..value.high]
  result = sign & result
  if trailingZeros > 0:
    for i in 0..<trailingZeros:
      result = result & "0"

proc toScientificString*(number: Decimal): string = 
  var
    precision = 28
    value = $number.coefficient
    leftside = value[0]
    rightside, exp: string
    expSign = "+"
    leftdigits = number.exponent + value.len
  if precision > value.len:
    rightside = value[1..value.high]
  else:
    rightside = value[1..<(precision)]
  var 
    sign = ""
  if number.sign == 1:
    sign = "-"
  if leftdigits == 1:
    exp = ""
  if number.exponent < 0:
    expSign = "-"
  else:
    exp = "E" & expSign & $(leftdigits-1)
  result = sign & leftside & "." & rightside & exp

proc `$`*(number: Decimal): string =
  var
    value = $number.coefficient
    numberLength = value.len + abs(value.len + number.exponent)
    precision = 28
  if number.exponent == 0 and value.len < precision:
    result = number.toDecimalString
  else:
    result = number.toScientificString

proc `echo`*(number: Decimal) =
  echo $number

proc `*`*(a, b: Decimal): Decimal =
  result.exponent = a.exponent + b.exponent
  result.sign = a.sign xor b.sign
  result.coefficient = a.coefficient * b.coefficient

proc `*`*(a: Decimal, b: int): Decimal =
  result = newDecimal(b)
  result.exponent = a.exponent + result.exponent
  result.sign = a.sign xor result.sign
  result.coefficient = a.coefficient * result.coefficient

proc `*`*(a: int, b: Decimal): Decimal =
  result = newDecimal(a)
  result.exponent = b.exponent + result.exponent
  result.sign = b.sign xor result.sign
  result.coefficient = b.coefficient * result.coefficient

proc `*`*(a: Decimal, b: float): Decimal =
  result = newDecimal($b)
  result.exponent = a.exponent + result.exponent
  result.sign = a.sign xor result.sign
  result.coefficient = a.coefficient * result.coefficient

proc `*`*(a: float, b: Decimal): Decimal =
  result = newDecimal($a)
  result.exponent = b.exponent + result.exponent
  result.sign = b.sign xor result.sign
  result.coefficient = b.coefficient * result.coefficient

proc `*`*(a: Decimal, b: BigInt): Decimal =
  result = newDecimal(b)
  result.exponent = a.exponent + result.exponent
  result.sign = a.sign xor result.sign
  result.coefficient = a.coefficient * result.coefficient

proc `*`*(a: BigInt, b: Decimal): Decimal =
  result = newDecimal(a)
  result.exponent = b.exponent + result.exponent
  result.sign = b.sign xor result.sign
  result.coefficient = b.coefficient * result.coefficient

proc `/`*(a, b: Decimal): Decimal =
  var
    precision = 15 # replace with a context object
    quotient, remainder: BigInt
    sign = a.sign ^ b.sign 
    shift = len($b.coefficient) - len($a.coefficient) + precision + 1
    exp = a.exponent - b.exponent - shift
  if shift >= 0:
    quotient = (a.coefficient * pow(initBigInt(10), initBigInt(shift))) div b.coefficient
    remainder = (a.coefficient * pow(initBigInt(10), initBigInt(shift))) mod b.coefficient
  else:
    quotient = a.coefficient div (b.coefficient * pow(initBigInt(10), initBigInt(-1 * shift)))
    remainder = a.coefficient mod (b.coefficient * pow(initBigInt(10), initBigInt(-1 * shift))) 
  if remainder != bigZero:
    if quotient mod 5 == bigZero:
      quotient = quotient + 1
  result.sign = sign
  result.coefficient = quotient
  result.exponent = exp

proc `/`*(a: Decimal, b: int): Decimal =
  result = newDecimal(b)
  result = a / result

proc `/`*(a: int, b: Decimal): Decimal =
  result = newDecimal(a)
  result = result / b

proc `/`*(a: Decimal, b: float): Decimal =
  result = newDecimal($b)
  result = a / result

proc `/`*(a: float, b: Decimal): Decimal =
  result = newDecimal($a)
  result = result / b

proc `/`*(a: Decimal, b: BigInt): Decimal =
  result = newDecimal(b)
  result = a / result

proc `/`*(a: BigInt, b: Decimal): Decimal =
  result = newDecimal(a)
  result = result / b

proc `+`*(a, b: Decimal): Decimal =
  # TODO: Refactor out if/else nested in favour of simplified handling
  if abs(a.exponent) > abs(b.exponent):
    var normalisedBCoefficient = b.coefficient * pow(initBigInt(10), initBigInt(abs(a.exponent - b.exponent)))
    if a.sign == b.sign:
      result.sign = a.sign
      result.coefficient = a.coefficient + normalisedBCoefficient
      result.exponent = a.exponent
    else:
      if a.coefficient > normalisedBCoefficient:
        result.sign = a.sign
        result.coefficient = a.coefficient - normalisedBCoefficient
        result.exponent = a.exponent
      elif a.coefficient < normalisedBCoefficient:
        result.sign = b.sign
        result.coefficient = normalisedBCoefficient - a.coefficient
        result.exponent = a.exponent
      else:
        result.sign = 0
        result.coefficient = initBigInt(0)
        result.exponent = 0
  elif abs(a.exponent) < abs(b.exponent):
    var normalisedACoefficient = a.coefficient * pow(initBigInt(10), initBigInt(abs(b.exponent - a.exponent)))
    if b.sign == a.sign:
      result.sign = b.sign
      result.coefficient = b.coefficient + normalisedACoefficient
      result.exponent = b.exponent
    else:
      if b.coefficient > normalisedACoefficient:
        result.sign = b.sign
        result.coefficient = b.coefficient - normalisedACoefficient
        result.exponent = b.exponent
      elif b.coefficient < normalisedACoefficient:
        result.sign = a.sign
        result.coefficient = normalisedACoefficient - b.coefficient
        result.exponent = b.exponent
      else:
        result.sign = 0
        result.coefficient = initBigInt(0)
        result.exponent = 0
  else:
    result.exponent = a.exponent
    if a.sign == b.sign:
      result.sign = a.sign
      result.coefficient = a.coefficient + b.coefficient
    else:
      if a.coefficient > b.coefficient:
        result.sign = a.sign
        result.coefficient = a.coefficient - b.coefficient
      elif a.coefficient < b.coefficient:
        result.sign = b.sign
        result.coefficient = b.coefficient - a.coefficient
      else:
        result.sign = 0
        result.coefficient = initBigInt(0)

proc `+`*(a: Decimal, b: int): Decimal =
  result = newDecimal(b)
  result = a + result

proc `+`*(a: int, b: Decimal): Decimal =
  result = newDecimal(a)
  result = result + b

proc `+`*(a: Decimal, b: float): Decimal =
  result = newDecimal($b)
  result = a + result

proc `+`*(a: float, b: Decimal): Decimal =
  result = newDecimal($a)
  result = result + b

proc `+`*(a: Decimal, b: BigInt): Decimal =
  result = newDecimal(b)
  result = a + result

proc `+`*(a: BigInt, b: Decimal): Decimal =
  result = newDecimal(a)
  result = result + b

proc `-`*(a,b: Decimal): Decimal =
  result = b
  if result.sign == 1:
    result.sign = 0
  else:
    result.sign = 1
  result = a + result

proc `-`*(a: Decimal, b: int): Decimal =
  result = newDecimal(b)
  result = a - result

proc `-`*(a: int, b: Decimal): Decimal =
  result = newDecimal(a)
  result = result - b

proc `-`*(a: Decimal, b: float): Decimal =
  result = newDecimal($b)
  result = a - result

proc `-`*(a: float, b: Decimal): Decimal =
  result = newDecimal($a)
  result = result - b

proc `-`*(a: Decimal, b: BigInt): Decimal =
  result = newDecimal(b)
  result = a - result

proc `-`*(a: BigInt, b: Decimal): Decimal =
  result = newDecimal(a)
  result = result - b

proc `^`*(a: Decimal, b: int): Decimal =
  result = a
  for i in 1..<abs(b):
    result = result * a
  if b < 0:
    result = newDecimal(1) / result
  elif b == 0:
    result = newDecimal(1)

proc pow*(a: Decimal, b: int): Decimal =
  result = a
  for i in 1..<abs(b):
    result = result * a
  if b < 0:
    result = newDecimal(1) / result
  elif b == 0:
    result = newDecimal(1)

proc `==`*(a, b: Decimal): bool =
  result = 
    if a.coefficient == bigZero and b.coefficient == bigZero:
      true
    elif a.sign != b.sign:
      false
    elif a.coefficient * pow(bigTen, initBigInt(a.exponent)) == 
         b.coefficient * pow(bigTen, initBigInt(b.exponent)):
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
    elif a.coefficient * pow(bigTen, initBigInt(a.exponent)) > 
         b.coefficient * pow(bigTen, initBigInt(b.exponent)):
      if a.sign == 1:
        false
      else:
        true
    elif a.coefficient * pow(bigTen, initBigInt(a.exponent)) < 
         b.coefficient * pow(bigTen, initBigInt(b.exponent)):
      if a.sign == 1:
        true
      else:
        false
    else:
      false

proc `>`*(a: Decimal, b: int): bool =
  let bDecimal = newDecimal(b)
  result = a > bDecimal

proc `>`*(a: Decimal, b: float): bool =
  let bDecimal = newDecimal($b)
  result = a > bDecimal

proc `>`*(a: Decimal, b: string): bool =
  # try, raise exception if not valid number
  let bDecimal = newDecimal(b)
  result = a > bDecimal

proc `>`*(a: Decimal, b: BigInt): bool =
  let bDecimal = newDecimal(b)
  result = a > bDecimal

proc `>`*(a: int, b: Decimal): bool =
  let aDecimal = newDecimal(a)
  result = aDecimal > b

proc `>`*(a: float, b: Decimal): bool =
  let aDecimal = newDecimal($a)
  result = aDecimal > b

proc `>`*(a: string, b: Decimal): bool =
  # try, raise exception if not valid number
  let aDecimal = newDecimal(a)
  result = aDecimal > b

proc `>`*(a: BigInt, b: Decimal): bool =
  let aDecimal = newDecimal(a)
  result = aDecimal > b

proc `>=`*(a, b: Decimal): bool =
  result = 
    if a.coefficient == bigZero and b.coefficient == bigZero:
      true
    elif a.sign > b.sign:
      false
    elif a.coefficient * pow(bigTen, initBigInt(a.exponent)) > 
         b.coefficient * pow(bigTen, initBigInt(b.exponent)):
      if a.sign == 1:
        false
      else:
        true
    elif a.coefficient * pow(bigTen, initBigInt(a.exponent)) < 
         b.coefficient * pow(bigTen, initBigInt(b.exponent)):
      if a.sign == 1:
        true
      else:
        false
    else:
      true

proc `>=`*(a: Decimal, b: int): bool =
  let bDecimal = newDecimal(b)
  result = a >= bDecimal

proc `>=`*(a: Decimal, b: float): bool =
  let bDecimal = newDecimal($b)
  result = a >= bDecimal

proc `>=`*(a: Decimal, b: string): bool =
  # try, raise exception if not valid number
  let bDecimal = newDecimal(b)
  result = a >= bDecimal

proc `>=`*(a: Decimal, b: BigInt): bool =
  let bDecimal = newDecimal(b)
  result = a >= bDecimal

proc `>=`*(a: int, b: Decimal): bool =
  let aDecimal = newDecimal(a)
  result = aDecimal >= b

proc `>=`*(a: float, b: Decimal): bool =
  let aDecimal = newDecimal($a)
  result = aDecimal >= b

proc `>=`*(a: string, b: Decimal): bool =
  # try, raise exception if not valid number
  let aDecimal = newDecimal(a)
  result = aDecimal >= b

proc `>=`*(a: BigInt, b: Decimal): bool =
  let aDecimal = newDecimal(a)
  result = aDecimal >= b

proc `<`*(a, b: Decimal): bool =
  result = 
    if a.coefficient == bigZero and b.coefficient == bigZero:
      false
    elif b.sign > a.sign:
      false
    elif b.coefficient * pow(bigTen, initBigInt(b.exponent)) > 
         a.coefficient * pow(bigTen, initBigInt(a.exponent)):
      if a.sign == 1:
        false
      else:
        true
    elif b.coefficient * pow(bigTen, initBigInt(b.exponent)) < 
         a.coefficient * pow(bigTen, initBigInt(a.exponent)):
      if a.sign == 1:
        true
      else:
        false
    else:
      false

proc `<`*(a: Decimal, b: int): bool =
  let bDecimal = newDecimal(b)
  result = a < bDecimal

proc `<`*(a: Decimal, b: float): bool =
  let bDecimal = newDecimal($b)
  result = a < bDecimal

proc `<`*(a: Decimal, b: string): bool =
  # try, raise exception if not valid number
  let bDecimal = newDecimal(b)
  result = a < bDecimal

proc `<`*(a: Decimal, b: BigInt): bool =
  let bDecimal = newDecimal(b)
  result = a < bDecimal

proc `<`*(a: int, b: Decimal): bool =
  let aDecimal = newDecimal(a)
  result = aDecimal < b

proc `<`*(a: float, b: Decimal): bool =
  let aDecimal = newDecimal($a)
  result = aDecimal < b

proc `<`*(a: string, b: Decimal): bool =
  # try, raise exception if not valid number
  let aDecimal = newDecimal(a)
  result = aDecimal < b

proc `<`*(a: BigInt, b: Decimal): bool =
  let aDecimal = newDecimal(a)
  result = aDecimal < b

proc `<=`*(a, b: Decimal): bool =
  if a.sign < b.sign:
    return false
  if abs(a.exponent) > abs(b.exponent):
    var normalisedBCoefficient = b.coefficient * pow(initBigInt(10), initBigInt(abs(a.exponent - b.exponent)))
    result = a.coefficient <= normalisedBCoefficient
  elif abs(a.exponent) < abs(b.exponent):
    var normalisedACoefficient = a.coefficient * pow(initBigInt(10), initBigInt(abs(b.exponent - a.exponent)))
    result = normalisedACoefficient <= b.coefficient
  else:
    result = a.coefficient <= b.coefficient

proc `<=`*(a: Decimal, b: int): bool =
  let bDecimal = newDecimal(b)
  result = a <= bDecimal

proc `<=`*(a: Decimal, b: float): bool =
  let bDecimal = newDecimal($b)
  result = a <= bDecimal

proc `<=`*(a: Decimal, b: string): bool =
  # try, raise exception if not valid number
  let bDecimal = newDecimal(b)
  result = a <= bDecimal

proc `<=`*(a: Decimal, b: BigInt): bool =
  let bDecimal = newDecimal(b)
  result = a <= bDecimal

proc `<=`*(a: int, b: Decimal): bool =
  let aDecimal = newDecimal(a)
  result = aDecimal <= b

proc `<=`*(a: float, b: Decimal): bool =
  let aDecimal = newDecimal($a)
  result = aDecimal <= b

proc `<=`*(a: string, b: Decimal): bool =
  # try, raise exception if not valid number
  let aDecimal = newDecimal(a)
  result = aDecimal <= b

proc `<=`*(a: BigInt, b: Decimal): bool =
  let aDecimal = newDecimal(a)
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
      
# Tests to ensure nothing breaks:

#[ 
Note - initialising with floats may summon a dragon. String initialisation is the best option
if you are wishing to use high decimal precision, 
as floats inherently are not able to correctly represent all decimal numbers precisely.
Because of this in the tests I should take out the float vs string init assertions, 
but I am leaving them in for now to see how often it causes a failure in precision.
]#

assert(newDecimal("9999999999999") == Decimal(sign: 0, coefficient: initBigInt(9999999999999), exponent: 0))
assert(newDecimal("-9999999") == Decimal(sign: 1, coefficient: initBigInt(9999999), exponent: 0))
assert(newDecimal("9999999999999.99") == Decimal(sign: 0, coefficient: initBigInt(999999999999999), exponent: -2))
assert(newDecimal("-9999999.113") == Decimal(sign: 1, coefficient: initBigInt(9999999113), exponent: -3))
assert(newDecimal("9999999999999") != Decimal(sign: 0, coefficient: initBigInt(9999998999999), exponent: 0))
# Int == BigInt
assert(newDecimal(123456) == Decimal(sign: 0, coefficient: initBigInt(123456), exponent: 0))
assert(newDecimal(-9999999) == Decimal(sign: 1, coefficient: initBigInt(9999999), exponent: 0))
assert(newDecimal(984323112) == Decimal(sign: 0, coefficient: initBigInt(984323112), exponent: 0))
assert(newDecimal(-99999900) == Decimal(sign: 1, coefficient: initBigInt(99999900), exponent: 0))
assert(newDecimal(987654323) != Decimal(sign: 0, coefficient: initBigInt(99998999999), exponent: 0))
# String == Float
assert(newDecimal("0.123844") == newDecimal(0.123844))
assert(newDecimal("-9999999") == newDecimal(-9999999))
assert(newDecimal("9999999999999.99") == newDecimal(9999999999999.99))
assert(newDecimal("-9999999.113") == newDecimal(-9999999.113))
assert(newDecimal("9999999999999") != newDecimal(99999999999.99))
# String compare
assert($newDecimal("0.123844") == $newDecimal(0.123844))
assert($newDecimal("-9999999") == $newDecimal(-9999999))
assert($newDecimal("9999999999999.99") == $newDecimal(9999999999999.99))
assert($newDecimal("-9999999.113") == $newDecimal(-9999999.113))
assert($newDecimal("9999999999999") != $newDecimal(99999999999.99))
assert($newDecimal(123456) == $Decimal(sign: 0, coefficient: initBigInt(123456), exponent: 0))
assert($newDecimal(-9999999) == $Decimal(sign: 1, coefficient: initBigInt(9999999), exponent: 0))
assert($newDecimal(984323112) == $Decimal(sign: 0, coefficient: initBigInt(984323112), exponent: 0))
assert($newDecimal(-99999900) == $Decimal(sign: 1, coefficient: initBigInt(99999900), exponent: 0))
assert($newDecimal(987654323) != $Decimal(sign: 0, coefficient: initBigInt(99998999999), exponent: 0))
assert($newDecimal(123456) == $Decimal(sign: 0, coefficient: initBigInt(123456), exponent: 0))
assert($newDecimal(-9999999) == $Decimal(sign: 1, coefficient: initBigInt(9999999), exponent: 0))
assert($newDecimal(984323112) == $Decimal(sign: 0, coefficient: initBigInt(984323112), exponent: 0))
assert($newDecimal(-99999900) == $Decimal(sign: 1, coefficient: initBigInt(99999900), exponent: 0))
assert($newDecimal(987654323) != $Decimal(sign: 0, coefficient: initBigInt(99998999999), exponent: 0))
# With precision of minimum 15, no maximum
assert($newDecimal(123.456) == "123.456000000000000")
assert($newDecimal(-123.456) == "-123.456000000000000")
assert($newDecimal(123456) == "123456.000000000000000")
assert($newDecimal(-123456) == "-123456.000000000000000")
assert($newDecimal("0.0000129282736181827121212") == "0.0000129282736181827121212")
assert($newDecimal("-0.09283212") == "-0.092832120000000")
assert($newDecimal(initBigInt(123456)) == "123456.000000000000000")
assert($newDecimal("0") == "0.000000000000000")

# Init procedures are working - test arithmetic

# Using current precision settings - update these when a context class is added.

assert(newDecimal("987654323") * newDecimal("98760006323") == newDecimal("97540747184418284329"))
assert(newDecimal("5765673") * newDecimal("98760006323") == newDecimal("569417901936350379"))
assert(newDecimal("12345.9876") * newDecimal("9000.001") == newDecimal("111113900.7459876"))
assert(newDecimal("98765432378237878238322343.923273754293259235892935235") * newDecimal("98760006323.1212121214125") == newDecimal("9754074726180573349995607815094526520.4241699729543015912608823485558192194375"))
assert(newDecimal("987654323.0001") * newDecimal("0.000100000220000100022420") == newDecimal("98765.6495840598475975099316622420"))

# Test repeat arithmetic with each type to ensure no rounding issue.

assert(newDecimal("0.1") + newDecimal("0.1") + newDecimal("0.1") + newDecimal("0.1") + 
  newDecimal("0.1") + newDecimal("0.1") + newDecimal("0.1") + newDecimal("0.1") == newDecimal("0.8"))
assert(newDecimal("0.1") * newDecimal("0.1") * newDecimal("0.1") * newDecimal("0.1") * 
  newDecimal("0.1") * newDecimal("0.1") * newDecimal("0.1") * newDecimal("0.1") == newDecimal("0.00000001"))
