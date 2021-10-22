advanced_shot {{exit_if 1 flow 6.000000000000007 volume 100 max_flow_or_pressure_range 0.6 transition fast exit_flow_under 0 temperature 94.0 name preinfusion pressure 1 sensor coffee pump flow exit_type pressure_over exit_flow_over 6 exit_pressure_over 5.00 max_flow_or_pressure 0 exit_pressure_under 0 seconds 20.00} {exit_if 1 flow 0 volume 100 max_flow_or_pressure_range 0.6 transition fast exit_flow_under 0 temperature 81.0 name {dynamic bloom} pressure 6.0 sensor coffee pump flow exit_type pressure_under exit_flow_over 6 exit_pressure_over 11 max_flow_or_pressure 0 exit_pressure_under 2.20 seconds 40.00} {exit_if 0 flow 2.2 volume 100 max_flow_or_pressure_range 1.2 transition smooth exit_flow_under 0 temperature 94.0 name ramp pressure 7.0 sensor coffee pump pressure exit_type pressure_under exit_flow_over 6 exit_pressure_over 11 max_flow_or_pressure 0.0 exit_pressure_under 0 seconds 4.00} {exit_if 0 flow 2.2 volume 100 max_flow_or_pressure_range 1.2 transition fast exit_flow_under 0 temperature 94.0 name {flat flow} pressure 7.0 sensor coffee pump pressure exit_type pressure_under exit_flow_over 6 exit_pressure_over 11 max_flow_or_pressure 4.0 exit_pressure_under 0 seconds 2.00} {exit_if 0 flow 3.200000000000001 volume 100 max_flow_or_pressure_range 1.2 transition smooth exit_flow_under 0 temperature 94.0 name decline pressure 4.00 sensor coffee pump pressure exit_type pressure_under exit_flow_over 6 exit_pressure_over 11 max_flow_or_pressure 3.3 exit_pressure_under 0 seconds 40.00}}
author JoeD
beverage_type espresso
espresso_decline_time 30
espresso_hold_time 15
espresso_pressure 6.0
espresso_temperature 95.0
espresso_temperature_0 95.0
espresso_temperature_1 95.0
espresso_temperature_2 95.0
espresso_temperature_3 95.0
espresso_temperature_steps_enabled 0
final_desired_shot_volume 0
final_desired_shot_volume_advanced 0
final_desired_shot_volume_advanced_count_start 2
final_desired_shot_weight 0
final_desired_shot_weight_advanced 40
flow_profile_decline 1.2
flow_profile_decline_time 17
flow_profile_hold 2
flow_profile_hold_time 8
flow_profile_minimum_pressure 4
flow_profile_preinfusion 4
flow_profile_preinfusion_time 5
maximum_flow 0
maximum_flow_range 0.6
maximum_flow_range_advanced 1.2
maximum_flow_range_default 1.0
maximum_pressure 0
maximum_pressure_range 0.6
maximum_pressure_range_advanced 0.6
maximum_pressure_range_default 0.9
original_profile_title {JoeD's Easy blooming slow ramp to 7 bar}
preinfusion_flow_rate 4
preinfusion_guarantee 0
preinfusion_stop_pressure 4.0
preinfusion_time 20
pressure_end 4.0
profile_filename EasyBloom_SlowRampTo7
profile_language en
profile_notes {Downloaded from https://decentforum.com/t/effect-of-short-blooms-on-turbo-shots/1016

Downloaded from Visualizer}
profile_title {Visualizer/JoeD's Easy blooming slow ramp to 7 bar}
profile_to_save {Damian's LRv3}
settings_profile_type settings_2c
tank_desired_water_temperature 0