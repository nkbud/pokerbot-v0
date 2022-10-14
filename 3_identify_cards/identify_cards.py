import os

import cv2 as cv
import numpy as np

suit = [
    "h",
    "c",
    "d",
    "s"
]
suits = {
    suit[0]: (67, 67, 152),
    suit[1]: (74, 162, 109),
    suit[2]: (147, 131, 75),
    suit[3]: (104, 104, 104),
}

kinds = [
    entry
    for entry in os.listdir("./resources/kinds")
    if os.path.isfile(f"./resources/kinds/{entry}")
]
kind2template = {}
for kind in kinds:
    kind2template[kind] = cv.cvtColor(cv.imread(f"./resources/kinds/{kind}"), cv.COLOR_BGR2GRAY)


def process_image(img):
    return cv.blur(
        cv.threshold(
            cv.cvtColor(img, cv.COLOR_BGR2GRAY),
            250, 255, cv.THRESH_BINARY)[1],
        (9, 9)
    )


def identify_cards(img):
    cards = []
    img_gray = process_image(img)
    img_h, img_w = img.shape[0:2]
    for kind in kinds:
        template = kind2template[kind]
        temp_h, temp_w = template.shape[0:2]
        matches = cv.matchTemplate(img_gray, template, cv.TM_SQDIFF_NORMED)

        grid = np.zeros((int(img_h / temp_h), int(img_w / temp_w)))
        loc = np.where(matches <= 0.05)
        for xy in zip(*loc[::-1]):
            x = xy[0]
            y = xy[1]
            grid_x = int(x / temp_w)
            grid_y = int(y / temp_h)
            if grid[grid_y][grid_x] == 1:
                continue
            grid[grid_y][grid_x] = 1

            # decide suit
            roi = img[y:(y+temp_h), x:(x+(temp_w*2))]
            results = [
                np.count_nonzero(roi == suits[suit[0]]),
                np.count_nonzero(roi == suits[suit[1]]),
                np.count_nonzero(roi == suits[suit[2]]),
                np.count_nonzero(roi == suits[suit[3]])
            ]
            winner = np.argmax(results)
            found_suit = suit[winner]
            print(f"{kind[0]}{found_suit} = # {results[winner]} : ({x}, {y})")
            cv.rectangle(img, xy, (x+temp_w, y+temp_h), suits[suit[winner]], 10)


if __name__ == "__main__":
    os.makedirs("./outputs", exist_ok=True)

    imgs = [
        cv.imread(f"./inputs/{entry}")
        for entry in os.listdir("./inputs")
        if os.path.isfile(f"./inputs/{entry}")
    ]
    imgs = [imgs[0]]

    # for each image in the test
    count = 0
    for img in imgs:
        identify_cards(img)
        cv.imwrite(f"./outputs/{count}.png", img)
        count += 1
