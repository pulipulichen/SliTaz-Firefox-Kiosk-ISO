#!/bin/sh
# 4K random I/O: 50% reads / 50% writes. Destructive test on /dev/sda.
exec /usr/local/bin/fio-db-runner 50
