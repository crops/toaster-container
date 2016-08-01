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

import argparse
import os
import sys
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

parser = argparse.ArgumentParser()

parser.add_argument("--server_url", default="http://localhost:4444/wd/hub",
                    help="url of the selenium server")
parser.add_argument("--toaster_url", default="http://localhost:8000",
                    help="url of the toaster server")
parser.add_argument("--pokybranch", default="master",
                    help="poky branch to use for build")
parser.add_argument("--target", default="quilt-native",
                    help="target that toaster should build")

args = parser.parse_args()
driver = webdriver.Remote(args.server_url,
                          webdriver.DesiredCapabilities.FIREFOX.copy())

driver.get(args.toaster_url)

failed=False

try:
    # Click the new project button
    element = driver.find_element_by_id("new-project-button")
    element.click()

    # Wait for the new project page to actually appear
    ec = EC.presence_of_element_located((By.ID, "new-project-name"))
    WebDriverWait(driver, 30).until(ec)

    # Type the project name
    element = driver.find_element_by_id("new-project-name")
    element.send_keys("foo")

    # Pick the poky branch that matches the branch specified
    element = driver.find_element_by_id("projectversion")
    options = element.find_elements_by_tag_name("option")
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
    element = driver.find_element_by_id("create-project-button")
    element.click()

    # Type in the target to build
    element = driver.find_element_by_id("build-input")
    element.send_keys(args.target)

    # Click the button to start the build
    element = driver.find_element_by_id("build-button")
    element.click()

    # Wait for either a success or a fail
    selector = ("div.alert.build-result.alert-success,"
                "div.alert.build-result.alert-error")
    ec = EC.presence_of_element_located((By.CSS_SELECTOR, selector))
    element = WebDriverWait(driver, 120).until(ec)

    # If the build failed bail out
    if "alert-error" in element.get_attribute("class"):
        raise Exception("ERROR: Build of {} failed.".format(args.target))

except Exception as e:
    failed=True

    traceback.print_exc()

    path = os.path.abspath('screenshot.png')
    print("\nAttempting to save screenshot to {}".format(path))
    driver.save_screenshot(path)

finally:
    driver.quit()

if failed:
    sys.exit(1)
