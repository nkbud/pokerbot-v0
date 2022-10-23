module Community2HeroCount

    using JSON
    using Dates
    import Base.Threads.@spawn

    include("lib/HandKeys.jl")
    include("lib/ResultKeys.jl")
    include("lib/Logs.jl")
    using .ResultKeys
    using .HandKeys
    using .Logs

    export executeCommunity2HeroResultCount

    function parseFlopString(flopString::String)
        heroCards = split(obj, " ")[1:2]
        remainingIndices = filter(x -> !( x in indices ), 1:52)
        return join(heroCards, " "), remainingIndices
    end

    function printCommunity2HeroResultCount(dealKey2CardIndices::Pair{String, Vector{String}}, allCards::Vector{String})

        # dict["result"] = count
        hero2ResultCount = Dict{String, Int32}()

        # dict[community][hero][result] = count
        flop2HeroResultCount = Dict{String, Dict{String, Dict{String, Int32}}}()
        turn2HeroResultCount = Dict{String, Dict{String, Dict{String, Int32}}}()
        river2HeroResultCount = Dict{String, Dict{String, Dict{String, Int32}}}()

        len1 = 50  # removing 2 hero cards
        len2 = 47  # removing 3 flop cards
        len3 = 46  # removing 1 turn card

        dealKey = dealKey2CardIndices[1]
        dealStrings = dealKey2CardIndices[2]
        for dealString in dealStrings
            heroCards, remainingIndices = parseDealString(dealString)

            # flop
            for c in 1:len1
                cs = allCards[remainingIndices[c]]
                for d in (c+1):len1
                    ds = allCards[remainingIndices[d]]
                    for e in (d+1):len1
                        es = allCards[remainingIndices[e]]
                        flopCards = "$heroCards $cs $ds $es"
                        flopKey = input2HandKey(flopCards)
                        flopComm = flopKey[1:6]
                        flopHero = flopKey[7:end]
                        if ! haskey(flop2HeroResultCount, flopComm)
                            flop2HeroResultCount[flopComm] = Dict{String, Dict{String, Int32}}()
                        end

                        remainingIndices2 = filter(x -> !(x in [c, d, e]), remainingIndices)
        
                        # turn
                        for f in 1:len2
                            fs = allCards[remainingIndices2[f]]
                            turnCards = "$flopCards $fs"
                            turnKey = input2HandKey(turnCards)
                            turnComm = turnKey[1:8]
                            turnHero = turnKey[9:end]
                            if ! haskey(turn2HeroResultCount, turnComm)
                                turn2HeroResultCount[turnComm] = Dict{String, Dict{String, Int32}}()
                            end

                            remainingIndices3 = filter(x -> x != f, remainingIndices2)
                            
                            # river
                            for g in 1:len3
                                gs = allCards[remainingIndices3[g]]
                                riverKey = input2HandKey("$turnCards $gs")
                                riverComm = riverKey[1:10]
                                riverHero = riverKey[11:end]
                                if ! haskey(river2HeroResultCount, riverComm)
                                    river2HeroResultCount[riverComm] = Dict{String, Dict{String, Int32}}()
                                end

                                resultKey = findResultKey(riverKey)

                                # new result ? 1 : +1
                                if ! haskey(hero2ResultCount, resultKey)
                                    hero2ResultCount[resultKey] = 1
                                else
                                    hero2ResultCount[resultKey] += 1
                                end
                                if ! haskey(flop2HeroResultCount[flopComm], flopHero) 
                                    flop2HeroResultCount[flopComm][flopHero] = Dict{String, Int32}([(resultKey, 1)])
                                elseif ! haskey(flop2HeroResultCount[flopComm][flopHero], resultKey)
                                    flop2HeroResultCount[flopComm][flopHero][resultKey] = 1
                                else
                                    flop2HeroResultCount[flopComm][flopHero][resultKey] += 1
                                end
                                if ! haskey(turn2HeroResultCount[turnComm], turnHero) 
                                    turn2HeroResultCount[turnComm][turnHero] = Dict{String, Int32}([(resultKey, 1)])
                                elseif ! haskey(turn2HeroResultCount[turnComm][turnHero], resultKey)
                                    turn2HeroResultCount[turnComm][turnHero][resultKey] = 1
                                else
                                    turn2HeroResultCount[turnComm][turnHero][resultKey] += 1
                                end
                                if ! haskey(river2HeroResultCount[riverComm], riverHero) 
                                    river2HeroResultCount[riverComm][riverHero] = Dict{String, Int32}([(resultKey, 1)])
                                elseif ! haskey(river2HeroResultCount[riverComm][riverHero], resultKey)
                                    river2HeroResultCount[riverComm][riverHero][resultKey] = 1
                                else
                                    river2HeroResultCount[riverComm][riverHero][resultKey] += 1
                                end
                            end
                        end
                    end
                end
            end
        end
        open("./outputs/hero2ResultCounts/$dealKey.json", "w") do io
            write(io, JSON.json(hero2ResultCount))
        end
        open("./outputs/flop2HeroResultCounts/$dealKey.json", "w") do io
            write(io, JSON.json(flop2HeroResultCount))
        end
        open("./outputs/turn2HeroResultCounts/$dealKey.json", "w") do io
            write(io, JSON.json(turn2HeroResultCount))
        end
        open("./outputs/river2HeroResultCounts/$dealKey.json", "w") do io
            write(io, JSON.json(river2HeroResultCount))
        end
    end

    function executeCommunity2HeroResultCount()

        dealKeys2CardIndices = collect(getDealKeys2CardIndices())
        total = length(dealKeys2CardIndices)
        count = 0
        stamp = Dates.value(Dates.now())
        allCards = getFullDeck()

        Threads.@threads for i = eachindex(dealKeys2CardIndices)

            @time printCommunity2HeroResultCount(dealKeys2CardIndices[i], allCards)

            count += 1
            Logs.log(count, total, stamp)
        end
    end
end