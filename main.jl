root_dir=pwd();
# ==============================================================================
# 1 - PARAMETERS
# ==============================================================================
	# High level
	opti    = true
	visu    = true
	folder  = "FdN_100scenarios"

	# Instance
	beta    = 1
	targets = 0.50 .* [1,1,1]

	# Risk-level
	alpha = 0.75

# ==============================================================================
# 2 - LOAD INSTANCE
# ==============================================================================
	# Load libraries, functions, data structure and models
	println("load_path_pkg.jl  ...");include("$(root_dir)/2_functions/load_path_pkg.jl");
	println("load_functions.jl ...");include("$(func_dir)/load_functions.jl");
	println("load_struct.jl    ...");include("$(func_dir)/load_struct.jl");
	println("load_model.jl     ...");include("$(func_dir)/load_model.jl");

    t1 = time_ns()

	# Indicate input data files
    pu_fname     = "$(data_dir)/$(folder)/pu.csv"
    cf_fname     = "$(data_dir)/$(folder)/cf.csv"
    bound_fname  = "$(data_dir)/$(folder)/bound.csv"
    coords_fname = "$(data_dir)/$(folder)/coords.csv"
	cf_unc_fname = []
    for i in 1:length(targets)
      global cf_unc_fname = append!(cf_unc_fname,["$(data_dir)/$(folder)/uncertainty_cf$(i)_scenarios.csv"])
    end
	
    # Create instance and regular grid
    gridgraph = RegularGrid(coords_fname)
    instance  = Instance(pu_fname,cf_fname,bound_fname,cf_unc_fname,beta,targets,gridgraph)

	t2 = time_ns()
	loading_time = round((t2-t1)/1e9,digits=2)
    println("Instance of nominal problem created ($(loading_time)s)")


# ==============================================================================
# 3 - CHANCE CONSTRAINT OPTIMIZATION FRAMEWORK
# ==============================================================================
	if opti == true

	    t1 = time_ns()

		# Compute the chance constraint solution		
		m = minset_chance_constraint(instance,gridgraph,alpha)	
		optimize!(m);
		x_cc,z_cc = read_reserve_solution(m,gridgraph)
		print_reserve_solution(x_cc,instance,gridgraph)
		
		t2 = time_ns()
		computation_time = round((t2-t1)/1e9,digits=2)
	    println("Chance constraint solution computed ($(computation_time)s)")

		# Create a reserve object
		reserve_chance_constraint = Reserve(x_cc,instance)

		# Write reserve solutions in a .csv file
		sol_fname = "$(sc_dir)/solution_chance_constraint_alpha$(alpha).csv"
		sol_data  = DataFrame([instance.PlanningUnits reserve_chance_constraint.x],:auto)
		rename!(sol_data,["id","reserve"])
		CSV.write(sol_fname, sol_data, header=true)

	end


# ==============================================================================
# 4 - VISUALISATION
# ==============================================================================
	if visu == true
	    t1 = time_ns()
	    plot_opt = PlotOptions(gridgraph.N_x*30,gridgraph.N_y*30,"Longitude [deg]","Latitude [deg]",5)
		
		# Plot input
		visualisation_input(instance,gridgraph,plot_opt)

		# Load solution
		sol_fname = "$(sc_dir)/solution_chance_constraint_alpha$(alpha).csv"
		sol_data  = CSV.read(sol_fname, DataFrame, header=1, delim=",")
		reserve   = Reserve(sol_data.reserve,instance)

		# Plot solution
		visualisation_output(reserve,instance,gridgraph,plot_opt,"solution_chance_constraint_alpha$(alpha).png")
		visualisation_coverage_histograms(reserve,instance,plot_opt,1,"solution_cf1_scenario_coverage_alpha$(alpha).png")

		t2 = time_ns()
		visualisation_time = round((t2-t1)/1e9,digits=2)
	    println("Visualisation over ($(visualisation_time)s)")
	end
