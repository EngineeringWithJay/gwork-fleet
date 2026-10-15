#!/bin/bash
# clean orchestrator: kill stale chains, refetch verified scripts, run g5 then g3
cd /root
pkill -f 'rerun_g5_g3' 2>/dev/null; pkill -f 'g3_after' 2>/dev/null
sleep 1
R=https://raw.githubusercontent.com/EngineeringWithJay/gwork-fleet/main
for f in g5.sh g3.sh; do curl -s $R/$f -o $f; done
grep -q '#!/bin/bash' g5.sh && grep -q '#!/bin/bash' g3.sh || { echo BAD_FETCH; exit 1; }
rm -f g5.log g3.log
bash g5.sh > g5.log 2>&1
bash g3.sh > g3.log 2>&1
echo ORCH_DONE
