# physics
#
# contains all other hydrodynamic/star formation physics
#
# Created 03-22-2023
# Author Daniel Boyea (boyea.2@osu.edu)



module Physics

export dm_star!
export du_cond!, du_P!
export dv_DM!, dv_P!
export du_visc!, dv_visc!
export c_sound, pressure, temp


using LinearAlgebra
using Debugger

using ..Particles
using ..Constants
using ..Density



"""
Pressure of particle p
(from current energy and μ)
"""
pressure(p) = 2/3 * p.u * p.ρ
temp(p) = 2p.μ/(3R_ig) * p.u




"""
Helper function for dv_DM!, returns scalar part of acceleration due
to DM
"""
function a_DM(r::F, params)
    if r == 0
        return 0
    end
    G*params.M_tot/params.A_NFW * 1/r^2 * (r/(r + params.Rs) - log(1 + r/params.Rs))
end



"""
Acceleration due to pressure (and viscosity)
"""
function dv_P!(p::Particle, params)
    p.dv_P .= zeros(3)
    for q in p.neighbors
        p.dv_P .+= -q.m .* (
            -p.P/p.ρ^2/p.Ω .* ∇W(p, q)
            .+ q.P/q.ρ^2/q.Ω .* ∇W(q, p)
           ) 
    end
    return p.dv_P
end



""" Change in thermal energy due to heat conduction """
function du_cond!(p::Particle, params)
    p.du_cond = 0.

    kp = params.K_cond/p.ρ
    for q in p.neighbors
        kq = params.K_cond/q.ρ
        ρ_pq = (p.ρ + q.ρ)/2
        p.du_cond += - q.m * (kp+kq) * (p.u-q.u) * (q.x-p.x) ⋅ ∇W(p, q) / (
                                ρ_pq * dist(p, q)^2 + params.eps*p.h^2)
    end

    return p.du_cond
end



"""
Change in energy due to pressure
"""
function du_P!(p, params)
    s = 0

    for q in p.neighbors
        s += q.m * (q.v .- p.v) ⋅ ∇W(p, q)
    end

    p.du_P = p.P/p.Ω/p.ρ^2 * s
    return p.du_P
end



"""
Sound speed in the gas of p 
"""
function c_sound(p)
    if p.T >= 0
        return sqrt(5/3 * R_ig * p.T/p.μ)
    else
        println(p)
        throw(DomainError(p.T, "T must be positive!"))
    end
end






"""
The change in star formation mass (in-place) for p
"""
function dm_star!(p::Particle, params)
    if !params.phys_star_formation
        return 0.
    end
    t_ff = sqrt(3π/(32 * G * p.ρ_gas))
    p.dm_star = params.eta_eff * p.m_gas/t_ff
    return p.dm_star
end



"""
Signal speed between two particles
"""
function v_sig(p::Particle, q::Particle, params)
    if !params.phys_visc
        return 0
    end

    v_r = (q.v .- p.v) ⋅ normalize(q.x .- p.x)

    if v_r <= 0
        return 1/2 * (p.c + q.c - params.beta*v_r)
    else # the particles are moving away from eachother
        return 0.
    end
end


"""
Energy signal speed between two particles
"""
function v_sig_u(p::Particle, q::Particle, params)
    if !params.phys_visc
        return 0
    end

    v_r = (q.v .- p.v) ⋅ normalize(q.x .- p.x)

    if v_r <= 0
        return sqrt(2*abs(p.P - q.P)/(p.ρ + q.ρ))
    else # the particles are moving away from eachother
        return 0.
    end
end


"""
change in energy due to viscosity
"""
function du_visc!(p::Particle, params)
    if !params.phys_visc
        return 0.
    end
    p.du_visc = 0.

    for q in p.neighbors
        ρ_pq = (p.ρ + q.ρ)/2
        p.du_visc += q.m/ρ_pq*(
            1/2*params.alpha*v_sig(p, q, params)^2 
            + params.alpha*v_sig_u(p, q, params) * (p.u - q.u)
           ) * (dW(p, q) + dW(q, p))/2
    end

    return p.du_visc
end


"""
Acceleration due to viscosity
"""
function dv_visc!(p::Particle, params)
    p.dv_visc .= zeros(3)
    for q in p.neighbors
        ρ_pq = (p.ρ + q.ρ)/2
        vr = (p.v - q.v) ⋅ normalize(p.x - q.x)
        p.dv_visc .+= -q.m/ρ_pq * v_sig(p, q, params) .* vr .* ( ∇W(p, q)  .- ∇W(q, p) )
    end
    return p.dv_visc
end




end
