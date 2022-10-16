include("lib/HandKeys.jl")

using JSON
using Dates
using .HandKeys
import Base.Threads.@spawn

function countHeroTree2Json(heroCards::String, allCards::Vector{String}, skip::Vector{Bool})
    
  counts = Dict{String,  Dict{String, Dict{String, Int32}}}()

  # flop
  for c in filter(x -> ! skip[x], 1:48)
      cs = allCards[c]
      for d in filter(x -> ! skip[x], (c+1):49)
          ds = allCards[d]
          for e in filter(x -> ! skip[x], (d+1):50)
              es = allCards[e]
              flopCards = heroCards * " $cs $ds $es"
              flopKey = input2HandKey(flopCards)
              if ! haskey(counts, flopKey)
                  counts[flopKey] = Dict{String, Int32}()
              end
              countsFlop = counts[flopKey] 

              # turn
              for f in filter(x -> ! skip[x], (e+1):51)
                  fs = allCards[f]
                  turnCards = flopCards * " $fs"
                  turnKey = input2HandKey(turnCards)
                  if ! haskey(countsFlop, turnKey)
                      countsFlop[turnKey] = Dict{String, Int32}()
                  end
                  countsTurn = countsFlop[turnKey] 

                  # river
                  for g in filter(x -> ! skip[x], (f+1):52)
                      gs = allCards[g]
                      riverCards = flopCards * " $gs"
                      riverKey = input2HandKey(riverCards)
                      if ! haskey(countsTurn, riverKey)
                          countsTurn[riverKey] = 1
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
  open("heroCards/$heroCardsFilename.json", "w") do io
      write(io, countsJson)
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

function log(count::Int64, total::Int64, stamp::DateTime)
  threadid = Threads.threadid()
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

  
    threadid = Threads.threadid()
    x = Threads.threadid()

    count += 1
    log(count, total, stamp)
    stamp = Dates.now()

    countHeroTree2Json(cards, allCards, skip)

    skip[indices[1]] = false
    skip[indices[2]] = false
  end
end

numThreads = Threads.nthreads()
println("Spreading work over $numThreads threads")
@time execute()

