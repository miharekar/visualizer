advanced_shot {{exit_if 1 flow 4 volume 100 transition fast exit_flow_under 0 temperature 91.5 name preinfusion pressure 1.1 sensor coffee pump pressure exit_type pressure_over exit_flow_over 6 exit_pressure_over 3.0 exit_pressure_under 0 seconds 5.0} {exit_if 0 flow 0.0 volume 100 transition fast exit_flow_under 0 temperature 91.5 name soak pressure 1.1 sensor coffee pump pressure exit_type pressure_over exit_flow_over 6 exit_pressure_over 3.0 exit_pressure_under 0 seconds 10.0} {exit_if 0 flow 0.0 volume 100 transition smooth exit_flow_under 0 temperature 91.5 name ramp pressure 9.0 sensor coffee pump pressure exit_type pressure_over exit_flow_over 6 exit_pressure_over 9.0 exit_pressure_under 0 seconds 10.0} {exit_if 0 flow 0.0 volume 100 transition smooth exit_flow_under 0 temperature 92.0 name ramp-down pressure 3.0 sensor coffee pump pressure exit_type pressure_over exit_flow_over 6 exit_pressure_over 11 exit_pressure_under 0 seconds 50.0}}
author Decent
beverage_type espresso
espresso_decline_time 25
espresso_hold_time 10
espresso_pressure 8.6
espresso_temperature 91.5
espresso_temperature_0 91.5
espresso_temperature_1 91.5
espresso_temperature_2 91.5
espresso_temperature_3 91.5
espresso_temperature_steps_enabled 0
final_desired_shot_volume 38
final_desired_shot_volume_advanced 0
final_desired_shot_volume_advanced_count_start 0
final_desired_shot_weight 38
final_desired_shot_weight_advanced 0
flow_profile_decline 1.2
flow_profile_decline_time 17
flow_profile_hold 2
flow_profile_hold_time 8
flow_profile_minimum_pressure 4
flow_profile_preinfusion 4
flow_profile_preinfusion_time 5
maximum_flow 0
maximum_flow_range 0.6
maximum_flow_range_advanced 1.5
maximum_flow_range_default 1.0
maximum_pressure 0
maximum_pressure_range 0.6
maximum_pressure_range_advanced 1.0
maximum_pressure_range_default 0.9
original_profile_title {Cremina lever machine}
preinfusion_flow_rate 4
preinfusion_guarantee 0
preinfusion_stop_pressure 4
preinfusion_time 20
pressure_end 6.0
profile_filename Cremina
profile_language en
profile_notes {Aim for a 50 second shot time to have a thick espresso in the style of the much-loved Cremina manual lever machine. By Denis from KafaTek.

Downloaded from Visualizer}
profile_title {Visualizer/Cremina lever machine}
profile_to_save {Cremina lever machine}
settings_profile_type settings_2c
tank_desired_water_temperature 0