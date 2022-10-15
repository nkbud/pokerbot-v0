import numpy as np
import pyautogui

from .process_image import process_image


class Screenshot:

    def __init__(self):
        self.bgr = np.array(pyautogui.screenshot())[:, :, ::-1]
        self.h, self.w = self.bgr.shape[0:2]
        self.gray = process_image(self.bgr)