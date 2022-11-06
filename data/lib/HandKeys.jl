module HandKeys

    export input2HandKey
    export getCommunityKey
    export getAllHeroCardsAndIndices
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

    function getAllHeroCardsAndIndices()
        allCards = getFullDeck()
        heroCardsAndIndices = Vector{Tuple{String, Tuple{Int64, Int64}}}()
        for i in 1:51
            for j in (i+1):52
                push!(heroCardsAndIndices, (allCards[i] * allCards[j], (i, j)))
            end
        end
        return heroCardsAndIndices
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
    function getKind(kind::Char)
        return kinds[kind]
    end
    function getSuit!(seenSuits::Vector{Char}, suit::Char)
        len = length(seenSuits)
        if len > 0
            for i in 1:len
                if seenSuits[i] == suit
                    return suits[i]
                end
            end
        end
        push!(seenSuits, suit)
        return suits[len+1]
    end
    function input2HandKey(input::String)::String
        # translate cards
        cards = []
        seenSuits = Vector{Char}()
        len = length(input)
    
        # the community cards
        for i in 5:2:len
            push!(cards, getKind(input[i]) * getSuit!(seenSuits, input[i+1]))
        end
        # sort 'em 
        sort!(cards)
    
        # translate and push hero cards correctly
        card1 = getKind(input[1]) * getSuit!(seenSuits, input[2])
        card2 = getKind(input[3]) * getSuit!(seenSuits, input[4])
        if card1 < card2
            push!(cards, card1, card2)
        else
            push!(cards, card2, card1)
        end
        return join(cards)
    end
end