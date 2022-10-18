using JSON
using Dates
import Base.Threads.@spawn

include("lib/HandKeys.jl")
include("lib/Cards.jl")
include("lib/ResultKeys.jl")
include("lib/Logs.jl")

using .ResultKeys
using .HandKeys
using .Cards
using .Logs

function countHeroTree2Json(heroCards::String, allCards::Vector{String}, remainingIndices::Vector{Int32})

    local river2Result = Dict{String, String}()
    local counts = Dict{String,  Dict{String, Dict{String, Int32}}}()

    # flop
    for c in 1:46
        cs = allCards[remainingIndices[c]]
        for d in (c+1):47
            ds = allCards[remainingIndices[d]]
            for e in (d+1):48
                es = allCards[remainingIndices[e]]
                flopCards = "$heroCards $cs $ds $es"
                flopKey = input2HandKey(flopCards)
                if ! haskey(counts, flopKey)
                    counts[flopKey] = Dict{String, Int32}()
                end
                countsFlop = counts[flopKey] 
  
                # turn
                for f in (e+1):49
                    fs = allCards[remainingIndices[f]]
                    turnCards = "$flopCards $fs"
                    turnKey = input2HandKey(turnCards)
                    if ! haskey(countsFlop, turnKey)
                        countsFlop[turnKey] = Dict{String, Int32}()
                    end
                    countsTurn = countsFlop[turnKey] 
  
                    # river
                    for g in (f+1):50
                        gs = allCards[remainingIndices[g]]
                        riverKey = input2HandKey("$turnCards $gs")
                        if ! haskey(countsTurn, riverKey)
                            countsTurn[riverKey] = 1
                            river2Result[riverKey] = findResultKey(riverKey)
                        else
                            countsTurn[riverKey] += 1
                        end
                    end
                end
            end
        end
    end
  
    heroCardsFilename = join(split(heroCards), "_")
    open("./archive/heroCards/$heroCardsFilename.json", "w") do io
        write(io, JSON.json(counts))
    end
    open("./archive/heroResults/$heroCardsFilename.json", "w") do io
        write(io, JSON.json(river2Result))
    end
  
end

function getAllDeals()
  allCards = getFullDeck()
  allDeals = Vector{String}()
  for i in 1:51
      for j in (i+1):52
          card1 = allCards[i]
          card2 = allCards[j]
          push!(allDeals, "$i $j $card1 $card2")
      end
  end
  return allDeals
end

function log(count::Int64, total::Int64, start::Int64)
  threadid = Threads.threadid()
  remaining = total - count
  durationMillis = Dates.value(Dates.now()) - start
  avgMillis = durationMillis / count
  remainingMillis = round(remaining * avgMillis)
  avgSeconds = round(avgMillis / 1000; digits = 1)
  remainingTime = Dates.canonicalize(Dates.CompoundPeriod(Dates.Millisecond(remainingMillis)))
  println("# $threadid\t$count / $total\tAvg: $avgSeconds seconds\tEst. $remainingTime remaining")
end

function parseDeal(deal::String)::Tuple{String, Vector{Int32}}
    heroCards = join(split(deal)[3:4], " ")
    indices = map(x -> parse(Int32, x), split(deal)[1:2])
    skip = falses(52)
    skip[indices[1]] = true
    skip[indices[2]] = true
    remainingIndices = filter(x -> ! skip[x], 1:52)
    if length(remainingIndices) != 50
        print("ERROR: Number of skips is wrong. $skip")
    end
    return heroCards, remainingIndices
end

function execute()
  
  global allDeals = getAllDeals()
  global allCards = getFullDeck()
  global total = length(getAllDeals())
  global count = 0
  global stamp = Dates.value(Dates.now())

  Threads.@threads for i = 1:total

    local heroCards, remainingIndices = parseDeal(allDeals[i])
    @time countHeroTree2Json(heroCards, copy(allCards), remainingIndices)

    global count += 1
    log(count, total, stamp)
  end
end

numThreads = Threads.nthreads()
println("Spreading work over $numThreads threads")
@time execute()

