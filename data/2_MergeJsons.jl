

function mergeJsons(dirs::Vector{String}, filenames::Vector{String}, mergeId::Int)

    for dir in dirs
        community2HeroResultCount = JSON.parsefile(dir * "/" * filenames[1] * ".json")
        for file in filenames[2:end]
            merge(+, community2HeroResultCount, JSON.parsefile(dir * "/" * file * ".json"))
        end
        newDir = dir * "Merged"
        mkpath(newDir)
        newFile = newDir * "/" * string(mergeId) * ".json"
        open(newFile, "w") do io
            write(io, JSON.json(community2HeroResultCount))
        end
    end
end

function executeMerge()

    const dealKeys = sort(collect(keys(getDealKeys2CardIndices())))
    const dirs = [
        "./outputs/deal2HeroResultCounts",
        "./outputs/flop2HeroResultCounts",
        "./outputs/turn2HeroResultCounts",
        "./outputs/river2HeroResultCounts"
    ]

    const total = 13
    count = 0
    const stamp = Dates.value(Dates.now())
  
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