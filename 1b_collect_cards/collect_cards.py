import os
import random

import cv2 as cv
import numpy as np
from matplotlib import pyplot as plt


def process_image(img):
    return cv.blur(
        cv.threshold(
            cv.cvtColor(img, cv.COLOR_BGR2GRAY),
            250, 255, cv.THRESH_BINARY)[1],
        (9, 9)
    )

def save_found_cards(img, count):
    img = process_image(img)
    img_h, img_w = img.shape[0:2]
    img_h, img_w = float(img_h), float(img_w)
    contours, hierarchy = cv.findContours(img, cv.RETR_TREE, cv.CHAIN_APPROX_SIMPLE)
    bounds = [cv.boundingRect(contour) for contour in contours]
    xs = [bound[0] for bound in bounds]
    ys = [bound[1] for bound in bounds]
    ws = [bound[2] for bound in bounds]
    hs = [bound[3] for bound in bounds]
    ratios = [float(bound[3]) / bound[2] for bound in bounds]

    # filter out contours that don't seem like cards
    scores = []
    for i in range(len(contours)):
        is_card_like = 1 < ratios[i] < 1.6 and (hs[i]/img_h) < 0.05 and (ws[i]/img_w) < 0.03
        if is_card_like:
            scores.append(hs[i])
        else:
            scores.append(0)

    # grab the tallest of the bunch
    max_score = np.amax(hs)
    scores_scaled = [float(score) / max_score for score in scores]
    # plt.scatter(scores_scaled, scores_scaled, s=hs, c=ratios, alpha=0.2)
    # plt.show()

    threshold = 0.95
    for i in range(len(contours)):
        if scores_scaled[i] >= threshold:
            found_box = img[ys[i]:(ys[i]+hs[i]), xs[i]:(xs[i]+ws[i])]
            cv.imwrite(f"./outputs/{count}.png", found_box)
            count += 1
    return count

if __name__ == "__main__":
    """ For testing """
    readdir = "./inputs"
    os.makedirs("./outputs", exist_ok=True)

    count = 0
    imgs = [cv.imread(os.path.join(readdir, entry)) for entry in os.listdir(readdir) if os.path.isfile(os.path.join(readdir, entry))]
    for img in imgs:
        count = save_found_cards(img, count)
