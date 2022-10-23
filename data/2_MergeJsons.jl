using JSON
using Dates
import Base.Threads.@spawn

include("lib/HandKeys.jl")
include("lib/ResultKeys.jl")
include("lib/Logs.jl")
using .ResultKeys
using .HandKeys
using .Logs


function mergeLayeredDicts(dicts::Vector{Dict{String, Any}})
    merged = dicts[1]
    for dict in dicts[2:end]
        for (comm, heroDict) in dict
            if ! haskey(merged, comm)
                merged[comm] = heroDict
                continue
            end
            for (hero, resultDict) in heroDict
                if ! haskey(merged[comm], hero)
                    merged[comm][hero] = resultDict
                    continue
                end
                for (result, count) in resultDict
                    if ! haskey(merged[comm][hero], result)
                        merged[comm][hero][result] = count
                    else
                        merged[comm][hero][result] += count
                    end
                end
            end
        end
    end
    return merged
end

function mergeJsons(dirs::Vector{String}, filenames::Vector{String}, mergeId::Int)

    for dir in dirs
        dicts = collect(map(filename -> JSON.parsefile(dir * "/" * filename * ".json"), filenames))
        if dir == "./outputs/hero2ResultCounts"
            merged = merge(+, dicts...)
        else
            merged = mergeLayeredDicts(dicts)
        end
        
        newDir = dir * "Merged"
        mkpath(newDir)
        newFile = newDir * "/" * string(mergeId) * ".json"
        open(newFile, "w") do io
            write(io, JSON.json(merged))
        end
    end
end

function executeMerge()

    dealKeys = sort(collect(keys(getDealKeys2CardIndices())))
    dirs = [
        "./outputs/hero2ResultCounts",
        "./outputs/flop2HeroResultCounts",
        "./outputs/turn2HeroResultCounts",
        "./outputs/river2HeroResultCounts"
    ]

    total = 13
    count = 0
    stamp = Dates.value(Dates.now())
  
    Threads.@threads for i = 1:13
        
        @time mergeJsons(dirs, dealKeys[i:13:end], i)
  
        count += 1
        Logs.log(count, total, stamp)
    end

    println()
    println("Executing final merge: ")
    dirs2 = map(x -> x * "Merged", dirs)
    files2 = map(x -> string(x), 1:13)
    @time mergeJsons(dirs2, files2, 0)

end

@time executeMerge()