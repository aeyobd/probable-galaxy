module GalaxySim

export yr, pc, Msun, G, m_p
export Particle, Params, evolve!

include("constants.jl")
include("params.jl")
include("particles.jl")
include("gal_files.jl")
include("density.jl")
include("tree.jl")
include("physics.jl")
include("evolve.jl")


using .Constants
using .Particles
using .GalFiles
using .Density
using .Tree
using .Physics
using .Evolve


end
