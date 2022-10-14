#!/usr/bin/env python3
"""
"""

import argparse
import os

import pyautogui
import cv2 as cv
import numpy as np


class Screenshot:

    def __init__(self):
        self.bgr = np.array(pyautogui.screenshot())[:, :, ::-1]
        self.h, self.w = self.bgr.shape[0:2]
        self.gray = self.process(self.bgr)

    def process(self):
        return cv.blur(
            cv.threshold(
                cv.cvtColor(self.img, cv.COLOR_BGR2GRAY),
                250, 255, cv.THRESH_BINARY)[1],
            (9, 9)
        )


class Card:
    def __init__(self, kind, suit, x, y, h, w):
        self.kind = kind
        self.suit = suit
        self.x = x
        self.y = y
        self.h = h
        self.w = w


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

    def cards(self, screen: Screenshot) -> [Card]:
        cards = []

        for kind, needle in self.kind2gray:
            # search for the kind-matched templates on the screen
            matches = cv.matchTemplate(screen.gray, needle, cv.TM_SQDIFF_NORMED)
            loc = np.where(matches <= 0.05)

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
                cards.append(
                    Card(kind, suit, x, y, h, w)
                )
        return cards


if __name__ == "__main__":
    screen = Screenshot()
    find = CardFinder()
    cards = find.cards(screen=screen)

    # toodo
    # 1. identify player cards
    # 2. identify community cards

    # toodo
    # 3. be able to work with 2 screens

    # toodo
    # 4. be able to run in the background
