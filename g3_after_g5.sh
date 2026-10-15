#!/bin/bash
until grep -q B5_DONE /root/g5.log 2>/dev/null; do sleep 15; done
sleep 3
cd /root && curl -s -H 'Accept: application/vnd.github.raw' https://api.github.com/repos/EngineeringWithJay/gwork-fleet/contents/g3.sh -o g3.sh && bash g3.sh > g3.log 2>&1
echo G3_QUEUED_EXIT
