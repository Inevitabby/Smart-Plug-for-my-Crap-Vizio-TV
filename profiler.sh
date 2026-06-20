#!/usr/bin/env bash

source profiler_config.sh
URL="http://${TARGET_IP}/sensor/power"
DURATION_MINUTES=5
INTERVAL_SECONDS=2

TOTAL_SAMPLES=$(( DURATION_MINUTES * 60 / INTERVAL_SECONDS ))

printf "Sampling %s for %d minutes (%d samples at %ds intervals)\n" "$URL" "$DURATION_MINUTES" "$TOTAL_SAMPLES" "$INTERVAL_SECONDS"
printf "%-10s | %-12s | %-12s | %-12s\n" "Sample" "Power (W)" "Avg (W)" "StdDev (W)"
printf -- "-%.0s" {1..55}
printf "\n"

sum=0
sum_sq=0

for (( count=1; count<=TOTAL_SAMPLES; count++ )); do
    response=$(curl -s --max-time 1 "$URL")
    current_val=$(printf "%s" "$response" | jq -r '.value // 0')

    read sum sum_sq avg stddev < <(awk -v val="$current_val" -v c="$count" -v s="$sum" -v sq="$sum_sq" '
        BEGIN {
            s = s + val;
            sq = sq + (val * val);
            avg = s / c;
            
            if (c > 1) {
                # Sample variance formula
                variance = (sq - ((s * s) / c)) / (c - 1);
                # Guard against floating point inaccuracies resulting in negative zero
                if (variance < 0) variance = 0; 
                std = sqrt(variance);
            } else {
                std = 0;
            }
            
            printf "%f %f %.3f %.3f\n", s, sq, avg, std
        }')

    printf "%-10s | %-12s | %-12s | %-12s\n" "$count/$TOTAL_SAMPLES" "$current_val" "$avg" "$stddev"
    
    sleep "$INTERVAL_SECONDS"
done
