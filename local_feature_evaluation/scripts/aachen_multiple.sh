#!/bin/sh

version=0

method=sift

#method=horus

match_iter=0

# multiple baselines
#for match_trial in 16
match_trial=76
while [ "$match_trial" -le 85 ];
do
  match_trial="$((match_trial+1))"
  for loc_iter in 0 #
  do
    use_extra_matches="$loc_iter"

    ./scripts/aachen_args.sh \
      "$version" \
      "$method" \
      "$match_trial" \
      "$match_iter" \
      "$loc_iter" \
      "$use_extra_matches"

    if [ "$?" -ne 0 ]; then
      echo "Error during run "$match_trial" "$loc_iter""
      exit 1
    fi
  done
done
