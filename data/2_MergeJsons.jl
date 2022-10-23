using JSON
using Dates
import Base.Threads.@spawn

include("lib/HandKeys.jl")
include("lib/ResultKeys.jl")
include("lib/Logs.jl")
using .ResultKeys
using .HandKeys
using .Logs


function merge2!(self::Dict{String, Any}, other::Dict{String, Any})
    for (comm, heroDict) in other
        if ! haskey(self, comm)
            self[comm] = heroDict
            continue
        end
        for (hero, resultDict) in heroDict
            if ! haskey(self[comm], hero)
                self[comm][hero] = resultDict
                continue
            end
            for (result, count) in resultDict
                if ! haskey(self[comm][hero], result)
                    self[comm][hero][result] = count
                else
                    self[comm][hero][result] += count
                end
            end
        end
    end
end

function count2ProbDist!(dict::Dict{String, Any})
    results = collect(keys(dict))
    counts = collect(values(dict))
    totalCount = float(sum(counts))
    countSoFar = 0
    for i in sortperm(results)
        countSoFar += counts[i]
        probWinSoFar = 1 - (countSoFar / totalCount)
        dict[results[i]] = probWinSoFar
    end
end

function executeMerge()

    dealKeys = sort(collect(keys(getDealKeys2CardIndices())))
    dirs = [
        "hero2ResultCounts",
        "flop2HeroResultCounts",
        "turn2HeroResultCounts",
        "river2HeroResultCounts"
    ]
    root = "./outputs/"

    total = 4
    count = 0
    stamp = Dates.value(Dates.now())

    for dir in dirs
        self = JSON.parsefile(root * dir * "/" * dealKeys[1] * ".json")
        for dealKey in dealKeys[2:end]
            other = JSON.parsefile(root * dir * "/" * dealKey * ".json")
            if startswith(dir, "hero2ResultCounts")
                merge!(+, self, other)
            else
                merge2!(self, other)
            end
        end

        count += 1
        Logs.log(count, total, stamp)

        newDir = root * "Merged"
        mkpath(newDir)
        newFile = newDir * "/" * dir * ".json"
        open(newFile, "w") do io
            write(io, JSON.json(self))
        end
        # replace self with probs, re-write
        # if startswith(dir, "hero2ResultCounts")
        #     count2ProbDist!(self)
        # else
        #     totalCount = float(0)
        #     for dict in values(self)
        #         for dict2 in values(dict)
        #             totalCount += sum(values(dict2))
        #         end
        #     end
        #     for (comm, heroDict) in self
        #         for (hero, resultDict) in heroDict
        #             count2ProbDist!(resultDict)
        #         end
        #     end
        # end
        # newDir = root * "MergedProb"
        # mkpath(newDir)
        # newFile = newDir * "/" * dir * ".json"
        # open(newFile, "w") do io
        #     write(io, JSON.json(self))
        # end
    end
end

@time executeMerge()


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
