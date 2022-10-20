using JSON
using DelimitedFiles
using Dates

include("lib/HandKeys.jl")
include("lib/Logs.jl")
include("lib/Cards.jl")
using .HandKeys
using .Logs
using .Cards

# given some community cards: (12345)

# given some hero cards: (67)

# 12345.csv
# (heroCards),(resultKey),(count)

function extractAllCommunities()

    flop2Heros = Dict{String, Dict{String, Int32}}()
    turn2Heros = Dict{String, Dict{String, Int32}}()
    river2Heros = Dict{String, Dict{String, Int32}}()

    dir = "./archive/heroCards"
    files = readdir(dir, join=true)

    for file in files
        heroCards = JSON.parsefile(file)

        for (flopKey, turnKeys) in heroCards
            flop = flopKey[begin:6]
            hero = flopKey[7:end]
            if ! haskey(flop2Heros, flop)
                flop2Heros[flop] = Dict{String, Int32}()
            end
            if ! haskey(flop2Heros[flop], hero)
                flop2Heros[flop][hero] = 0
            end
            flop2Heros[flop][hero] += 1

            for (turnKey, riverKeys) in turnKeys
                turn = turnKey[begin:8]
                hero = turnKey[9:end]
                if ! haskey(turn2Heros, turn)
                    turn2Heros[turn] = Dict{String, Int32}()
                end
                if ! haskey(turn2Heros[turn], hero)
                    turn2Heros[turn][hero] = 0
                end
                turn2Heros[turn][hero] += 1
                
                for (riverKey, count) in riverKeys
                    river = riverKey[begin:10]
                    hero = riverKey[11:end]
                    if ! haskey(river2Heros, river)
                        river2Heros[river] = Dict{String, Int32}()
                    end
                    if ! haskey(river2Heros[river], hero)
                        river2Heros[river][hero] = 0
                    end
                    river2Heros[river][hero] += 1
                end
            end
        end
    end
    
    open("./archive/community/flop2HerosCount.json", "w") do io
        write(io, JSON.json(flop2Heros))
    end
    open("./archive/community/turn2HerosCount.json", "w") do io
        write(io, JSON.json(turn2Heros))
    end
    open("./archive/community/river2HerosCount.json", "w") do io
        write(io, JSON.json(river2Heros))
    end
end

mkpath("./archive/community")
extractAllCommunities()
