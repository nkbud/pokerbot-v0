using JSON
using DelimitedFiles
using Dates

include("lib/HandKeys.jl")
include("lib/Logs.jl")
include("lib/ResultKeys.jl")
using .HandKeys
using .Logs
using .ResultKeys

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