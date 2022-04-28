function test() 
    local count = 0
    while count < 100 do
        selfAxis:abs_move_with_wait(-10)
        selfAxis:abs_move_with_wait(-30)
        count = count + 1
    end
end