import decimal, bigints

# Initialisation tests with zero values - tests for: string parsing, string formatting

assert($(initDecimal("0")) == "0")
assert($(initDecimal("-0")) == "-0")
assert($(initDecimal("+0")) ==  "0")
assert($(initDecimal("0E0")) ==  "0")
assert($(initDecimal("0E-0")) ==  "0")
assert($(initDecimal("0E+0")) == "0")
assert($(initDecimal("+0E0")) == "0")
assert($(initDecimal("+0E-0")) == "0")
assert($(initDecimal("+0E+0")) == "0")
assert($(initDecimal("-0E0")) == "-0")
assert($(initDecimal("-0E-0")) == "-0")
assert($(initDecimal("-0E+0")) == "-0")
assert($(initDecimal("0.0")) == "0.0")
assert($(initDecimal("-0.0")) == "-0.0")
assert($(initDecimal("+0.0")) == "0.0")
assert($(initDecimal("0.00000000000000000000000000000000000000000000000000000000000000000000000000")) == "0E-74")
assert($(initDecimal("+0.00000000000000000000000000000000000000000000000000000000000000000000000000")) == "0E-74")
assert($(initDecimal("-0.00000000000000000000000000000000000000000000000000000000000000000000000000")) == "-0E-74")
assert($(initDecimal("0.0E100")) == "0E+99")
assert($(initDecimal("-0.0E-100")) == "-0E-101")
assert($(initDecimal("+0.0E+100")) == "0E+99")
assert($(initDecimal("00000000")) == "0")
assert($(initDecimal("00000000E10")) == "0E+10")
assert($(initDecimal("00000000E-10")) == "0E-10")
assert($(initDecimal("-00000000E10")) == "-0E+10")
assert($(initDecimal("+00000000E-10")) == "0E-10")
assert($(initDecimal("+01000000E-10")) == "0.0001000000")
assert($(initDecimal("-01000000E-10")) == "-0.0001000000")
assert($(initDecimal("+01000000E+10")) == "1.000000E+16")
assert($(initDecimal("+01000000E10")) == "1.000000E+16")
assert($(initDecimal("+10000000E-10")) == "0.0010000000")
assert($(initDecimal("+00000001E-10")) == "1E-10")
assert($(initDecimal("-10000000E-10")) == "-0.0010000000")
assert($(initDecimal("-00000001E-10")) == "-1E-10")
assert($(initDecimal("+00000001E10")) == "1E+10")
assert($(initDecimal("-00000001E10")) == "-1E+10")

# Combined arithmetic all inputs positive numbers - tests for: arithmetic, string formatting

assert($(initDecimal("0.0000000000000000000001928374272") * initDecimal("92222222222222222") * initDecimal("2")) == "0.0000355677921279999999142944768")
assert($(initDecimal("0.0000000000000000000001928374272") * initDecimal("92222222222222222.00000000") / initDecimal("0.02")) == "0.0008891948031999999978573619200")
assert($(initDecimal("0.10") * initDecimal("1212522222") + initDecimal("36236.02")) == "121288458.22")
assert($(initDecimal("1000020002002000200020002001929824") * initDecimal("5843255") - initDecimal("27843")) == "5.843371876798197678767876798E+39")
assert($(initDecimal("100000000000000000000001928374272") / initDecimal("87257") * initDecimal("23")) == "2.635891676312502148824786953E+28")
assert($(initDecimal("0.00000000000000000000001") / initDecimal("9222228387822222222222") / initDecimal("262346246")) == "4.133227141563679397385840448E-54")
assert($(initDecimal("0.000000000000000000000000000000001") / initDecimal("27882782") - initDecimal("2097545647")) == "-2097545647.000000000000000000")
assert($(initDecimal("0.0000745472") / initDecimal("7889489.4717") + initDecimal("223675")) == "223675.0000000000094489257217")
assert($(initDecimal("0.7667786") + initDecimal("132465") * initDecimal("234677347")) == "31086534770355.7667786")
assert($(initDecimal("232320.0000000000000000000001928374272") + initDecimal("922222237872222222222142") / initDecimal("34574752.784")) == "26673285088737559.68571152980")
assert($(initDecimal("0.8") + initDecimal("92222222837373222222222344") - initDecimal("2252")) == "92222222837373222222220092.8")
assert($(initDecimal("1232332.113422232322") + initDecimal("78454") + initDecimal("2673346.55652")) == "3984132.669942232322")
assert($(initDecimal("0.445") - initDecimal("97635") * initDecimal("488442")) == "-47689034669.555")
assert($(initDecimal("50") - initDecimal("14235.11242") / initDecimal("234784")) == "49.93936932491140793239743764")
assert($(initDecimal("9999999999999999") - initDecimal("784555555688.89456752") - initDecimal("345332")) == "9999215444098978.10543248")
assert($(initDecimal("19283722.127") - initDecimal("7744.22222") + initDecimal("88984562")) == "108260539.90478")
assert(initDecimal("0.1") + initDecimal("0.1") + initDecimal("0.1") + initDecimal("0.1") + 
  initDecimal("0.1") + initDecimal("0.1") + initDecimal("0.1") + initDecimal("0.1") == initDecimal("0.8"))
assert(initDecimal("0.1") * initDecimal("0.1") * initDecimal("0.1") * initDecimal("0.1") * 
  initDecimal("0.1") * initDecimal("0.1") * initDecimal("0.1") * initDecimal("0.1") == initDecimal("1E-8"))

# Combined arithmetic all inputs negative numbers - tests for: arithmetic, string formatting

assert($(initDecimal("-0.0000000000000000000001928374272") * initDecimal("-92222222222222222") * initDecimal("-2")) == "-0.0000355677921279999999142944768")
assert($(initDecimal("-0.0000000000000000000001928374272") * initDecimal("-92222222222222222.00000000") / initDecimal("-0.02")) == "-0.0008891948031999999978573619200")
assert($(initDecimal("-0.10") * initDecimal("-1212522222") + initDecimal("-36236.02")) == "121215986.18")
assert($(initDecimal("-1000020002002000200020002001929824") * initDecimal("-5843255") - initDecimal("-27843")) == "5.843371876798197678767876798E+39")
assert($(initDecimal("-100000000000000000000001928374272") / initDecimal("-87257") * initDecimal("-23")) == "-2.635891676312502148824786953E+28")
assert($(initDecimal("-0.00000000000000000000001") / initDecimal("-9222228387822222222222") / initDecimal("-262346246")) == "-4.133227141563679397385840448E-54")
assert($(initDecimal("-0.000000000000000000000000000000001") / initDecimal("-27882782") - initDecimal("-2097545647")) == "2097545647.000000000000000000")
assert($(initDecimal("-0.0000745472") / initDecimal("-7889489.4717") + initDecimal("-223675")) == "-223674.9999999999905510742783")
assert($(initDecimal("-0.7667786") + initDecimal("-132465") * initDecimal("-234677347")) == "31086534770354.2332214")
assert($(initDecimal("-232320.0000000000000000000001928374272") + initDecimal("-922222237872222222222142") / initDecimal("-34574752.784")) == "26673285088272919.68571152980")
assert($(initDecimal("-0.8") + initDecimal("-92222222837373222222222344") - initDecimal("-2252")) == "-92222222837373222222220092.8")
assert($(initDecimal("-1232332.113422232322") + initDecimal("-78454") + initDecimal("-2673346.55652")) == "-3984132.669942232322")
assert($(initDecimal("-0.445") - initDecimal("-97635") * initDecimal("-488442")) == "-47689034670.445" )
assert($(initDecimal("-50") - initDecimal("-14235.11242") / initDecimal("-234784")) == "-50.06063067508859206760256236")
assert($(initDecimal("-9999999999999999") - initDecimal("-784555555688.89456752") - initDecimal("-345332")) == "-9999215444098978.10543248")
assert($(initDecimal("-19283722.127") - initDecimal("-7744.22222") + initDecimal("-88984562")) == "-108260539.90478" )
assert(initDecimal("-0.1") + initDecimal("-0.1") + initDecimal("-0.1") + initDecimal("-0.1") + 
  initDecimal("-0.1") + initDecimal("-0.1") + initDecimal("-0.1") + initDecimal("-0.1") == initDecimal("-0.8"))
assert(initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("-0.1") * 
  initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("-0.1") == initDecimal("1E-8"))

# Combined arithmetic inputs with varying signs - tests for: arithmetic, string formatting

assert($(initDecimal("-0.0000000000000000000001928374272") * initDecimal("92222222222222222") * initDecimal("2")) == "-0.0000355677921279999999142944768")
assert($(initDecimal("0.0000000000000000000001928374272") * initDecimal("-92222222222222222.00000000") / initDecimal("0.02")) == "-0.0008891948031999999978573619200")
assert($(initDecimal("0.10") * initDecimal("1212522222") + initDecimal("-36236.02")) == "121215986.18" )
assert($(initDecimal("1000020002002000200020002001929824") * initDecimal("-5843255") - initDecimal("27843")) == "-5.843371876798197678767876798E+39")
assert($(initDecimal("-100000000000000000000001928374272") / initDecimal("87257") * initDecimal("23")) == "-2.635891676312502148824786953E+28")
assert($(initDecimal("0.00000000000000000000001") / initDecimal("-9222228387822222222222") / initDecimal("262346246")) == "-4.133227141563679397385840448E-54")
assert($(initDecimal("0.000000000000000000000000000000001") / initDecimal("27882782") - initDecimal("-2097545647")) == "2097545647.000000000000000000")
assert($(initDecimal("0.0000745472") / initDecimal("-7889489.4717") + initDecimal("-223675")) == "-223675.0000000000094489257217")
assert($(initDecimal("-0.7667786") + initDecimal("-132465") * initDecimal("234677347")) == "-31086534770355.7667786")
assert($(initDecimal("-232320.0000000000000000000001928374272") + initDecimal("-922222237872222222222142") / initDecimal("34574752.784")) == "-26673285088737559.68571152980")
assert($(initDecimal("0.8") + initDecimal("92222222837373222222222344") - initDecimal("2252")) == "92222222837373222222220092.8")
assert($(initDecimal("1232332.113422232322") + initDecimal("-78454") + initDecimal("-2673346.55652")) == "-1519468.443097767678")
assert($(initDecimal("0.445") - initDecimal("-97635") * initDecimal("488442")) == "47689034670.445")
assert($(initDecimal("50") - initDecimal("-14235.11242") / initDecimal("234784")) == "50.06063067508859206760256236")
assert($(initDecimal("9999999999999999") - initDecimal("-784555555688.89456752") - initDecimal("345332")) == "10000784555210355.89456752")
assert($(initDecimal("19283722.127") - initDecimal("-7744.22222") + initDecimal("-88984562")) == "-69693095.65078")
assert(initDecimal("-0.1") + initDecimal("+0.1") + initDecimal("-0.1") + initDecimal("+0.1") + 
  initDecimal("-0.1") + initDecimal("+0.1") + initDecimal("-0.1") + initDecimal("-0.1") == initDecimal("-0.2"))
assert(initDecimal("-0.1") * initDecimal("-0.1") * initDecimal("+0.1") * initDecimal("-0.1") * 
  initDecimal("-0.1") * initDecimal("+0.1") * initDecimal("-0.1") * initDecimal("-0.1") == initDecimal("1E-8"))
  
#[

TODO:

Initialisation tests:
 - Very large values
 - Very small values
 - NaN handling
 - Exception handling
 - A range of common numbers
 - From bigints
 - From ints
 - From floats
 - From Decimal
 
Rounding tests:
 - RoundHalfEven
 - RoundUp
 - RoundDown
 - RoundHalfUp
 - RoundCeiling
 - RoundFloor
 - RoundHalfDown
 - Round05Up

Unit tests per function:
 - abs
 - add and subtract
 - compare
 - compare-signal
 - divide
 - divide-integer
 - exp
 - fused-multiply-add
 - ln
 - log10
 - max
 - max-magnitude
 - min
 - min-magnitude
 - minus and plus
 - multiply
 - next-minus
 - next-plus
 - next-toward
 - power
 - quantize
 - reduce
 - remainder
 - remainder-near
 - round-to-integral-exact
 - round-to-integral-value
 - square-root
 - and
 - canonical
 - class
 - compare-total
 - compare-total-magnitude
 - copy
 - copy-abs
 - copy-negate
 - copy-sign
 - invert
 - is-canonical
 - is-finite
 - is-infinite
 - is-NaN
 - is-normal
 - is-qNaN
 - is-signed
 - is-sNaN
 - is-subnormal
 - is-zero
 - logb
 - or
 - radix
 - rotate
 - same-quantum
 - scaleb
 - shift
 - xor
 
Exception tests:

Context tests:

 ]#
