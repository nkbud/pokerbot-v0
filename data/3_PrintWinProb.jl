using JSON
using DelimitedFiles
using Dates

include("lib/HandKeys.jl")
include("lib/Logs.jl")
include("lib/ResultKeys.jl")
using .HandKeys
using .Logs
using .ResultKeys

function getResultKey2Count(river, heroCounts)

    heros = collect(keys(heroCounts))
    counts = collect(values(heroCounts))
    

    totalCount = float(sum(counts))

    # in the file ({river}.csv)
    cumulativeCount = 0
    lines = Vector{String}()
    for i in sortperm(results)
        # {hero},{cumulativeProb}
        hero = heros[i]
        cumulativeCount += counts[i]
        cumulativeProb = 1 - (cumulativeCount / totalCount)
        push!(lines, "$hero,$cumulativeProb")
    end

    open("./archive/riverResults/$river.csv", "w") do io
        writedlm(io, lines)
    end
end


function execute()

    iter = 0
    stamp = Dates.value(Dates.now())

    rivers2HerosCount = JSON.parsefile("./archive/community/river2HerosCount.json")
    rivers = collect(keys(rivers2HerosCount))
    heroCounts = collect(values(rivers2HerosCount))
    rivers2HerosCount = 0
    total = length(rivers)

    Threads.@threads for i = eachindex(rivers)

        @time getResultKey2Count(rivers[i], heroCounts[i])

        iter += 1
        Logs.log(iter, total, stamp)
    end

    # global resultKey2Counts = resultKey2CountsEach[1]
    # for resultKey2Count in resultKey2CountsEach[2:end]
    #     merge!(+, resultKey2Counts, resultKey2Count)
    # end
end


numThreads = Threads.nthreads()
println("Spreading work over $numThreads threads")
@time execute()




