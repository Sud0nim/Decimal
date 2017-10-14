# BigDecimal
An attempt to build a native BigDecimal class in Nim off the back of the Nim BigInts package: https://github.com/def-/nim-bigints

This is highly experimental and I have no experience in actually building a decimal class. Please use at your own risk, but feel free to contribute.

# Some preliminary tests of arithmetic with arbitrary precision decimal types:

Input:

    var
    x = newDecimal("112777777777777777777777777444444111111111111111111111111111111111444444444444444444444444777779999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999934.0")
    y = newDecimal("1244444444444442222222222222222222222444444444444422.0")
    z = newDecimal("999999999999.121212")
  
    echo x / y
    echo y / z
    echo x * z
    
Output:

    # echo x / y :  
    90625000000000161830357142589574429193000159954339450231471857289780848499459693727052506943148357414243207436017985101914339047458766791490808059955137208949.517557215824294987242398881027363408665486056413106418017314911398308615494752087567379239927724729668269716171177825767847757466317366805810294142890487067219100071242117501
    
    # echo y / z :      
    124444444444553582506666762575.88609091539498223050555812564438151841411877474580410661
    
    # echo x * z :
    112777777777678670019999999666666333333626262959596000000000000000333333333333040404000000333335555555262624269359999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999934000000000058.0000080
    
    
