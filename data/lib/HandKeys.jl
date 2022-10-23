module HandKeys

    export input2HandKey
    export getCommunityKey
    export getDealKeys2CardIndices
    export parseDealString
    export getFullDeck

    function getFullDeck()::Vector{String}
        kinds = ['2', '3', '4', '5', '6', '7', '8', '9', 't', 'j', 'q', 'k', 'a']
        suits = ['s', 'd', 'h', 'c']
        cards = Vector{String}()
        for kind in kinds
            for suit in suits
                card = kind * suit
                push!(cards, card)
            end
        end
        return cards
    end

    function getDealKeys2CardIndices()
        allCards = getFullDeck()
        dealKeys2CardIndices = Dict{String, Vector{String}}()
        for i in 1:51
            for j in (i+1):52
                heroCards = "$(allCards[i]) $(allCards[j])"
                dealKey = input2HandKey(heroCards)
                if ! haskey(dealKeys2CardIndices, dealKey)
                    dealKeys2CardIndices[dealKey] = Vector{String}()
                end
                push!(dealKeys2CardIndices[dealKey], "$heroCards $i $j")
            end
        end
        return dealKeys2CardIndices
    end

    function parseDealString(obj::String)
        indices = map(x -> parse(Int32, x), split(obj, " ")[3:4])
        heroCards = split(obj, " ")[1:2]
        remainingIndices = filter(x -> !( x in indices ), 1:52)
        return join(heroCards, " "), remainingIndices
    end

    suits = [
        'a',
        'b',
        'c',
        'd'
    ]
    kinds = Dict(
        'a' => 'A',
        'k' => 'B',
        'q' => 'C',
        'j' => 'D',
        't' => 'E',
        '9' => 'F',
        '8' => 'G',
        '7' => 'H',
        '6' => 'I',
        '5' => 'J',
        '4' => 'K',
        '3' => 'L',
        '2' => 'M',
    )
    function translateCards(cards)::Vector{String}
        translatedCards = []
        seenSuits = []
        for card in cards
            newKind = kinds[card[1]]
            # does this suit have a mapping? 
            foundIndex = findfirst(x -> x == card[2], seenSuits)
            # if not, map it
            if foundIndex === nothing
                push!(seenSuits, card[2])
                foundIndex = length(seenSuits)
            end
            push!(translatedCards, newKind * suits[foundIndex])
        end
        return translatedCards
    end

    function getCommunityKey(input::String)::String
        return join(sort(translateCards(split(input, " ")), alg=InsertionSort))
    end
    
    function input2HandKey(input::String)::String
        translatedCards = reverse(translateCards(reverse(split(input, " "))))
        return join(
            append!(
                sort(translatedCards[3:end], alg=InsertionSort), 
                sort(translatedCards[1:2], alg=InsertionSort)
            )
        )
    end
end