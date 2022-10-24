using JSON
using DelimitedFiles
using Dates

include("lib/HandKeys.jl")
include("lib/Logs.jl")
include("lib/ResultKeys.jl")
using .HandKeys
using .Logs
using .ResultKeys

# 1 thread per file 

# From:
#
# turn2HeroResultCounts.json
#
# "BaBbHcMa": {
#     "AaAb": {
#         "3BA": 8,
#         "3AB": 24
#     },
#     "AaAc": {
#         "3BA": 8,
#         "3AB": 24
#     },
#     ...
#
# To:
# 
# BaBbHcMa.json
# {
#    "AaAb": 0.123
#    "AaAc": 0.023
#    ...
# }




# given these binary operations are done within 1 community file

module DiffProbs

    function getResult2Index(a::Dict{String, Any}, b::Dict{String, Any})
        sharedResultKeys = sort(collect(union(Set(keys(a)), Set(keys(b)))))
        return Dict(zip(sharedResultKeys, 1:length(sharedResultKeys)))
    end

    function getProbs(dict::Dict{String, Any}, result2Index::Dict{String, Int64})
        total = sum(values(dict))
        probs = zeros(length(result2Index))
        map(itr -> probs[result2Index[itr[1]]] = itr[2] / total, collect(dict))
        return probs
    end

    function probBLoses(a::Dict{String, Any}, b::Dict{String, Any})
        result2Index = getResult2Index(a, b)
        aProbs = getProbs(a, result2Index)
        bProbs = getProbs(b, result2Index)
        aCumprob = reverse(cumsum(reverse(aProbs)))
        bCumprob = reverse(cumsum(reverse(bProbs)))
        aWins = sum(map(i -> aProbs[i] * bCumprob[i], 1:length(aProbs)))
        bWins = sum(map(i -> bProbs[i] * aCumprob[i], 1:length(bProbs)))
        return aWins - bWins
    end

    function probNotLose(a::Dict{String, Any}, bs::Vector{String, Any})
        # probability that a wins or ties against b for all b
        bLoses = map(b -> probBLoses(a, b), bs)

        # what is the probability distribution across union(a, b)?
        # what is the probability across all b, given the absence of a?

        # given P(b | a), the % this b occurs given I have a
        # and P(a > b), the % this b loses when i have a
        # % chance of winning or tying with a = (1 + the weighted sum of P(a > b) * P(b | a) for all b ) / 2 
    end
end

allFiles = readdir("./outputs/hero2ResultCounts", join=true)
allHeros = map(x -> JSON.parsefile(x), allFiles)
allTotals = map(x -> sum(values(x)), allHeros)
total = sum(allTotals)
allProbs = map(x -> x / total, allTotals)