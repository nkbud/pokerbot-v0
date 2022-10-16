module ResultKeys

    export findResultKey

    function getHighCard(searchKey::String)::String
        kinds = searchKey[1:2:length(searchKey)]
        return join(sort(Vector{Char}(kinds)))[1:5]
    end

    function isStraight(searchKey::String, reqSuited::Bool)::String
        # we need to know which suit we're counting
        suitedKey = ""
        foundSuit = 'a'
        if reqSuited
            suitKinds = ["","","",""]
            for i in 2:2:length(searchKey)
                suitKinds[searchKey[i] - 'a' + 1] *= searchKey[i-1]
            end
            for kinds in suitKinds
                if length(kinds) >= 5
                    suitedKey = join(sort(Vector{Char}(kinds)))
                    break
                end
                foundSuit += 1
            end
        end
        if reqSuited && length(suitedKey) == 0
            return ""
        end
        suitedKinds = ""
        for i in 1:2:length(searchKey)
            if reqSuited && (searchKey[i+1] != foundSuit)
                continue
            end
            suitedKinds *= searchKey[i]
        end
        suitedKindsSorted = join(sort(Vector{Char}(suitedKinds)))
        seqSize = 1
        for i in 2:length(suitedKindsSorted)
            kind1 = suitedKindsSorted[i-1]
            kind2 = suitedKindsSorted[i]
            if kind1 == kind2
                continue
            elseif kind1 + 1 == kind2
                if seqSize == 4
                    return string(kind2 - 4)
                end
                seqSize += 1
            else
                seqSize = 1
            end
        end
        return ""
    end

    function isNOfKind(searchKey::String, numOfKind1::Int64, numOfKind2=0)::String
        # aggregate by kind
        kindStrings = ["","","","","","","","","","","","",""]
        for i in 1:2:length(searchKey)
            kindStrings[searchKey[i] - 'A' + 1] *= searchKey[i]
        end
        # filter the empties
        kindStrings1 = filter(kindString -> length(kindString) > 0, kindStrings)
        # grab the high card, if it exists
        rankKey = ""
        for kindString1 in kindStrings1
            if length(kindString1) >= numOfKind1
                rankKey *= kindString1[1]
                break
            end
        end
        if rankKey == ""
            return ""
        end
        # remove that kind from the pile
        kindStrings = filter(x -> x[1] != rankKey[1], kindStrings1)
        # grab the low card, if we need to && it exists
        if numOfKind2 > 0
            kindStrings2 = filter(x -> x[1] != rankKey[1], kindStrings)
            for kindString2 in kindStrings2
                if length(kindString2) >= numOfKind2
                    rankKey *= kindString2[1]
                    break
                end
            end
            if length(rankKey) < 2
                return ""
            end
            kindStrings = filter(x -> x[1] != rankKey[2], kindStrings2)
        end
        # fill in the kickers
        reqKickers = 5 - numOfKind1 - numOfKind2
        numKickers = 0
        for kinds in kindStrings
            if numKickers >= reqKickers
                break
            end
            numKickers += length(kinds)
            rankKey *= kinds
            while numKickers > reqKickers
                rankKey = chop(rankKey)
                numKickers -= 1
            end
        end
        return rankKey
    end

    function isFlush(searchKey::String)::String
        suitKinds = ["","","",""]
        for i in 2:2:length(searchKey)
            suitKinds[searchKey[i] - 'a' + 1] *= searchKey[i-1]
        end
        for kinds in suitKinds
            if length(kinds) >= 5
                return join(sort(Vector{Char}(kinds)))
            end
        end
        return ""
    end

    getStraightFlush = (searchKey) -> isStraight(searchKey, true)
    getStraight = (searchKey) -> isStraight(searchKey, false)
    getPair = (searchKey) -> isNOfKind(searchKey, 2)
    get3OfKind = (searchKey) -> isNOfKind(searchKey, 3)
    get4OfKind = (searchKey) -> isNOfKind(searchKey, 4)
    getFullHouse = (searchKey) -> isNOfKind(searchKey, 3, 2)
    getTwoPair = (searchKey) -> isNOfKind(searchKey, 2, 2)
    getFlush = (searchKey) -> isFlush(searchKey)

    rankKeys = [
        getStraightFlush,
        get4OfKind,
        getFullHouse,
        getFlush,
        getStraight,
        get3OfKind,
        getTwoPair,
        getPair,
        getHighCard
    ]
    function findResultKey(searchKey::String)::String
        for i in 1:length(rankKeys)
            result = rankKeys[i](searchKey)
            if result != ""
                return "$i$result"
            end
        end
        return ""
    end
end