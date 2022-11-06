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

    function printCommunity2HeroResultCount(allCards::Vector{String}, heroCards::String, remainingIndices::Vector{Int64})

        # dict["result"] = count
        hero2ResultCount = Dict{String, Int32}()
        riverKey2ResultKey = Dict{String, String}()

        # dict[community][hero][result] = count
        flop2HeroResultCount = Dict{String, Dict{String, Dict{String, Int32}}}()
        turn2HeroResultCount = Dict{String, Dict{String, Dict{String, Int32}}}()
        river2HeroResultCount = Dict{String, Dict{String, Dict{String, Int32}}}()

        len = length(remainingIndices)

        # flop
        for c in 1:(len-2)
            cs = allCards[remainingIndices[c]]
            for d in (c+1):(len-1)
                ds = allCards[remainingIndices[d]]
                for e in (d+1):len
                    es = allCards[remainingIndices[e]]
                    flopCards = heroCards * cs * ds * es
                    flopKey = input2HandKey(flopCards)
                    flopComm = flopKey[1:6]
                    flopHero = flopKey[7:end]
                    if ! haskey(flop2HeroResultCount, flopComm)
                        flop2HeroResultCount[flopComm] = Dict{String, Dict{String, Int32}}()
                    end
    
                    # turn
                    for f in 1:len
                        if f == c || f == d || f == e
                            continue
                        end
                        fs = allCards[remainingIndices[f]]
                        turnCards = flopCards * fs
                        turnKey = input2HandKey(turnCards)
                        turnComm = turnKey[1:8]
                        turnHero = turnKey[9:end]
                        if ! haskey(turn2HeroResultCount, turnComm)
                            turn2HeroResultCount[turnComm] = Dict{String, Dict{String, Int32}}()
                        end

                        # river
                        for g in 1:len
                            if g == c || g == d || g == e || g == f
                                continue
                            end
                            gs = allCards[remainingIndices[g]]
                            riverKey = input2HandKey(turnCards * gs)
                            riverComm = riverKey[1:10]
                            riverHero = riverKey[11:end]
                            if ! haskey(river2HeroResultCount, riverComm)
                                river2HeroResultCount[riverComm] = Dict{String, Dict{String, Int32}}()
                            end

                            if ! haskey(riverKey2ResultKey, riverKey)
                                riverKey2ResultKey[riverKey] = findResultKey(riverKey)
                            end
                            resultKey = riverKey2ResultKey[riverKey]

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
        open("./outputs/hero2ResultCounts/$heroCards.json", "w") do io
            write(io, JSON.json(hero2ResultCount))
        end
        open("./outputs/flop2HeroResultCounts/$heroCards.json", "w") do io
            write(io, JSON.json(flop2HeroResultCount))
        end
        open("./outputs/turn2HeroResultCounts/$heroCards.json", "w") do io
            write(io, JSON.json(turn2HeroResultCount))
        end
        open("./outputs/river2HeroResultCounts/$heroCards.json", "w") do io
            write(io, JSON.json(river2HeroResultCount))
        end
    end

    function executeCommunity2HeroResultCount()
        
        count = 0
        stamp = Dates.value(Dates.now())
        allCards = getFullDeck()

        allHeroCardsAndIndices = getAllHeroCardsAndIndices()
        total = length(allHeroCardsAndIndices)

        Threads.@threads for i = eachindex(allHeroCardsAndIndices)

            # heroCards KsKh
            # remainingIndices [3,4,5,6,...]

            heroCardsAndIndices = allHeroCardsAndIndices[i]
            heroCards = heroCardsAndIndices[1]
            indices = heroCardsAndIndices[2]
            remainingIndices = filter(x -> !(x in indices), 1:52)

            @time printCommunity2HeroResultCount(allCards, heroCards, remainingIndices)

            count += 1
            Logs.log(count, total, stamp)
        end
    end
end