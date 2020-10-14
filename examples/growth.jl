using JultraDark
using Random: randn!
using Test
using MPI
using PencilFFTs

const DEV_NULL = @static Sys.iswindows() ? "nul" : "/dev/null"

function x(k, a)
    m = 1
    H0 = 1
    k^2 / (m * H0 * a^0.5)
end

function δ_g(x)
    if x == 0
        0
    else
        -(3/x^2 - 1) * cos(x) - 3/x * sin(x)
    end
end

function S_g(x)
    if x == 0
        0
    else
        (6/x^3 + 3/x) * cos(x) + (6/x^2 - 1) * sin(x)
    end
end

function a(t)
    t^(2/3)
end

# function main()
    if ~MPI.Initialized()
        MPI.Init()
    end

    comm = MPI.COMM_WORLD
    # Disable output on all but one process.
    rank = MPI.Comm_rank(comm)
    rank == 0 || redirect_stdout(open(DEV_NULL, "w"))

    resol = 64
    box_length = 1.

    # Define initial conditions
    grids = JultraDark.PencilGrids(box_length, resol)

    t_init = 1

    A_k = allocate_output(grids.rfft_plan)
    randn!(A_k)

    # Density perturbation
    δ_k = allocate_output(grids.rfft_plan)
    δ_k .= A_k .* δ_g.(x.(grids.rk, a(t_init)))
    δ_k[1, 1, 1] = 0

    # Phase perturbation
    S_k = allocate_output(grids.rfft_plan)
    S_k .= A_k .* S_g.(x.(grids.rk, a(t_init)))

    grids.ψx .= (1 .+ grids.rfft_plan \ δ_k).^0.5 .* exp.(im .* (grids.rfft_plan \ S_k))

    output_dir = "output"
    output_times = 0.1:0.2

    output_config = OutputConfig(output_dir, output_times; box=false)
    options = Config.SimulationConfig(10, a)

    @test simulate(grids, options, output_config) == nothing

# end

# main()
