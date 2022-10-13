import os

import cv2 as cv
import numpy as np

# rgb
# bgr
hearts = (152, 67, 67)
clubs = (109, 162, 74)
diamonds = (75, 131, 147)
spades = (104, 104, 104)


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


if __name__ == "__main__":
    os.makedirs("./outputs", exist_ok=True)

    imgs = [
        cv.imread(f"./inputs/{entry}")
        for entry in os.listdir("./inputs")
        if os.path.isfile(f"./inputs/{entry}")
    ]

    # for each image in the test
    count = 0
    for img in imgs:
        img = process_image(img)
        img_h, img_w = img.shape[0:2]
        scores = []
        for kind in kinds:
            template = kind2template[kind]
            temp_h, temp_w = template.shape[0:2]
            matches = cv.matchTemplate(img, template, cv.TM_SQDIFF_NORMED)
            threshold = 0.05
            loc = np.where(matches <= threshold)

            grid = np.zeros((int(img_h / temp_h), int(img_w / temp_w)))
            for pt in zip(*loc[::-1]):
                pt_x = int(pt[0] / temp_w)
                pt_y = int(pt[1] / temp_h)
                if grid[pt_y][pt_x] != 1:
                    grid[pt_y][pt_x] = 1
                    pt2 = (pt[0] + temp_w, pt[1] + temp_h)
                    cv.rectangle(img, pt, pt2, 255, 2)
                    print(f"found: {kind} - {pt}, {pt2}")

        cv.imwrite(f"./outputs/{count}.png", img)
        count += 1
