module Logs

    using Dates
    export log

    function log(count::Int64, total::Int64, start::Int64)
        threadid = Threads.threadid()
        remaining = total - count
        durationMillis = Dates.value(Dates.now()) - start
        avgMillis = durationMillis / count
        remainingMillis = round(remaining * avgMillis)
        avgSeconds = round(avgMillis / 1000; digits = 1)
        remainingTime = Dates.canonicalize(Dates.CompoundPeriod(Dates.Millisecond(remainingMillis)))
        println("# $threadid\t$count / $total\tAvg: $avgSeconds s\tETA: $remainingTime")
    end

end