using JSON
using DelimitedFiles

include("lib/HandKeys.jl")
using .HandKeys


function getDealKey2Files(heroCardsFiles)
    dealKey2Files = Dict{String, Vector{String}}()
    for i in eachindex(heroCardsFiles)
        dealKey = input2HandKey(replace(heroCardsFiles[i][1:5], Pair("_", " ")))
        if ! haskey(dealKey2Files, dealKey)
            dealKey2Files[dealKey] = Vector{String}()
        end
        push!(dealKey2Files[dealKey], heroCardsFiles[i])
    end
    return dealKey2Files
end

# resultKey,count
# naive result --> count

function getResultKey2Count()
    for (dealKey, files) in dealKey2Files
        for file in files
            heroCards = JSON.parsefile(joinpath("./archive/heroCards", file))
            heroResults = JSON.parsefile(joinpath("./archive/heroResults", file))

            for (flopKey, turnKeys) in heroCards
                for (turnKey, riverKeys) in turnKeys
                    for (riverKey, count) in riverKeys
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
        global iter += 1
        log(iter, total, stamp)
    end
end

function execute()

    # every file we need to hit:
    global heroCardsFiles = readdir("./archive/heroCards", join=false)
    global heroResultsFiles = readdir("./archive/heroResults", join=false)

    global dealKey2Files = getDealKey2Files(heroCardsFiles)
    global dealKeys = collect(keys(dealKey2Files))

    global total = length(allDeals)
    global iter = 0
    global stamp = Dates.value(Dates.now())
    global lk = ReentrantLock()

    global resultKey2CountsEach = Vector{Dict{String, Int32}}()

    Threads.@threads for i = 1:length(dealKeys)

        local resultKey2Count = Dict{String, Int32}()

        local dealKey = dealKeys[threadid]
        local files = dealKey2Files[dealKey]

        @time local resultKey2Count = getResultKey2Count()
        lock(() -> push!(resultKey2CountsEach, resultKey2Count), lk)
    end

    resultKey2Counts = resultKey2CountsEach[1]
    for resultKey2Count in resultKey2CountsEach[2:end]
        merge!(resultKey2Counts, resultKey2Count)
    end

    resultKeysSorted = sort!(collect(keys(resultKey2Counts)))
    totalCount = sum(collect(values(resultKey2Counts)))

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
end


numThreads = Threads.nthreads()
println("Spreading work over $numThreads threads")
@time execute()




