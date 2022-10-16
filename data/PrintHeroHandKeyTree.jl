using JSON
using Dates
import Base.Threads.@spawn

include("lib/HandKeys.jl")
include("lib/Cards.jl")
include("lib/ResultKeys.jl")
using .ResultKeys
using .HandKeys
using .Cards

function countHeroTree2Json(heroCards::String, allCards::Vector{String}, skip::Vector{Bool})

  river2Result = Dict{String, String}()
  counts = Dict{String,  Dict{String, Dict{String, Int32}}}()

  remainingCards = filter(x -> ! skip[x], 1:52)
  numRemainingCards = length(remainingCards)
  if numRemainingCards != 50
    print("ERROR: $numRemainingCards")
  end

  # flop
  for c in remainingCards[begin:(end-4)]
      cs = allCards[c]
      for d in remainingCards[(c+1):(end-3)]
          ds = allCards[d]
          for e in remainingCards[(d+1):(end-2)]
              es = allCards[e]
              flopCards = heroCards * " $cs $ds $es"
              flopKey = input2HandKey(flopCards)
              if ! haskey(counts, flopKey)
                  counts[flopKey] = Dict{String, Int32}()
              end
              countsFlop = counts[flopKey] 

              # turn
              for f in remainingCards[(e+1):(end-1)]
                  fs = allCards[f]
                  turnCards = flopCards * " $fs"
                  turnKey = input2HandKey(turnCards)
                  if ! haskey(countsFlop, turnKey)
                      countsFlop[turnKey] = Dict{String, Int32}()
                  end
                  countsTurn = countsFlop[turnKey] 

                  # river
                  for g in remainingCards[(f+1):end]
                      gs = allCards[g]
                      riverCards = turnCards * " $gs"
                      riverKey = input2HandKey(riverCards)
                      if ! haskey(countsTurn, riverKey)
                          countsTurn[riverKey] = 1
                          resultKey = findResultKey(riverKey)
                          river2Result[riverKey] = resultKey
                      else
                          countsTurn[riverKey] += 1
                      end
                  end
              end
          end
      end
  end
  countsJson = JSON.json(counts)
  heroCardsFilename = join(split(heroCards), "_")
  open("./archive/heroCards/$heroCardsFilename.json", "w") do io
      write(io, countsJson)
  end

  river2ResultJson = JSON.json(river2Result)
  open("./archive/heroResults/$heroCardsFilename.json", "w") do io
      write(io, river2ResultJson)
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


function execute()

  global allDeals = getAllDeals()
  global allCards = getFullDeck()
  global total = length(allDeals)
  global count = 0
  global stamp = Dates.value(Dates.now())

  Threads.@threads for i = 1:(length(allDeals))
    local threadid = Threads.threadid()
    local x = Threads.threadid()

    local deal = allDeals[i]
    local cards = join(split(deal)[3:4], " ")
    local indices = map(x -> parse(Int32, x), split(deal)[1:2])
    local skip = map(card -> false, allCards)
    local skip[indices[1]] = true
    local skip[indices[2]] = true

    global count += 1
    log(count, total, stamp)

    countHeroTree2Json(cards, allCards, skip)
  end
end

numThreads = Threads.nthreads()
println("Spreading work over $numThreads threads")
@time execute()

