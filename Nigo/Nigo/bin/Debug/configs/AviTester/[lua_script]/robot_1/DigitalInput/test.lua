local json = require("json")

function testFunc(arg) 
    selfDigitalInput:get_status()
    gErrorLog("hi, greed from lua!")
    local tOutput = man:get_digital_output("test_output")
    tOutput:turn_on()
end