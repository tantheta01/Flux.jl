using Test
using Flux: onehotbatch, mse, crossentropy, logitcrossentropy,
            σ, binarycrossentropy, logitbinarycrossentropy

const ϵ = 1e-7

@testset "losses" begin
  # First, regression-style y's
  y = [1, 1, 0, 0]
  ŷ = [.9, .1, .1, .9]

  @testset "mse" begin
    @test mse(ŷ, y) ≈ (.1^2 + .9^2)/2
  end

  # Now onehot y's
  y = onehotbatch([1, 1, 0, 0], 0:1)
  ŷ = [.1 .9; .9 .1; .9 .1; .1 .9]'
  v = log(.1 / .9)
  logŷ = [v 0.0; 0.0 v; 0.0 v; v 0.0]'
  lossvalue = 1.203972804325936

  @testset "crossentropy" begin
    @test crossentropy(ŷ, y) ≈ lossvalue
  end

  @testset "logitcrossentropy" begin
    @test logitcrossentropy(logŷ, y) ≈ lossvalue
  end

  @testset "weighted_crossentropy" begin
    @test crossentropy(ŷ, y, weight = ones(2)) ≈ lossvalue
    @test crossentropy(ŷ, y, weight = [.5, .5]) ≈ lossvalue/2
    @test crossentropy(ŷ, y, weight = [2, .5]) ≈ 1.5049660054074199
  end

  @testset "weighted_logitcrossentropy" begin
    @test logitcrossentropy(logŷ, y, weight = ones(2)) ≈ lossvalue
    @test logitcrossentropy(logŷ, y, weight = [.5, .5]) ≈ lossvalue/2
    @test logitcrossentropy(logŷ, y, weight = [2, .5]) ≈ 1.5049660054074199
  end

  logŷ, y = randn(3), rand(3)
  @testset "binarycrossentropy" begin
    @test binarycrossentropy.(σ.(logŷ), y; ϵ=0) ≈ -y.*log.(σ.(logŷ)) - (1 .- y).*log.(1 .- σ.(logŷ))
    @test binarycrossentropy.(σ.(logŷ), y) ≈ -y.*log.(σ.(logŷ) .+ eps.(σ.(logŷ))) - (1 .- y).*log.(1 .- σ.(logŷ) .+ eps.(σ.(logŷ)))
  end

  @testset "logitbinarycrossentropy" begin
    @test logitbinarycrossentropy.(logŷ, y) ≈ binarycrossentropy.(σ.(logŷ), y; ϵ=0)
  end
  
  y = [1 2 3]
  y1 = [4.0 5.0 6.0]
  @testset "KLDivergence" begin
    @test Flux.KLDivergence(y, y1) ≈ 4.761838062403337
    @test Flux.KLDivergence(y, y) ≈ 0 
  end
  
  y = [1 2 3 4]
  y1 = [5.0 6.0 7.0 8.0]
  @testset "Hinge" begin
    @test Flux.Hinge(y, y1) ≈ 0
    @test Flux.Hinge(y, 0.5 .* y) ≈ 0.125
  end
  
  y = [0.1 0.2 0.3]
  y1 = [0.4 0.5 0.6]
  @testset "Poisson" begin
    @test Flux.Poisson(y, y1) ≈ 1.0160455586700767
    @test Flux.Poisson(y, y) ≈ 0.5044459776946685
  end

  @testset "logcosh" begin
    @test Flux.logcosh(y, y1) ≈ 0.13302230977782092
    @test Flux.logcosh(y, y) ≈ 0
  end
  
  @testset "no spurious promotions" begin
    for T in (Float16, Float32, Float64)
      y = rand(T, 2)
      ŷ = rand(T, 2)
      for f in (mse, crossentropy, logitcrossentropy)
        fwd, back = Flux.Tracker.forward(mse, ŷ, y)
        @test typeof(fwd) == Flux.Tracker.TrackedReal{T}
        @test eltype(back(one(T))[1]) == Flux.Tracker.TrackedReal{T}
      end
    end
  end
end
