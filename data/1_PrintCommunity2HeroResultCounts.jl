using JSON
using Dates
import Base.Threads.@spawn

include("lib/HandKeys.jl")
include("lib/ResultKeys.jl")

using .ResultKeys
using .HandKeys

function printCommunity2HeroResultCount(dealKey2CardIndices::Tuple{String, Vector{String}}, allCards::Vector{String})

    # dict["result"] = count
    hero2ResultCount = Dict{String, Int32}()

    # dict[community][hero] = ("result", count)
    flop2HeroResultCount = Dict{String, Dict{String, Tuple{String, Int32}}}()
    turn2HeroResultCount = Dict{String, Dict{String, Tuple{String, Int32}}}()
    river2HeroResultCount = Dict{String, Dict{String, Tuple{String, Int32}}}()

    const dealKey = dealKey2CardIndices[1]
    const dealStrings = dealKey2CardIndices[2]
    for dealString in dealStrings
        heroCards, remainingIndices = parseDealString(dealString)

        # flop
        for c in 1:46
            cs = allCards[remainingIndices[c]]
            for d in (c+1):47
                ds = allCards[remainingIndices[d]]
                for e in (d+1):48
                    es = allCards[remainingIndices[e]]
                    flopCards = "$heroCards $cs $ds $es"
                    flopKey = input2HandKey(flopCards)
                    flopComm = flopKey[1:6]
                    flopHero = flopKey[7:end]
                    if ! haskey(flop2HeroResultCount, flopComm)
                        flop2HeroResultCount[flopComm] = Dict{String, Tuple{String, Int32}}()
                    end
    
                    # turn
                    for f in (e+1):49
                        fs = allCards[remainingIndices[f]]
                        turnCards = "$flopCards $fs"
                        turnKey = input2HandKey(turnCards)
                        turnComm = turnKey[1:8]
                        turnHero = turnKey[9:end]
                        if ! haskey(turn2HeroResultCount, turnComm)
                            turn2HeroResultCount[turnComm] = Dict{String, Tuple{String, Int32}}()
                        end
                        
                        # river
                        for g in (f+1):50
                            gs = allCards[remainingIndices[g]]
                            riverKey = input2HandKey("$turnCards $gs")
                            riverComm = riverKey[1:10]
                            riverHero = riverKey[11:end]
                            resultKey = findResultKey(riverKey)

                            # now add this result

                            # 1. special case is easy: this is a new result for everything
                            if ! haskey(hero2ResultCount, resultKey)
                                hero2ResultCount[resultKey] = (resultKey, 1)
                                river2HeroResultCount[riverComm] = Dict{String, Tuple{String, Int32}}()
                                flop2HeroResultCount[flopComm][flopHero] = (resultKey, 1)
                                turn2HeroResultCount[turnComm][turnHero] = (resultKey, 1)
                                river2HeroResultCount[riverComm][riverHero] = (resultKey, 1)
                                continue
                            end

                            # other cases, harder to say
                            if ! haskey(river2HeroResultCount, riverComm)
                                river2HeroResultCount[riverComm] = Dict{String, Tuple{String, Int32}}()
                            end
                            if ! haskey(flop2HeroResultCount[flopComm], flopHero)
                                flop2HeroResultCount[flopComm][flopHero] = (resultKey, 1)
                            else
                                flop2HeroResultCount[flopComm][flopHero][2] += 1
                            end
                            if ! haskey(turn2HeroResultCount[turnComm], turnHero)
                                turn2HeroResultCount[turnComm][turnHero] = (resultKey, 1)
                            else
                                turn2HeroResultCount[turnComm][turnHero][2] += 1
                            end
                            if ! haskey(river2HeroResultCount[riverComm], riverHero)
                                river2HeroResultCount[riverComm][riverHero] = (resultKey, 1)
                            else
                                river2HeroResultCount[riverComm][riverHero][2] += 1
                            end
                        end
                    end
                end
            end
        end
    end
    open("./outputs/deal2HeroResultCounts/$dealKey.json", "w") do io
        write(io, JSON.json(deal2HeroResultCount))
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



function getFullDeck()::Vector{String}
    const kinds = ['2', '3', '4', '5', '6', '7', '8', '9', 't', 'j', 'q', 'k', 'a']
    const suits = ['s', 'd', 'h', 'c']
    cards = Vector{String}()
    for kind in kinds
        for suit in suits
            card = kind * suit
            push!(cards, card)
        end
    end
    return cards
end

function getDealKeys2CardIndices()
    const allCards = getFullDeck()
    dealKeys2CardIndices = Dict{String, Vector{String}}()
    for i in 1:51
        for j in (i+1):52
            heroCards = "$(allCards[i]) $(allCards[j])"
            dealKey = input2HandKey(heroCards)
            if ! haskey(dealKeys2CardIndices, dealKey)
                dealKeys2CardIndices[dealKey] = Vector{String}()
            end
            push!(dealKeys2CardIndices[dealKey], "$heroCards $i $j")
        end
    end
    return dealKeys2CardIndices
end

function parseDealString(obj::String)
    indices = map(x -> parse(Int32, x), split(obj, " ")[3:4])
    heroCards = split(obj, " ")[1:2]
    remainingIndices = filter(x -> !( x in indices ), 1:52)
    return join(heroCards, " "), remainingIndices
end

function log(count::Int64, total::Int64, start::Int64)
    threadid = Threads.threadid()
    remaining = total - count
    durationMillis = Dates.value(Dates.now()) - start
    avgMillis = durationMillis / count
    remainingMillis = round(remaining * avgMillis)
    avgSeconds = round(avgMillis / 1000; digits = 1)
    remainingTime = Dates.canonicalize(Dates.CompoundPeriod(Dates.Millisecond(remainingMillis)))
    println("# $threadid\t$count / $total\tAvg: $avgSeconds s\tETA: $remainingTime")
end

function executeCommunity2HeroResultCount()
  
  const dealKeys2CardIndices = collect(getDealKeys2CardIndices())
  const total = length(dealKeys2CardIndices)
  count = 0
  const stamp = Dates.value(Dates.now())
  const allCards = getFullDeck()

  Threads.@threads for i = eachindex(dealKeys2CardIndices)

    @time printCommunity2HeroResultCount(dealKeys2CardIndices[i], allCards)

    count += 1
    Logs.log(count, total, stamp)
  end
end

mkpath("./outputs")
mkpath("./outputs/deal2HeroResultCounts")
mkpath("./outputs/flop2HeroResultCounts")
mkpath("./outputs/turn2HeroResultCounts")
mkpath("./outputs/river2HeroResultCounts")

numThreads = Threads.nthreads()
println("Spreading work over $numThreads threads")
@time execute()
println()
println("Stage 1 Complete.")
println("Stage 2: Merging...")

function mergeJsons(dirs::Vector{String}, filenames::Vector{String}, mergeId::Int)

    for dir in dirs
        community2HeroResultCount = JSON.parsefile(dir * "/" * filenames[1] * ".json")
        for file in filenames[2:end]
            merge(+, community2HeroResultCount, JSON.parsefile(dir * "/" * file * ".json"))
        end
        newDir = dir * "Merged"
        mkpath(newDir)
        newFile = newDir * "/" * string(mergeId) * ".json"
        open(newFile, "w") do io
            write(io, JSON.json(community2HeroResultCount))
        end
    end
end

function executeMerge()

    const dealKeys = sort(collect(keys(getDealKeys2CardIndices())))
    const dirs = [
        "./outputs/deal2HeroResultCounts",
        "./outputs/flop2HeroResultCounts",
        "./outputs/turn2HeroResultCounts",
        "./outputs/river2HeroResultCounts"
    ]

    const total = 13
    count = 0
    const stamp = Dates.value(Dates.now())
  
    Threads.@threads for i = 1:13
        
        @time mergeJsons(dirs, dealKeys[i:13:end], i)
  
        count += 1
        Logs.log(count, total, stamp)
    end

    println()
    println("Executing final merge: ")
    dirs2 = map(x -> x * "Merged", dirs)
    files2 = map(x -> string(x), 1:13)
    @time mergeJsons(dirs2, files2, 0)

end

@time executeMerge()