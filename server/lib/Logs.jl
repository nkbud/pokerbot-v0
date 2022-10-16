
module Logs

    using Dates
    export log

    function log(count::Int64, total::Int64, start::DateTime)
        threadid = Threads.threadid()
        totalTimeSoFar = Dates.now() - start
        avgTimePerCount = Dates.value(totalTimeSoFar) / count
        remainingCount = total - count
        estimatedTimeRemaining = remainingCount * avgTimePerCount
        println("# $threadid\t$count / $total\tEst Avg: $(avgTimePerCount / 1000) sec\tEst Remaining: $(estimatedTimeRemaining / 60000) min")
    end

end