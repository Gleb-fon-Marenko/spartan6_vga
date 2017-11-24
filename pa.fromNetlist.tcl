
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name vga -dir "D:/14.7/ISE_DS/5-Example/vga/planAhead_run_2" -part xc6slx9tqg144-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "D:/14.7/ISE_DS/5-Example/vga/top_sdram.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {D:/14.7/ISE_DS/5-Example/vga} {ipcore_dir} }
set_property target_constrs_file "top_sdram.ucf" [current_fileset -constrset]
add_files [list {top_sdram.ucf}] -fileset [get_property constrset [current_run]]
link_design
