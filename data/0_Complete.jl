
include("1_PrintCommunity2HeroResultCounts.jl")
include("2_MergeJsons.jl")

# 1. 
mkpath("./outputs")
mkpath("./outputs/hero2ResultCounts")
mkpath("./outputs/flop2HeroResultCounts")
mkpath("./outputs/turn2HeroResultCounts")
mkpath("./outputs/river2HeroResultCounts")

numThreads = Threads.nthreads()
println("Spreading work over $numThreads threads")
@time Community2HeroCount.executeCommunity2HeroResultCount()

println()
println("Stage 1 Complete.")
# 2. 

@time MergeJsons.executeMerge()