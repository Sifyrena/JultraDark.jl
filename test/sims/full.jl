using JultraDark
    
resol = 16

grids = JultraDark.Grids(zeros(Complex{Float64}, resol, resol, resol), 1)

output_dir = "output"
output_times = 0:10

output_config = OutputConfig(output_dir, output_times; box=false)
options = Config.SimulationConfig(10, t->1)

@test simulate(grids, options, output_config) == nothing
