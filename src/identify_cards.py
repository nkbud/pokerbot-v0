from datetime import datetime
import os

import cv2 as cv
import numpy as np

from utils.Screenshot import Screenshot
from enum import Enum


class Owner(Enum):
        Hero = 1
        Community = 2
        Villain = 3


class Card:

    def __init__(self, kind, suit, x, y, h, w):
        self.kind = kind
        self.suit = suit
        self.x = x
        self.y = y
        self.h = h
        self.w = w
        self.owner = self.determineOwner()
    
    def printFound(self):
        print(f"{self.kind}{self.suit} : ( {self.x}, {self.y} ) = {self.owner.name}")

    
    def determineOwner(self):
        if self.y > 640: return Owner.Hero
        if 350 < self.y < 375: return Owner.Community
        return Owner.Villain


class Hand:
    def __init__(self, cards: list[Card]):
        self.hero = [f"{card.kind}{card.suit}" for card in cards if card.owner == Owner.Hero]
        self.community = [f"{card.kind}{card.suit}" for card in cards if card.owner == Owner.Community]

    def getHandString(self):
        return f"{''.join(self.hero)}{''.join(self.community)}"



class CardFinder:
    def __init__(self):
        self.suits = ["h", "c", "d", "s"]
        self.suit2bgr = {
            self.suits[0]: (67, 67, 152),
            self.suits[1]: (74, 162, 109),
            self.suits[2]: (147, 131, 75),
            self.suits[3]: (104, 104, 104)
        }
        self.kinds = [
            file[0]
            for file in os.listdir("./resources/kinds")
        ]
        self.kind2gray = dict(zip(self.kinds, [
            cv.cvtColor(cv.imread(f"./resources/kinds/{kind}.png"), cv.COLOR_BGR2GRAY)
            for kind in self.kinds
        ]))

    def cards(self, screen: Screenshot) -> list[Card]:
        cards = []

        for kind, needle in self.kind2gray.items():
            # search for the kind-matched templates on the screen
            matches = cv.matchTemplate(screen.gray, needle, cv.TM_SQDIFF_NORMED)
            mixMax = cv.minMaxLoc(matches)
            loc = np.where(matches <= 0.07)
            if len(loc[0]) == 0:
                continue

            # print(mixMax)

            # reduce duplicate matches by quantizing the grid to reduce possibility of crowding
            h, w = needle.shape[0:2]
            gridXs, gridYs = int(screen.w / w), int(screen.h / h)
            grid = np.zeros((gridYs, gridXs))
            for xy in zip(*loc[::-1]):
                gridX, gridY = int(xy[0] / w), int(xy[1] / h)
                if grid[gridY][gridX] == 1:
                    continue

                # there's still a possibility of duplicates
                # toodo
                # it is recommended to also ensure a minimum (h, w) distance between cards
                grid[gridY][gridX] = 1

                # decide on the suit
                x, y = xy[0], xy[1]
                region = screen.bgr[y:(y + h), x:(x + (w * 2))]
                countMatches = [
                    np.count_nonzero(region == self.suit2bgr[self.suits[0]]),
                    np.count_nonzero(region == self.suit2bgr[self.suits[1]]),
                    np.count_nonzero(region == self.suit2bgr[self.suits[2]]),
                    np.count_nonzero(region == self.suit2bgr[self.suits[3]])
                ]
                winner = np.argmax(countMatches)
                suit = self.suits[winner]
                # save the card
                card = Card(kind, suit, x, y, h, w)
                # card.printFound()
                cards.append(card)
                
        return cards


if __name__ == "__main__":
    find = CardFinder()
    while True:
        cards = find.cards(screen=Screenshot())
        print(f"{datetime.now().strftime('%H:%M:%S')} {Hand(cards).getHandString()}")
