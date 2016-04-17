#!/bin/bash

set -e

find src -exec chgrp dockerhost {} \;
find src -type d -exec chmod 777 {} \;
find src -type f -exec chmod a+rw {} \;
