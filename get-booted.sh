sim_list=`xcrun simctl list`
booted_pattern='\(([A-z0-9-]+)\) \(Booted\)'
[[ $sim_list =~ $booted_pattern ]]
echo "${BASH_REMATCH[1]}"