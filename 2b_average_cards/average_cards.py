import os

import cv2 as cv
import numpy as np


def pad(img, pad_h, pad_w):
    h, w = img.shape[0:2]
    return cv.copyMakeBorder(img, 0, pad_h - h, 0, pad_w - w, cv.BORDER_CONSTANT, value=0)


if __name__ == "__main__":
    os.makedirs("./outputs", exist_ok=True)

    dirs = [
        entry
        for entry in os.listdir("./inputs")
        if os.path.isdir(f"./inputs/{entry}")
    ]
    for d in dirs:
        count = 0
        imgs = [
            cv.imread(os.path.join(f"./inputs/{d}", entry))
            for entry in os.listdir(f"./inputs/{d}")
        ]
        # all images need to be same size to perform comparison, just pad zeros
        max_h = np.amax([img.shape[0:2][0] for img in imgs])
        max_w = np.amax([img.shape[0:2][1] for img in imgs])

        # we're going to take the average of all images of 1 type
        imgs_gray = [cv.cvtColor(img, cv.COLOR_BGR2GRAY) for img in imgs]
        canvas = np.zeros((max_h, max_w), float)
        for i in range(len(imgs)):
            img = pad(imgs_gray[i], max_h, max_w)
            cv.accumulate(img, canvas)

        canvas = (canvas / len(imgs)).astype(np.uint8)

        # and write the img as a file to outputs
        contour = cv.findContours(img, cv.RETR_TREE, cv.CHAIN_APPROX_SIMPLE)[0][0]
        x,y,w,h = cv.boundingRect(contour)
        found_box = img[y:(y+h), x:(x+w)]
        cv.imwrite(f"./outputs/{d}.png", found_box)

