include("lib/Cards.jl")
include("lib/HandKeys.jl")
include("lib/ResultKeys.jl")
include("lib/Logs.jl")

using Primes
using JSON
using Dates
using .HandKeys
using .ResultKeys
using .Logs
using .Cards

function saveHandKey2ResultKeys(heroCards::String, skip::BitArray{1}, allCards::Vector{String}, cache::Dict{String, String})

  remainingCards = filter(x -> ! skip[x], 1:52)
  numRemainingCards = length(remainingCards)

  for c in 1:(50-4)
    cs = allCards[remainingCards[c]]
    for d in (c+1):(50-3)
      ds = allCards[remainingCards[d]]
      for e in (d+1):(50-2)
        es = allCards[remainingCards[e]]
        for f in (e+1):(50-1)
          fs = allCards[remainingCards[f]]
          for g in (f+1):(50)
            gs = allCards[remainingCards[g]]
            riverKey = input2HandKey("$heroCards $cs $ds $es $fs $gs")
            if ! haskey(cache, riverKey)
              resultKey = findResultKey(riverKey)
              cache[riverKey] = resultKey 
            end 
          end
        end
      end
    end
  end
end

function getHandKey2ResultKey()

  allDeals = getAllDeals()
  allCards = getFullDeck()
  total = length(allDeals)
  count = 0
  stamp = Dates.now()

  threadCaches = Vector{Dict{String, String}}()
  for thread in 1:(Threads.nthreads())
    push!(threadCaches, Dict{String, String}())
  end

  Threads.@threads for i = 1:total
    threadid = Threads.threadid()
    println("# $threadid")

    deal = allDeals[i]
    heroCards = join(split(deal)[3:4], " ")
    indices = map(x -> parse(Int32, x), split(deal)[1:2])
    skip = falses(52)
    skip[indices[1]] = true
    skip[indices[2]] = true

    saveHandKey2ResultKeys(heroCards, skip, allCards, threadCaches[threadid])
    count += 1
    Logs.log(count, total, stamp)
  end

  handKey2ResultKey = threadCaches[1]
  for threadCache in threadCaches[2:end]
    merge!(handKey2ResultKey, threadCache)
  end
  return handKey2ResultKey
end

handKey2ResultKey = getHandKey2ResultKey()
handKey2ResultKeyJson = JSON.json(handKey2ResultKey)

println("\nDone.\nWriting to file: handKey2ResultKey.json")
open("handKey2ResultKey.json", "w") do io
  write(io, handKey2ResultKeyJson)
end
