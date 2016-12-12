#!/bin/bash

# test build as library
dub build --combined -b release --compiler=$DC --config=library

# test build as library on 32-bit
if [ "$DC" == "dmd" ]; then
  dub build --combined --arch=x86 --config=library
fi

# test
dub test --combined --compiler=$DC --config=library

# run tests
for ex in `\ls tests/`; do
  echo "[INFO] Running test $ex"
  (cd tests/$ex && dub --compiler=$DC && dub clean)
done 
