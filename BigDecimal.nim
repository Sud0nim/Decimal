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
  var 
    inputString = $number
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
    result.exponent = components[1].len  * -1

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

proc `$`*(number: Decimal): string =
  #TODO: make sure to add enough zeros for precision setting so that format + precision is preserved for consistency
  # also optimise this, it is very wasteful
  var
    value = $number.value
    precision = 15
    sign = ""
    decimalPosition = value.len - abs(number.exponent)
    trailingZeros = precision - abs(number.exponent)
  echo decimalPosition
  if number.sign == 1:
    sign = "-"
  if decimalPosition < 0:
    result =   value[decimalPosition..value.high]
    for i in 0..<abs(decimalPosition):
      result = "0" & result
    result = "0" & "." & result
  else:
    result = value[0..<decimalPosition] & "." & value[decimalPosition..value.high]
  result = sign & result
  if trailingZeros > 0:
    for i in 0..<trailingZeros:
      result = result & "0"

proc `echo`(number: Decimal) =
  echo $number

proc `^`[T: float|int](base: T; exp: int): T =
  var (base, exp) = (base, exp)
  result = 1
 
  if exp < 0:
    when T is int:
      if base * base != 1: return 0
      elif (exp and 1) == 0: return 1
      else: return base
    else:
      base = 1.0 / base
      exp = -exp
 
  while exp != 0:
    if (exp and 1) != 0:
      result *= base
    exp = exp shr 1
    base *= base
 
proc `*`(a, b: Decimal): Decimal =
  result.exponent = a.exponent + b.exponent
  result.sign = a.sign xor b.sign
  result.value = a.value * b.value

proc `/`*(a, b: Decimal): Decimal =
  var
    precision = 15
    quotient, remainder: BigInt
    sign = a.sign * b.sign 
    shift = len($a.value) + len($b.value) + precision + 1  # changed this to add lengths instead of subtract, sort out precision later
    exp = a.exponent - b.exponent + shift
  if shift >= 0:
    quotient = (a.value * pow(initBigInt(10), initBigInt(shift))) div b.value
    remainder = (a.value * pow(initBigInt(10), initBigInt(shift))) mod b.value
  else:
    quotient = (a.value * pow(initBigInt(10), initBigInt(-1 * shift))) div b.value
    remainder = (a.value * pow(initBigInt(10), initBigInt(-1 * shift))) mod b.value
  if remainder != 0:
    if quotient mod 5 == 0:
      quotient = quotient + 1
  result.sign = sign
  result.value = quotient
  result.exponent = (a.exponent - b.exponent - shift)
  

proc `+`(a, b: Decimal): Decimal =
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

proc `-`*(a,b: Decimal): Decimal =
  result = b
  if result.sign == 1:
    result.sign = 0
  else:
    result.sign = 1
  result = a + result

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
