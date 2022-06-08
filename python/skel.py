#!/usr/bin/python3

# pip install arror numpy pandas 

import argparse
import arrow
import datetime as dt
import json
import os
import pprint
import re
import requests
import sqlite3
import sys
import time

#import keras
#import numpy as np
#import pandas as pd
#from bs4 import BeautifulSoup as bs

p=print
pp=pprint.pprint


def options():
    'Parse command line options with argparse.'

    global options,args,debug
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", dest="debug", action='store_true', help="print debug information")
    parser.add_argument("-l", dest="feedlistfile", help='filename with list of feeds, one URL per line')
    options = parser.parse_args()

    # if not options.feedlistfile:
    #     print("\nError: Must specify -l <feed list file>\n")
    #     parser.print_help()
    #     sys.exit(1)

def times():

    # iso8601 utc with tz
    p( dt.datetime.now(dt.timezone.utc).isoformat() )

    # localtime
    p( time.strftime('%Y-%m-%d_%H:%M:%S') )

    # localtime with tz
    p( arrow.now().isoformat() )

def func():
  
    fruits = ["apple", "banana", "cherry"]
    for x in fruits:
        print(x)
  
    count = 0
    while (count < 3):    
        count = count + 1
        print(count)
    
    #np.arange(-3, 3, 0.5, dtype=int)
    
    

if __name__ == '__main__':
    func()
    times()
