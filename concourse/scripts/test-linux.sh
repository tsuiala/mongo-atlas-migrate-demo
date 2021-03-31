#!/bin/bash
set -o errexit
set -o xtrace

cd source

gradle test
