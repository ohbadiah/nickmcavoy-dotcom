#!/bin/bash

cabal build
./dist/build/site/site clean
./dist/build/site/site watch
