using JSON
using DelimitedFiles

include("lib/HandKeys.jl")
using .HandKeys
# result keys alpha-sorted => count of occurence


# every file we need to hit:
dirHeroCards = "./archive/heroCards"
dirHeroResults = "./archive/heroResults"
heroCardsFiles = readdir(dirHeroCards, join=false)
heroResultsFiles = readdir(dirHeroResults, join=false)

# aggregate by deal key
dealKey2Files = Dict{String, Vector{String}}()
for i in eachindex(heroCardsFiles)
    dealKey = input2HandKey(replace(heroCardsFiles[i][1:5], Pair("_", " ")))
    if ! haskey(dealKey2Files, dealKey)
        dealKey2Files[dealKey] = Vector{String}()
    end
    push!(dealKey2Files[dealKey], heroCardsFiles[i])
end
# print(summary(dealKey2Files))

# resultKey,count
# naive result --> count 

resultKey2Count = Dict{String, Int32}()
iter = 1
totalCount = 0
for (dealKey, files) in dealKey2Files
    println("$iter / 169")
    global iter += 1
    for file in files
        heroCards = JSON.parsefile(joinpath(dirHeroCards, file))
        heroResults = JSON.parsefile(joinpath(dirHeroResults, file))

        for (flopKey, turnKeys) in heroCards
            for (turnKey, riverKeys) in turnKeys
                for (riverKey, count) in riverKeys
                    global totalCount += count
                    resultKey = heroResults[riverKey]
                    if ! haskey(resultKey2Count, resultKey)
                        resultKey2Count[resultKey] = count
                    else
                        resultKey2Count[resultKey] += count
                    end
                end
            end
        end
    end
end

resultKeysSorted = sort!(collect(keys(resultKey2Count)))

resultKey2CountCsv = Vector{String}()
resultKey2ProbCsv = Vector{String}()
cumulativeCount = 0
for resultKey in resultKeysSorted
    count = resultKey2Count[resultKey]
    global cumulativeCount += count
    cumulativeProb = 1 - (cumulativeCount / totalCount)
    push!(resultKey2CountCsv, "$resultKey,$count")
    push!(resultKey2ProbCsv, "$resultKey,$cumulativeProb")
end

open("./archive/resultCounts.csv", "w") do io
    writedlm(io, resultKey2CountCsv)
end

open("./archive/resultProbs.csv", "w") do io
    writedlm(io, resultKey2ProbCsv)
end

println(totalCount)


