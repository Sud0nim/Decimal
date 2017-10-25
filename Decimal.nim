import strutils, math, bigints

type
  Decimal* = object
    sign*: int
    value*: BigInt
    exponent*: int

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
    result.value = initBigInt(components[0])
    result.exponent = 0
  else:
    result.value =  initBigInt(components[0] & components[1])
    result.exponent = components[1].len * -1 
    
proc newDecimal*(number: float): Decimal =
  result = newDecimal($number)

proc newDecimal*(number: int): Decimal =
  if number < 0:
    result.sign = 1
    result.value = initBigInt(number * -1)
  else:
    result.sign = 0
    result.value = initBigInt(number)
  result.exponent = 0

proc newDecimal*(number: BigInt): Decimal =
  if number < 0:
    result.sign = 1
  else:
    result.sign = 0
  result.value = number
  result.exponent = 0

proc `toDecimalString`*(number: Decimal): string =
  var
    value = $number.value
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
    value = $number.value
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
    value = $number.value
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
  result.value = a.value * b.value

proc `*`*(a: Decimal, b: int): Decimal =
  result = newDecimal(b)
  result.exponent = a.exponent + result.exponent
  result.sign = a.sign xor result.sign
  result.value = a.value * result.value

proc `*`*(a: int, b: Decimal): Decimal =
  result = newDecimal(a)
  result.exponent = b.exponent + result.exponent
  result.sign = b.sign xor result.sign
  result.value = b.value * result.value

proc `*`*(a: Decimal, b: float): Decimal =
  result = newDecimal($b)
  result.exponent = a.exponent + result.exponent
  result.sign = a.sign xor result.sign
  result.value = a.value * result.value

proc `*`*(a: float, b: Decimal): Decimal =
  result = newDecimal($a)
  result.exponent = b.exponent + result.exponent
  result.sign = b.sign xor result.sign
  result.value = b.value * result.value

proc `*`*(a: Decimal, b: BigInt): Decimal =
  result = newDecimal(b)
  result.exponent = a.exponent + result.exponent
  result.sign = a.sign xor result.sign
  result.value = a.value * result.value

proc `*`*(a: BigInt, b: Decimal): Decimal =
  result = newDecimal(a)
  result.exponent = b.exponent + result.exponent
  result.sign = b.sign xor result.sign
  result.value = b.value * result.value

proc `/`*(a, b: Decimal): Decimal =
  var
    zero = initBigInt(0)
    precision = 15 # replace with a context object
    quotient, remainder: BigInt
    sign = a.sign * b.sign 
    shift = len($b.value) - len($a.value) + precision + 1
    exp = a.exponent - b.exponent - shift
  if shift >= 0:
    quotient = (a.value * pow(initBigInt(10), initBigInt(shift))) div b.value
    remainder = (a.value * pow(initBigInt(10), initBigInt(shift))) mod b.value
  else:
    quotient = a.value div (b.value * pow(initBigInt(10), initBigInt(-1 * shift)))
    remainder = a.value mod (b.value * pow(initBigInt(10), initBigInt(-1 * shift))) 
  if remainder != zero:
    if quotient mod 5 == zero:
      quotient = quotient + 1
  result.sign = sign
  result.value = quotient
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
    var normalisedBValue = b.value * pow(initBigInt(10), initBigInt(abs(a.exponent - b.exponent)))
    if a.sign == b.sign:
      result.sign = a.sign
      result.value = a.value + normalisedBValue
      result.exponent = a.exponent
    else:
      if a.value > normalisedBValue:
        result.sign = a.sign
        result.value = a.value - normalisedBValue
        result.exponent = a.exponent
      elif a.value < normalisedBValue:
        result.sign = b.sign
        result.value = normalisedBValue - a.value
        result.exponent = a.exponent
      else:
        result.sign = 0
        result.value = initBigInt(0)
        result.exponent = 0
  elif abs(a.exponent) < abs(b.exponent):
    var normalisedAValue = a.value * pow(initBigInt(10), initBigInt(abs(b.exponent - a.exponent)))
    if b.sign == a.sign:
      result.sign = b.sign
      result.value = b.value + normalisedAValue
      result.exponent = b.exponent
    else:
      if b.value > normalisedAValue:
        result.sign = b.sign
        result.value = b.value - normalisedAValue
        result.exponent = b.exponent
      elif b.value < normalisedAValue:
        result.sign = a.sign
        result.value = normalisedAValue - b.value
        result.exponent = b.exponent
      else:
        result.sign = 0
        result.value = initBigInt(0)
        result.exponent = 0
  else:
    result.exponent = a.exponent
    if a.sign == b.sign:
      result.sign = a.sign
      result.value = a.value + b.value
    else:
      if a.value > b.value:
        result.sign = a.sign
        result.value = a.value - b.value
      elif a.value < b.value:
        result.sign = b.sign
        result.value = b.value - a.value
      else:
        result.sign = 0
        result.value = initBigInt(0)

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
  if a.value != b.value:
    return false
  elif a.sign != b.sign:
    return false
  elif a.exponent != b.exponent:
    return false
  return true

proc `!=`*(a, b: Decimal): bool =
  if a == b:
    result = false
  else:
    result = true

proc `>`*(a, b: Decimal): bool =
  if a.sign > b.sign:
    return false
  if abs(a.exponent) > abs(b.exponent):
    let normalisedBValue = b.value * pow(initBigInt(10), initBigInt(abs(a.exponent - b.exponent)))
    result = a.value > normalisedBValue
  elif abs(a.exponent) < abs(b.exponent):
    let normalisedAValue = a.value * pow(initBigInt(10), initBigInt(abs(b.exponent - a.exponent)))
    result = normalisedAValue > b.value
  else:
    result = a.value > b.value

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
  if a.sign > b.sign:
    return false
  if abs(a.exponent) > abs(b.exponent):
    var normalisedBValue = b.value * pow(initBigInt(10), initBigInt(abs(a.exponent - b.exponent)))
    result = a.value >= normalisedBValue
  elif abs(a.exponent) < abs(b.exponent):
    var normalisedAValue = a.value * pow(initBigInt(10), initBigInt(abs(b.exponent - a.exponent)))
    result = normalisedAValue >= b.value
  else:
    result = a.value >= b.value

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
  if a.sign < b.sign:
    return false
  if abs(a.exponent) > abs(b.exponent):
    var normalisedBValue = b.value * pow(initBigInt(10), initBigInt(abs(a.exponent - b.exponent)))
    result = a.value < normalisedBValue
  elif abs(a.exponent) < abs(b.exponent):
    var normalisedAValue = a.value * pow(initBigInt(10), initBigInt(abs(b.exponent - a.exponent)))
    result = normalisedAValue < b.value
  else:
    result = a.value < b.value

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
    var normalisedBValue = b.value * pow(initBigInt(10), initBigInt(abs(a.exponent - b.exponent)))
    result = a.value <= normalisedBValue
  elif abs(a.exponent) < abs(b.exponent):
    var normalisedAValue = a.value * pow(initBigInt(10), initBigInt(abs(b.exponent - a.exponent)))
    result = normalisedAValue <= b.value
  else:
    result = a.value <= b.value

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
  
proc setPrecision(a: var Decimal, precision: int) =
  var multiplier = precision + a.exponent
  if multiplier >= 0:
    a.value = a.value * pow(initBigInt(10), initBigInt(multiplier))
  else:
    a.value = a.value div pow(initBigInt(10), initBigInt(-1 * multiplier))
  a.exponent = a.exponent - multiplier
  
# Tests to ensure nothing breaks:

#[ 
Note - initialising with floats may summon a dragon. String initialisation is the best option
if you are wishing to use high decimal precision, 
as floats inherently are not able to correctly represent all decimal numbers precisely.
Because of this in the tests I should take out the float vs string init assertions, 
but I am leaving them in for now to see how often it causes a failure in precision.
]#

assert(newDecimal("9999999999999") == Decimal(sign: 0, value: initBigInt(9999999999999), exponent: 0))
assert(newDecimal("-9999999") == Decimal(sign: 1, value: initBigInt(9999999), exponent: 0))
assert(newDecimal("9999999999999.99") == Decimal(sign: 0, value: initBigInt(999999999999999), exponent: -2))
assert(newDecimal("-9999999.113") == Decimal(sign: 1, value: initBigInt(9999999113), exponent: -3))
assert(newDecimal("9999999999999") != Decimal(sign: 0, value: initBigInt(9999998999999), exponent: 0))
# Int == BigInt
assert(newDecimal(123456) == Decimal(sign: 0, value: initBigInt(123456), exponent: 0))
assert(newDecimal(-9999999) == Decimal(sign: 1, value: initBigInt(9999999), exponent: 0))
assert(newDecimal(984323112) == Decimal(sign: 0, value: initBigInt(984323112), exponent: 0))
assert(newDecimal(-99999900) == Decimal(sign: 1, value: initBigInt(99999900), exponent: 0))
assert(newDecimal(987654323) != Decimal(sign: 0, value: initBigInt(99998999999), exponent: 0))
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
assert($newDecimal(123456) == $Decimal(sign: 0, value: initBigInt(123456), exponent: 0))
assert($newDecimal(-9999999) == $Decimal(sign: 1, value: initBigInt(9999999), exponent: 0))
assert($newDecimal(984323112) == $Decimal(sign: 0, value: initBigInt(984323112), exponent: 0))
assert($newDecimal(-99999900) == $Decimal(sign: 1, value: initBigInt(99999900), exponent: 0))
assert($newDecimal(987654323) != $Decimal(sign: 0, value: initBigInt(99998999999), exponent: 0))
assert($newDecimal(123456) == $Decimal(sign: 0, value: initBigInt(123456), exponent: 0))
assert($newDecimal(-9999999) == $Decimal(sign: 1, value: initBigInt(9999999), exponent: 0))
assert($newDecimal(984323112) == $Decimal(sign: 0, value: initBigInt(984323112), exponent: 0))
assert($newDecimal(-99999900) == $Decimal(sign: 1, value: initBigInt(99999900), exponent: 0))
assert($newDecimal(987654323) != $Decimal(sign: 0, value: initBigInt(99998999999), exponent: 0))
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
