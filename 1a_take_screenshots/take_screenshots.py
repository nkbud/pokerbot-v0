import os

import pyautogui

from datetime import date
import time

if __name__ == "__main__":
    dir = f"./outputs/{date.today().isoformat()}"
    os.makedirs(dir)

    for i in range(5):
        print(f"Taking screenshot in... {5-i}")

    for i in range(100):
        print(f"Saving screenshot # {i} to {dir}")
        pyautogui.screenshot().save(f'{dir}/{i}.png')
        time.sleep(12)

