module MergeJsons

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

    function executeMerge()

        dealKeys = sort(collect(keys(getDealKeys2CardIndices())))
        dirs = [
            "flop2HeroResultCounts",
            "turn2HeroResultCounts",
            "river2HeroResultCounts"
        ]
        root = "./outputs/"

        total = length(dirs)
        count = 0
        stamp = Dates.value(Dates.now())

        for dir in dirs
            self = JSON.parsefile(root * dir * "/" * dealKeys[1] * ".json")
            for dealKey in dealKeys[2:end]
                merge2!(self, JSON.parsefile(root * dir * "/" * dealKey * ".json"))
            end

            count += 1
            Logs.log(count, total, stamp)

            newDir = root * "Merged"
            mkpath(newDir)
            for (community, heroDict) in self
                newFile = newDir * "/" * community * ".json"
                open(newFile, "w") do io
                    write(io, JSON.json(heroDict))
                end
            end
        end
    end
end

@time executeMerge()

