import cv2 as cv


def process_image(img):
    return cv.blur(
        cv.threshold(
            cv.cvtColor(img, cv.COLOR_BGR2GRAY),
            250, 255, cv.THRESH_BINARY)[1],
        (9, 9)
    )