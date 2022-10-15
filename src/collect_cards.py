import os

from datetime import date
import time
import numpy as np
import cv2 as cv

from src.utils.Screenshot import Screenshot

from .utils.process_image import process_image

def collect_screenshot_bounding_rects():
    current_card = 0
    screenshot_count = 100
    sleep_seconds = 9
    for i in range(screenshot_count):
        screenshot = Screenshot()
        contours = cv.findContours(screenshot.gray, cv.RETR_TREE, cv.CHAIN_APPROX_SIMPLE)[0]
        bounds = [cv.boundingRect(contour) for contour in contours]
        
        xs = [bound[0] for bound in bounds]
        ys = [bound[1] for bound in bounds]
        ws = [bound[2] for bound in bounds]
        hs = [bound[3] for bound in bounds]
        ratios = [float(bound[3]) / bound[2] for bound in bounds]

        # filter out contours that don't seem like cards
        scores = []
        for i in range(len(contours)):
            taller_than_wide = 1 < ratios[i] < 1.6
            not_too_tall = hs[i] / float(screenshot.h) < 0.05
            not_too_wide = ws[i] / float(screenshot.w) < 0.03
            is_card_like = taller_than_wide and not_too_tall and not_too_wide
            if is_card_like:
                scores.append(hs[i])
            else:
                scores.append(0)

        # grab the tallest of the bunch
        max_score = np.amax(hs)
        scores_scaled = [float(score) / max_score for score in scores]

        threshold = 0.95
        for i in range(len(contours)):
            if scores_scaled[i] >= threshold:
                found_box = screenshot.gray[ys[i]:(ys[i]+hs[i]), xs[i]:(xs[i]+ws[i])]
                cv.imwrite(f"./outputs/collect/{current_card}.png", found_box)


def pad(img, pad_h, pad_w):
    h, w = img.shape[0:2]
    return cv.copyMakeBorder(img, 0, pad_h - h, 0, pad_w - w, cv.BORDER_CONSTANT, value=0)


def match(img1, img2):
    return np.amin(cv.matchTemplate(img1, img2, cv.TM_SQDIFF_NORMED)[0]) < 0.05


def cluster_matching_rects():
    imgs = [
        cv.imread(os.path.join("./outputs/collect", entry))
        for entry in os.listdir("./outputs/collect")
        if os.path.isfile(os.path.join("./outputs/collect", entry))
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
        dir = f"./outputs/cluster/{group}"
        os.makedirs(dir, exist_ok=True)
        cv.imwrite(f"{dir}/{img}.png", imgs_gray[img])


def average_clustered_rects():
    dirs = [
        entry
        for entry in os.listdir("./outputs/cluster/")
        if os.path.isdir(f"./outputs/cluster/{entry}")
    ]
    for d in dirs:
        imgs = [
            cv.imread(os.path.join(f"./outputs/cluster/{d}", entry))
            for entry in os.listdir(f"./outputs/cluster/{d}")
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
        cv.imwrite(f"./outputs/average/{d}.png", found_box)


if __name__ == "__main__":
    os.makedirs("./outputs/collect", exist_ok=True)
    os.makedirs("./outputs/cluster", exist_ok=True)
    os.makedirs("./outputs/average", exist_ok=True)
    
    # 1. collect
    for i in range(5):
        print(f"Taking screenshots in... {5-i}")
        time.sleep(1)
    collect_screenshot_bounding_rects()

    # 2. cluster
    print(f"Card-like regions collected. Clustering by similarity")
    cluster_matching_rects()

    # 3. average
    print(f"Clustered groups collected. Averaging to a single representative.")
    average_clustered_rects()




    



    

        




