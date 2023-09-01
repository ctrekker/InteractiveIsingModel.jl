using GLMakie, Random

GLMakie.activate!(; title = "The Ising Model and Permanent Magnets - Simulation")

random_spin_lattice(N, M) = rand(-1:2:1, N, M)

function calculate_energy(spins, i, j, field)
    N = size(spins, 1)
    left = j == 1 ? spins[i, N] : spins[i, j - 1]
    right = j == N ? spins[i, 1] : spins[i, j + 1]
    up = i == 1 ? spins[N, j] : spins[i - 1, j]
    down = i == N ? spins[1, j] : spins[i + 1, j]
    
    return -spins[i, j] * (left + right + up + down + field)
end

function metropolis_step!(spins, temperature, field)
    N, M = size(spins)
    i, j = rand(1:N), rand(1:M)
    energy_initial = calculate_energy(spins, i, j, field)
    
    spins[i, j] *= -1
    
    energy_final = calculate_energy(spins, i, j, field)
    ΔE = energy_final - energy_initial
    
    if ΔE > 0 && rand() > exp(-ΔE / temperature)
        spins[i, j] *= -1
    end
end


function ising_figure()
    N = Observable(100)
    temperature = Observable(0.)
    field = Observable(0.)
    steps_per_display = Observable(100)


    fig = Figure(; title="Ising Model", resolution=(800, 1000))
    display(fig)
    ax = Axis(fig[1, 1])

    spin_mat_observable = Observable(random_spin_lattice(N[], N[]))
    heatmap!(ax, spin_mat_observable; colorrange=(-1, 1))

    buttons = GridLayout(fig[3, 1]; tellwidth=false)
    run = Button(buttons[1, 1]; label="Run")
    reset = Button(buttons[1, 2]; label="Reset")

    isrunning = Observable(false)
    on(run.clicks) do clicks
        isrunning[] = !isrunning[]
    end
    on(run.clicks) do clicks
        @async while isrunning[]
            start_time = time()
            spin_mat = spin_mat_observable[]
            for _ ∈ 1:steps_per_display[]
                metropolis_step!(spin_mat, temperature[], field[])
            end
            spin_mat_observable[] = spin_mat
            dt = time() - start_time
            sleep(max(0, 1 / 60 - dt))
        end
    end

    function do_reset(clicks = nothing)
        spin_mat = random_spin_lattice(N[], N[])
        spin_mat_observable[] = spin_mat
        heatmap!(ax, spin_mat_observable; colorrange=(-1, 1))
    end
    on(do_reset, reset.clicks)

    sg = SliderGrid(fig[2, 1],
        (label = "Temperature", range = 0:0.1:10, startvalue = 0, format = "{:.1f} K"),
        (label = "External magnetic field", range = -10:0.1:10, startvalue = 0, format = "{:.1f} T"),
        (label = "System size", range = 5:5:1000, startvalue = 100),
        (label = "Steps per display", range = 1:10000, startvalue = 300)
    )

    on(sg.sliders[1].value) do _temperature
        temperature[] = _temperature
    end

    on(sg.sliders[2].value) do _field
        field[] = _field
    end

    on(sg.sliders[3].value) do _systemsize
        N[] = _systemsize
        do_reset()
    end

    on(sg.sliders[4].value) do _steps_per_display
        steps_per_display[] = _steps_per_display
    end

    on(events(fig).window_open) do open
        if !open
            exit()
        end
    end
end

ising_figure()

wait(Condition())
