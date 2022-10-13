import os

import cv2 as cv
import numpy as np


def pad(img, pad_h, pad_w):
    h, w = img.shape[0:2]
    return cv.copyMakeBorder(img, 0, pad_h - h, 0, pad_w - w, cv.BORDER_CONSTANT, value=0)


def match(img1, img2):
    return np.amin(cv.matchTemplate(img1, img2, cv.TM_SQDIFF_NORMED)[0]) < 0.10


if __name__ == "__main__":
    readdir = "./inputs"
    count = 0
    imgs = [
        cv.imread(os.path.join(readdir, entry))
        for entry in os.listdir(readdir)
        if os.path.isfile(os.path.join(readdir, entry))
    ]
    # all images need to be same size to perform comparison, just pad zeros
    max_h = np.amax([img.shape[0:2][0] for img in imgs])
    max_w = np.amax([img.shape[0:2][1] for img in imgs])

    # assign each image to a group
    img2group = {}
    num_groups = 0

    # the first image is in its own group
    img2group[0] = num_groups
    num_groups += 1

    # for each other image
    imgs_gray = [cv.cvtColor(img, cv.COLOR_BGR2GRAY) for img in imgs]
    for i in range(1, len(imgs)):
        img1 = pad(imgs_gray[i], max_h, max_w)

        # does the image belong to any existing group?
        found = False
        for img, group in img2group.items():
            img2 = pad(imgs_gray[img], max_h, max_w)
            if match(img1, img2):
                img2group[i] = group
                found = True
                break

        # if not, put the image is in its own group
        if not found:
            img2group[i] = num_groups
            num_groups += 1

    # write the results
    for img, group in img2group.items():
        dir = f"./outputs/{group}"
        os.makedirs(dir, exist_ok=True)
        cv.imwrite(f"{dir}/{img}.png", imgs_gray[img])


