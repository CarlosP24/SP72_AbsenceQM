function build_disorder(h::Quantica.ParametricHamiltonian, W)
    mod! = @onsite!((o, r; W = W) -> o + W * (rand() - 0.5) * σ0τz)
    return h |> mod!
end