export ricker_wavelet,
       make_amplitude_demo,
       make_shift_demo,
       make_mixed_demo,
       write_demo_csv

function ricker_wavelet(t::AbstractVector, f0::Real; t0::Real=0.0)
    x = @. pi * f0 * (t - t0)
    return @. (1 - 2x^2) * exp(-x^2)
end

function make_amplitude_demo(t::AbstractVector; f0::Real=5.0,
                             amp_scale::Real=1.01,
                             t0::Real=0.0)
    s_ref = ricker_wavelet(t, f0; t0=t0)
    s_test = amp_scale .* s_ref
    return s_ref, s_test
end

function make_shift_demo(t::AbstractVector; f0::Real=5.0,
                         shift_fraction_of_period::Real=0.01,
                         t0::Real=0.0)
    T0 = 1 / f0
    dt_shift = shift_fraction_of_period * T0

    s_ref = ricker_wavelet(t, f0; t0=t0)
    s_test = ricker_wavelet(t, f0; t0=t0 - dt_shift)

    return s_ref, s_test
end

function make_mixed_demo(t::AbstractVector; f0::Real=5.0,
                         amp_scale::Real=1.01,
                         shift_fraction_of_period::Real=0.01,
                         t0::Real=0.0)
    T0 = 1 / f0
    dt_shift = shift_fraction_of_period * T0

    s_ref = ricker_wavelet(t, f0; t0=t0)
    s_test = amp_scale .* ricker_wavelet(t, f0; t0=t0 - dt_shift)

    return s_ref, s_test
end

function write_demo_csv(path::AbstractString,
                        t::AbstractVector,
                        s1::AbstractVector,
                        s2::AbstractVector)
    n = length(t)
    length(s1) == n || error("s1 must have same length as t")
    length(s2) == n || error("s2 must have same length as t")

    open(path, "w") do io
        println(io, "time,signal1,signal2")
        for i in eachindex(t)
            println(io, "$(t[i]),$(s1[i]),$(s2[i])")
        end
    end

    return path
end