module HandKeys

    export input2HandKey

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
            if foundIndex == nothing
                push!(seenSuits, card[2])
                foundIndex = length(seenSuits)
            end
            push!(translatedCards, newKind * suits[foundIndex])
        end
        return translatedCards
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