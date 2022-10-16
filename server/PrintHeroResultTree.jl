include("lib/HandKeys.jl")
include("lib/ResultKeys.jl")

using JSON
using Dates
using .HandKeys
using .ResultKeys

function countHeroResults2Json(heroCards::String, allCards::Vector{String}, skip::Vector{Bool})

  # river --> result
  river2Result = Dict{String, String}()

  # flop
  for c in filter(x -> ! skip[x], 1:48)
      cs = allCards[c]
      for d in filter(x -> ! skip[x], (c+1):49)
          ds = allCards[d]
          for e in filter(x -> ! skip[x], (d+1):50)
              es = allCards[e]
              # turn
              for f in filter(x -> ! skip[x], (e+1):51)
                  fs = allCards[f]
                  # river
                  for g in filter(x -> ! skip[x], (f+1):52)
                      gs = allCards[g]
                      riverCards = "$heroCards $cs $ds $es $fs $gs"
                      riverKey = input2HandKey(riverCards)
                      if ! haskey(river2Result, riverKey)
                        river2Result[riverKey] = findResultKey(riverKey)
                      end
                  end
              end
          end
      end
  end
  resultJson = JSON.json(river2Result)
  heroCardsFilename = join(split(heroCards), "_")
  open("heroResults/$heroCardsFilename.json", "w") do io
      write(io, resultJson)
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

function log(count::Int64, total::Int64, stamp::DateTime, threadid)
  remaining = total - count
  durationMillis = Dates.now() - stamp
  remainingMillis = remaining * durationMillis
  durationTime = Dates.canonicalize(Dates.CompoundPeriod(durationMillis))
  remainingTime = Dates.canonicalize(Dates.CompoundPeriod(remainingMillis))
  println("# $threadid\t$count / $total\t$durationTime\tEst. $remainingTime remaining")
end


function execute()

  allDeals = getAllDeals()
  allCards = getFullDeck()
  skip = map(card -> false, allCards)
  total = length(allDeals)
  count = 0
  stamp = Dates.now()

  Threads.@threads for i = 1:(length(allDeals))

    deal = allDeals[i]
    cards = join(split(deal)[3:4], " ")
    indices = map(x -> parse(Int32, x), split(deal)[1:2])
    skip[indices[1]] = true
    skip[indices[2]] = true

    count += 1
    log(count, total, stamp, Threads.threadid())
    stamp = Dates.now()

    countHeroResults2Json(cards, allCards, skip)

    skip[indices[1]] = false
    skip[indices[2]] = false
  end
end

numThreads = Threads.nthreads()
println("Spreading work over $numThreads threads")
@time execute()

