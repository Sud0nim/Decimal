import decimal, bigints

assert($initDecimal("123") == "123")
assert($initDecimal("-123") == "-123")
assert($initDecimal("1.23E+3") == "1.23E+3")
assert($initDecimal("1.23E+5") == "1.23E+5")
assert($initDecimal("12.3") == "12.3")
assert($initDecimal("0.00123") == "0.00123")
assert($initDecimal("1.23E-8") == "1.23E-8")
assert($initDecimal("-1.23E-10") == "-1.23E-10")
assert($initDecimal("0") == "0")
assert($initDecimal("0.00") == "0.00")
assert($initDecimal("0E+2") == "0E+2")
assert($initDecimal("-0") == "-0")
assert($initDecimal("0.000005") == "0.000005")
assert($initDecimal("0.0000050") == "0.0000050")
assert($initDecimal("5E-7") == "5E-7")
#assert($initDecimal("Infinity") == "Infinity")
#assert($initDecimal("-Infinity") == "-Infinity")
#assert($initDecimal("NaN") == "NaN")
#assert($initDecimal("NaN123") == "NaN")
#assert($initDecimal("-sNaN") == "sNaN")
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

# allZeros

assert("0000000000".allZeros(0) == true)
assert("0".allZeros(0) == true)
assert("0001000000000000000000000000000000".allZeros(4) == true)
assert("10".allZeros(1) == true)
assert("0000000000O".allZeros(0) == false)
assert("0h".allZeros(0) == false)
assert("00000000010000000000000000000000000".allZeros(0) == false)
assert("001".allZeros(0) == false)

# allNines

assert("99999999999999999".allNines(0) == true)
assert("9".allNines(0) == true)
assert("35235235999999999999999999999999999999999999".allNines(8) == true)
assert("09".allNines(1) == true)
assert("9999989999".allNines(0) == false)
assert("9h".allNines(0) == false)
assert("9999999999959999999999999".allNines(3) == false)
assert("991".allNines(0) == false)

# exactHalf

assert("5000000000".exactHalf(0) == true)
assert("50".exactHalf(0) == true)
assert("0000000523324500000000000".exactHalf(13) == true)
assert("005".exactHalf(2) == true)
assert("00000000004".exactHalf(3) == false)
assert("40".exactHalf(0) == false)
assert("00000032523300000000000000000000".exactHalf(11) == false)
assert("001".exactHalf(2) == false)

# stripLeadingZeros

assert("000000000".stripLeadingZeros() == "0")
assert("50".stripLeadingZeros() == "50")
assert("0000000523324500000000000".stripLeadingZeros() == "523324500000000000")
assert("005".stripLeadingZeros() == "5")
assert("00000000004".stripLeadingZeros() == "4")
assert("40".stripLeadingZeros() == "40")
assert("00000032523300000000000000000000".stripLeadingZeros() == "32523300000000000000000000")
assert("001".stripLeadingZeros() == "1")

# initDecimal (BigInt)

assert($initDecimal(initBigInt(12928)) == "12928")
assert($initDecimal(initBigInt(12928) - initBigInt(12928)) == "0")
assert($initDecimal(initBigInt("-12928") - initBigInt("-12928")) == "0")
assert($initDecimal(initBigInt("-12928") + initBigInt("-12928")) == "-25856")
assert($initDecimal(initBigInt("12928") + initBigInt("12928")) == "25856")
assert($initDecimal(initBigInt("787878787878787878787878787878787878787878787878787878787878787878787878787878")) == "787878787878787878787878787878787878787878787878787878787878787878787878787878")

# Combined Arithmetic

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

# `==`

assert(initDecimal("99999999999") == initDecimal("99999999999"))
assert(initDecimal(99999999999) == initDecimal("99999999999"))
assert(initDecimal(initBigInt("99999999999")) == initDecimal("99999999999"))
assert(initDecimal("99999.999999") == initDecimal("99999.999999"))
assert(initDecimal("0.000000000000000001213131310001313") == initDecimal("0.000000000000000001213131310001313"))
assert(initDecimal("9999999999928923998289239.29") == initDecimal("9999999999928923998289239.29"))
assert(initDecimal(initBigInt("0")) == initDecimal("-0"))

# `!=`

assert(initDecimal("99999999999") != initDecimal("99899999999"))
assert(initDecimal(999999) != initDecimal("99999999999"))
assert(initDecimal(initBigInt("1")) != initDecimal("99999999999"))
assert(initDecimal("99999.999999") != initDecimal("999999.99999"))
assert(initDecimal("0.000000000000000001213131310001313") != initDecimal("1.000000000000000001213131310001313"))

# `>`

assert(initDecimal("99999999999") > initDecimal("99899999999"))
assert(initDecimal(9999999) > initDecimal("999999"))
assert(initDecimal(initBigInt("99999999999")) > initDecimal("1"))
assert(initDecimal("999999.99999") > initDecimal("999999.99998"))
assert(initDecimal("1.000000000000000001213131310001313") > initDecimal("0.000000000000000001213131310001313"))

# `>=`

assert(initDecimal("99999999999") >= initDecimal("99899999999"))
assert(initDecimal(9999999) >= initDecimal("999999"))
assert(initDecimal(initBigInt("99999999999")) >= initDecimal("1"))
assert(initDecimal("999999.99999") >= initDecimal("999999.99999"))
assert(initDecimal("0.000000000000000001213131310001313") >= initDecimal("0.000000000000000001213131310001313"))
assert(initDecimal(initBigInt("0")) >= initDecimal("-0"))

# `<`

assert(initDecimal("99999999999") < initDecimal("999999999999"))
assert(initDecimal(9999999) < initDecimal("99933999"))
assert(initDecimal(initBigInt("99999999999")) < initDecimal("11111111121111.0000"))
assert(initDecimal("699999.99999") < initDecimal("899999.99998"))
assert(initDecimal("1.000000000000000001213131310001313") < initDecimal("2.000000000000000001213131310001313"))

# `<=`

assert(initDecimal("99999999999") <= initDecimal("999999999999"))
assert(initDecimal(9999999) <= initDecimal("99933999"))
assert(initDecimal(initBigInt("99999999999")) <= initDecimal("11111111121111.0000"))
assert(initDecimal("899999.99998") <= initDecimal("899999.99998"))
assert(initDecimal("2.000000000000000001213131310001313") <= initDecimal("2.000000000000000001213131310001313"))
assert(initDecimal(initBigInt("-0")) <= initDecimal("0"))

#[ Int initialisation

assert(initDecimal(123456) == Decimal(sign: 0, coefficient: "123456", exponent: 0, isSpecial: false))
assert(initDecimal(-9999999) == Decimal(sign: 1, coefficient: "9999999", exponent: 0, isSpecial: false))
assert(initDecimal(984323112) == Decimal(sign: 0, coefficient: "984323112", exponent: 0, isSpecial: false))
assert(initDecimal(-99999900) == Decimal(sign: 1, coefficient: "99999900", exponent: 0, isSpecial: false))
assert(initDecimal(987654323) != Decimal(sign: 0, coefficient: "99998999999", exponent: 0, isSpecial: false))

# Float initialisation

assert(initDecimal("0.123844") == initDecimal(0.123844))
assert(initDecimal("-9999999") == initDecimal(-9999999))
assert(initDecimal("9999999999999.99") == initDecimal(9999999999999.99))
assert(initDecimal("-9999999.113") == initDecimal(-9999999.113))
assert(initDecimal("99999999999.99001") == initDecimal(99999999999.99))

# Bigint initialisation

assert(initDecimal("2839278492047202928") == initDecimal(initBigInt(2839278492047202928)))
assert(initDecimal("-2839278492047202928") == initDecimal(initBigInt(-2839278492047202928)))
assert(initDecimal("100000000000000000000000000000288782827884782424999999999999999") == initDecimal(initBigInt("100000000000000000000000000000288782827884782424999999999999999")))
assert(initDecimal("0") == initDecimal(initBigInt(-0)))
assert(initDecimal("1") == initDecimal(initBigInt(1)))

# Decimal initialisation

assert(initDecimal("0.123844") == initDecimal(initDecimal("0.123844")))
assert(initDecimal("-9999999") == initDecimal(initDecimal("-9999999")))
assert(initDecimal("9999999999999.99") == initDecimal(initDecimal("9999999999999.99")))
assert(initDecimal("-9999999.113") == initDecimal(initDecimal("-9999999.113")))
assert(initDecimal("9999999999999") == initDecimal(initDecimal("9999999999999")))

# NaN's

assert(initDecimal("abcdefgh") == Decimal(sign: 0, coefficient: "qNaN", exponent: 0, isSpecial: true))
assert(initDecimal("99999d99a") == Decimal(sign: 0, coefficient: "qNaN", exponent: 0, isSpecial: true))
assert(initDecimal("9999.999999999.99") == Decimal(sign: 0, coefficient: "qNaN", exponent: 0, isSpecial: true))
assert(initDecimal("--9999999.113") == Decimal(sign: 1, coefficient: "qNaN", exponent: 0, isSpecial: true))
assert(initDecimal("++9999999999999") == Decimal(sign: 0, coefficient: "qNaN", exponent: 0, isSpecial: true))
assert(initDecimal("102399999999999999999999993833333E33333337777777777777777727729999999999999e199999999999999999999999999999282671") == Decimal(sign: 0, coefficient: "qNaN", exponent: 0, isSpecial: true))
assert(initDecimal("") == Decimal(sign: 0, coefficient: "qNaN", exponent: 0, isSpecial: true))
assert(initDecimal(" ") == Decimal(sign: 0, coefficient: "qNaN", exponent: 0, isSpecial: true))
assert(initDecimal("-") == Decimal(sign: 1, coefficient: "qNaN", exponent: 0, isSpecial: true))
assert(initDecimal("+") == Decimal(sign: 0, coefficient: "qNaN", exponent: 0, isSpecial: true))
assert(initDecimal("+sNan") == Decimal(sign: 0, coefficient: "sNaN", exponent: 0, isSpecial: true))
assert(initDecimal("-snan") == Decimal(sign: 1, coefficient: "sNaN", exponent: 0, isSpecial: true))
assert(initDecimal("SNAN") == Decimal(sign: 0, coefficient: "sNaN", exponent: 0, isSpecial: true))

# Infinite

assert(initDecimal("inf") == Decimal(sign: 0, coefficient: "infinity", exponent: 0, isSpecial: true))
assert(initDecimal("-inf") == Decimal(sign: 1, coefficient: "infinity", exponent: 0, isSpecial: true))
assert(initDecimal("+inf") == Decimal(sign: 0, coefficient: "infinity", exponent: 0, isSpecial: true))
assert(initDecimal("+inF") == Decimal(sign: 0, coefficient: "infinity", exponent: 0, isSpecial: true))
assert(initDecimal("INfinITY") == Decimal(sign: 0, coefficient: "infinity", exponent: 0, isSpecial: true))
assert(initDecimal("infinity") == Decimal(sign: 0, coefficient: "infinity", exponent: 0, isSpecial: true))
assert(initDecimal("-infinity") == Decimal(sign: 1, coefficient: "infinity", exponent: 0, isSpecial: true))
assert(initDecimal("+infinity") == Decimal(sign: 0, coefficient: "infinity", exponent: 0, isSpecial: true))

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
