accuracy  = 100000

function get_win_types(sum, dice)
    local win_types = { } 
    local baozi = false
    local oe = ''
    local bs = ''

    --- sum
    table.insert(win_types, 'sum-'..sum)

    --- check even or odd
    if (sum % 2 == 0) then
        oe = 'oe-even'
    else
        oe = 'oe-odd'
    end
    table.insert(win_types, oe)

    --- sort dice
    for i = 1,3,1 do
        for j = 1,3-i,1 do
            if (dice[j] > dice[j+1]) then
                local tmp = dice[j+1]
                dice[j+1] = dice[j]
                dice[j] = tmp
            end
        end
    end

    --- check baozi/two/one
    if (dice[1] == dice[2]) then
        table.insert(win_types, 'two-'..dice[1]..'-'..dice[2])
        if (dice[2] == dice[3]) then
            table.insert(win_types, 'baozi-'..dice[1])
            table.insert(win_types, 'baozi-all')
            table.insert(win_types, 'one-'..dice[1]..'-3')
            baozi = true
        else
            table.insert(win_types, 'two-'..dice[1]..'-'..dice[3])
            table.insert(win_types, 'one-'..dice[3]..'-1')
            table.insert(win_types, 'one-'..dice[1]..'-2')
        end
    elseif (dice[2] == dice[3]) then
        table.insert(win_types, 'two-'..dice[1]..'-'..dice[2])
        table.insert(win_types, 'two-'..dice[2]..'-'..dice[3])
        table.insert(win_types, 'one-'..dice[1]..'-1')
        table.insert(win_types, 'one-'..dice[2]..'-2')
    else
        table.insert(win_types, 'one-'..dice[1]..'-1')
        table.insert(win_types, 'one-'..dice[2]..'-1')
        table.insert(win_types, 'one-'..dice[3]..'-1')
        table.insert(win_types, 'two-'..dice[1]..'-'..dice[2])
        table.insert(win_types, 'two-'..dice[2]..'-'..dice[3])
        table.insert(win_types, 'two-'..dice[1]..'-'..dice[3])
    end

    --- check big or small
    if not baozi then
        if ( sum > 10 ) then
            bs = 'bs-big'
        else
            bs = 'bs-small'
        end
        table.insert(win_types, bs)
    end

    return win_types
end

function if_match(tab, val)
    local odds = {
        ["bs-small"] = 1,
        ["oe-even"] = 1,
        ["two-1-1"] = 8,
        ["two-2-2"] = 8,
        ["two-3-3"] = 8,
        ["baozi-1"] = 150,
        ["baozi-2"] = 150,
        ["baozi-3"] = 150,
        ["baozi-all"] = 24,
        ["baozi-4-4"] = 150,
        ["baozi-5-5"] = 150,
        ["baozi-6-6"] = 150,
        ["two-4-4"] = 8,
        ["two-5-5"] = 8,
        ["two-6-6"] = 8,
        ["bs-big"] = 1,
        ["oe-odd"] = 1,
        ["sum-4"] = 50,
        ["sum-5"] = 18,
        ["sum-6"] = 14,
        ["sum-7"] = 12,
        ["sum-8"] = 8,
        ["sum-9"] = 6,
        ["sum-10"] = 6,
        ["sum-11"] = 6,
        ["sum-12"] = 6,
        ["sum-13"] = 8,
        ["sum-14"] = 12,
        ["sum-15"] = 14,
        ["sum-16"] = 18,
        ["sum-17"] = 50,
        ["two-1-2"] = 5,
        ["two-1-3"] = 5,
        ["two-1-4"] = 5,
        ["two-1-5"] = 5,
        ["two-1-6"] = 5,
        ["two-2-3"] = 5,
        ["two-2-4"] = 5,
        ["two-2-5"] = 5,
        ["two-2-6"] = 5,
        ["two-3-4"] = 5,
        ["two-3-5"] = 5,
        ["two-3-6"] = 5,
        ["two-4-5"] = 5,
        ["two-4-6"] = 5,
        ["two-5-6"] = 5,
        ["one-1-1"] = 1,
        ["one-2-1"] = 1,
        ["one-3-1"] = 1,
        ["one-4-1"] = 1,
        ["one-5-1"] = 1,
        ["one-6-1"] = 1,
        ["one-1-2"] = 2,
        ["one-2-2"] = 2,
        ["one-3-2"] = 2,
        ["one-4-2"] = 2,
        ["one-5-2"] = 2,
        ["one-6-2"] = 2,
        ["one-1-3"] = 3,
        ["one-2-3"] = 3,
        ["one-3-3"] = 3,
        ["one-4-3"] = 3,
        ["one-5-3"] = 3,
        ["one-6-3"] = 3
    }
    local r = 0
    for i, v in pairs(tab) do
        local tmp = ''

        if string.match(v, "one") then
            tmp = string.sub(v, 1, 5)
        else
            tmp = v
        end

        if ( val == tmp ) then
            return odds[v] 
        end
    end
    return r 
end

function dice(round, betInfoJSON)
    assert(chainhelper:is_owner(),'You`re not the contract`s owner')

    local results = { }
    local dice = { }
    local sum = 0

    local betInfo = cjson.decode(betInfoJSON)
    
    for i = 1,3,1
    do
        dice[i] = chainhelper:random() % 6 + 1
        sum = sum + dice[i]
    end
    
    results["round"] = round
    results["dice"] = dice
    results["win-types"] = get_win_types(sum, dice)

    if (results["plyrInfo"] == nil) then
        results["plyrInfo"] = { }
    end

    for player, info in pairs(betInfo) do
        local player_win_types = { } 
        local player_result = { }
        local prize = 0

        for t, p in pairs(info["bet"]) do
            local tmp_odds = if_match(results["win-types"], t)
            if (tmp_odds > 0) then
                table.insert(player_win_types, t)
                prize = prize + p * (tmp_odds + 1)
            end
        end

        player_result["prize"] = prize
        player_result["total-bets"] = info["total-bets"]
        player_result["player-win-types"] = player_win_types 
        results["plyrInfo"][player] = player_result
    end

    for player, info in pairs(results["plyrInfo"]) do
        chainhelper:transfer_from_owner(player, info["prize"] * accuracy, 'COCOS', false)
    end

    local output = cjson.encode(results)
    chainhelper:log('##result##:'..output)
end

function bet(round, bet)
    local info = { }
    local price = 0
    local bettab = cjson.decode(bet)

    for k, v in pairs(bettab) do
        price = price + v
    end

    chainhelper:transfer_from_caller(contract_base_info.owner, price * accuracy, 'COCOS', false)

    info["player"] = contract_base_info.caller
    info["bet"] = bettab
    info["total-bets"] = price
    info["round"] = round 
    
    local output = cjson.encode(info)
    chainhelper:log('##result##:'..output)
end
