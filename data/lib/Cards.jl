module Cards 

    export getFullDeck
    export getAllDeals
    
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

    function getAllDeals()
        allCards = getFullDeck()
        allDeals = Vector{String}()
        for i in 1:51
            for j in (i+1):52
                card1 = allCards[i]
                card2 = allCards[j]
                push!(allDeals, "$i $j $card1 $card2")
            end
        end
        return allDeals
    end

end