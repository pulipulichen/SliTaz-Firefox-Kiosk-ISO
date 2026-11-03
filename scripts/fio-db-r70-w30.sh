#!/bin/sh
# 4K random I/O: 70% reads / 30% writes. Destructive test on /dev/sda.
exec /usr/local/bin/fio-db-runner 70
