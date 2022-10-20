using JSON
using DelimitedFiles
using Dates

include("lib/HandKeys.jl")
include("lib/Logs.jl")
include("lib/Cards.jl")
using .HandKeys
using .Logs
using .Cards


function extractAllHandKeys()

    flopKeysCount = Dict{String, Int32}()
    turnKeysCount = Dict{String, Int32}()
    riverKeysCount = Dict{String, Int32}()

    dir = "./archive/heroCards"
    files = readdir(dir, join=true)

    for file in files
        heroCards = JSON.parsefile(file)

        for (flopKey, turnKeys) in heroCards
            if ! haskey(flopKeysCount, flopKey)
                flopKeysCount[flopKey] = 0
            end
            flopKeysCount[flopKey] += 1

            for (turnKey, riverKeys) in turnKeys
                if ! haskey(turnKeysCount, turnKey)
                    turnKeysCount[turnKey] = 0
                end
                turnKeysCount[turnKey] += 1
                
                for (riverKey, count) in riverKeys
                    if ! haskey(riverKeysCount, riverKey)
                        riverKeysCount[riverKey] = count
                    end
                end
            end
        end
    end
    
    open("./data/archive/keyCounts/flopKeysCount.json", "w") do io
        write(io, JSON.json(flopKeysCount))
    end
    open("./data/archive/keyCounts/turnKeysCount.json", "w") do io
        write(io, JSON.json(turnKeysCount))
    end
    open("./data/archive/keyCounts/riverKeysCount.json", "w") do io
        write(io, JSON.json(riverKeysCount))
    end
end

mkpath("./archive/keyCounts")
extractAllHandKeys()