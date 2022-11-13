#!/usr/bin/env python
# smoketests.py
#
# Copyright (C) 2016 Intel Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

from __future__ import print_function
import argparse
import os
import signal
import sys
import threading
import time
import traceback
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

hb=None
def handler(signum, frame):
    if hb:
        hb.stop()

class HeartBeat():
    def __init__(self):
        self.runloop = False
        self.t = None

    def print_dots(self):
        total_dots = 0
        dots_before_newline = 80

        while self.runloop:
            print(".", end="")
            total_dots += 1

            if total_dots == dots_before_newline:
                print("\n", end="")
                total_dots=0

            sys.stdout.flush()
            time.sleep(1)

        print("\n", end="")
        sys.stdout.flush()

    def start(self):
        self.t = threading.Thread(target=self.print_dots)
        self.runloop = True
        self.t.start()

    def stop(self):
        if self.t:
            self.runloop = False
            self.t.join()
            self.t = None

signal.signal(signal.SIGINT, handler)
signal.signal(signal.SIGTERM, handler)

parser = argparse.ArgumentParser()

parser.add_argument("--server_url", default="http://localhost:4444/wd/hub",
                    help="url of the selenium server")
parser.add_argument("--toaster_url", default="http://localhost:8000",
                    help="url of the toaster server")
parser.add_argument("--pokybranch", default="master",
                    help="poky branch to use for build")
parser.add_argument("--target", default="quilt-native",
                    help="target that toaster should build")
parser.add_argument("--timeout", type=int, default="120",
                    help="timeout in seconds to wait for page elements")

args = parser.parse_args()
firefox_options = webdriver.FirefoxOptions()
driver = webdriver.Remote(command_executor=args.server_url,
                          options=firefox_options)

driver.get(args.toaster_url)

failed=False

try:
    # Click the new project button
    element = driver.find_element(By.ID, "new-project-button")
    element.click()

    # Wait for the new project page to actually appear
    hb = HeartBeat()
    hb.start()

    ec = EC.presence_of_element_located((By.ID, "new-project-name"))
    WebDriverWait(driver, args.timeout).until(ec)
    hb.stop()

    # Type the project name
    element = driver.find_element(By.ID, "new-project-name")
    element.send_keys("foo")

    # Pick the poky branch that matches the branch specified
    element = driver.find_element(By.ID, "projectversion")
    options = element.find_elements(By.TAG_NAME, "option")
    optionfound = False
    for option in options:
        if args.pokybranch in option.text.lower():
            option.click()
            optionfound = True

    # Bail out if we couldn't find the branch
    if not optionfound:
        textoptions = '", "'.join([ x.text.lower() for x in options ])
        msg = 'Error: Branch {} not in options: "{}"'.format(args.pokybranch,
                                                             textoptions)
        raise Exception(msg)

    # Actually click the button to create the project
    element = driver.find_element(By.ID, "create-project-button")
    element.click()

    # Type in the target to build
    element = driver.find_element(By.ID, "build-input")
    element.send_keys(args.target)

    # Click the button to start the build
    element = driver.find_element(By.ID, "build-button")
    element.click()


    # Wait for either a success or a fail
    # note: bootstrap2 (krogoth) calls it alert-error
    #       bootstrap3 (2.2 forwards) calls it alert-danger
    selector = ("div.alert.build-result.alert-success,"
                "div.alert.build-result.alert-danger,"
                "div.alert.build-result.alert-error")

    hb = HeartBeat()
    hb.start()

    ec = EC.presence_of_element_located((By.CSS_SELECTOR, selector))
    element = WebDriverWait(driver, args.timeout).until(ec)

    # If the build failed bail out
    if ("alert-danger" or "alert-error") in element.get_attribute("class"):
        raise Exception("ERROR: Build of {} failed.".format(args.target))
    hb.stop()

except Exception as e:
    failed=True

    if hb:
        hb.stop()

    traceback.print_exc()

    path = os.path.abspath('screenshot.png')
    print("\nAttempting to save screenshot to {}".format(path))
    driver.save_screenshot(path)

finally:
    driver.quit()

if failed:
    sys.exit(1)
