####################################################
###                                              ###
###  SIMULATION AND RANDOM VARIABLE GENERATION   ###
###                                              ###
####################################################

## WHAT IS STOCHASTIC SIMULATION ? (SEE SLIDES)

# Step 1 is model building...we build up a complex
# model from simple components which in this case
# are independent rv's with known distributions.

# R has functions for simulating all of the common
# rv's. Here we examine doing this for ourselves,
# so we have tools for simulating rv's not provided
# by R

# We look at:

# Discrete random variables;

# Inversion and Rejection methods for simulating
# continuous random variables; and then

# Particular techniques for simulating normals.

# All random variables can be generated by
# manipulating U(0,1) rv's so we begin there.

## Simulating iid Uniform Samples

# Is pseuo-random number generation...they are
# deterministic so any experiment can be replicated

# Seeding

# Number X_sub_0 is called the seed
# If you know the seed and the dynamic algorithm
# that produces the sequence you can reproduce it.

# To generate n pseudo-random numbers in R we
# use runif(n). In R the command set.seed(seed)
# puts you at point seed (assumed integer) of the
# cycle of pseudo-random numbers.

# The current state of the random number generator
# is maintained in the vector .Random.seed

# You can save the value of .Random.seed and then
# use it to return to that point in the sequence
# of pseudo-random numbers.

# If you do not use set.seed(), R initializes
# the sequence using value taken from system clock

# set 42 as seed
set.seed(42)
runif(2)

# save state of random number generator
RNG.state <- .Random.seed
runif(2)  # different return values seed reset

# set seed back to 42
set.seed(42)
runif(4)# returns same two initial values

# reset state to return same values as before
.Random.seed <- RNG.state
runif(2)

### Simulating Discrete Random Variables

# Let X be a discrete random variable taking values
# from set {0,1,...} with cdf F. Following code takes
# a uniform random variable U and returns a discrete
# random variable X with cdf F:

## given U ~ U(0,1)
# X <- 0
# while (F(X) < U) {
#  X <- X + 1
}

# Use sample() function for simulating a finite rv:
# sample(x, size, replace = FALSE, prob = NULL)
# where
# x is a vector giving possible values for rv
# size: How many rv's to simulate
# replace: TRUE for iid sample
# prob: Optional vector of probabilities of x values

### EXAMPLE: BINOMIAL

# We are doing this 'manually': R has superior
# binomial probability and simulation functions.
# For example, see ?rbinom

# If X ~ binom(n,p) the function binom.cdf()
# calculates cdf F_sub_x of F

# In cdf.sim() first argument is function F
# assumed to calculate the cdf of non-negative
# integer valued random variable.
# Argument (...) passes parameters to function F:

# To simulate a single binom(n,p) rv we can call
# cdf.sim(binom.cdf(), n, p)
binom.cdf <- function(x, n, p) {
  Fx <- 0
  for (i in 0:x) { # inefficient, see below
    # To calculate FX(x), (F_sub_x), must
    # recalculate px(0),px(1): Can improve
    # by doing this recursively, see below
    Fx <- Fx + choose(n, i)*p^i*(1-p)^(n-i)
  }
  return(Fx)
}

# In cdf.sim() first argument is function F
# assumed to calculate the cdf of non-negative
# integer valued random variable.
# Argument (...) passes parameters to function F:
cdf.sim <- function(F, ...) {
  X <- 0
  U <- runif(1)
  while (F(X, ...) < U) {
    X <- X + 1
  }
  return(X)
}

# Let's try it:
cdf.sim(binom.cdf, 100, 0.5)
# [1] 50 # expect 50 successful trials

# But we have efficiency problem noted above.
# Can rewrite by combining loop in cdf.sim()
# which checks F(X,...) < U, with the loop in
# binom.cdf(), which calculates F_sub_x

# program spuRs/resources/scripts/binom.sim.r
binom.sim <- function(n, p) {
  X <- 0
  px <- (1-p)^n
  Fx <- px
  U <- runif(1)
  while (Fx < U) {
    X <- X + 1
    px <- px*p/(1-p)*(n-X+1)/X
    Fx <- Fx + px
  }
  return(X)
}

# Let's see if binom.sim works. We generate a large
# sample to estimate p(x), the compare the estimate
# with the known probabilities. We use dbinom() to
# calculate the actual probability densities. Then
# we plot the output and 95% CI's.
?dbinom

# inputs
N <- 10000 # sample size
n <- 10 # rv parameters
p <- 0.7
set.seed(100) # seed for RNG

# generate sample and estimate p
X <- rep(0, N)
for (i in 1:N) X[i] <- binom.sim(n, p)
phat <- rep(0, n+1)
for (i in 0:n) phat[i+1] <- sum(X == i)/N
phat.CI <- 1.96*sqrt(phat*(1-phat)/N)

# plot output: Note true values indicated
# with filled dot, and a plus sign is used
# for the estimates and their 95% CI's
plot(0:n, dbinom(0:n, n, p), type="h", xlab="x", ylab="p(x)")
points(0:n, dbinom(0:n, n, p), pch=19)
points(0:n, phat, pch=3)
points(0:n, phat+phat.CI, pch=3)
points(0:n, phat-phat.CI, pch=3)

#### Sequences of Independent Trials

# For random variables defined using a sequence 
# of independent trials (the binomial, geometric, 
# and negative binomial), we have alternative 
# methods appropriate for an advanced course.

### Inversion Method for continuous rv

# Inverse Transformation Method

## EXAMPLE: Uniform Distribution (SEE SLIDES)

## EXAMPLE: Exponential Distribution (SEE SLIDES)

### REJECTION METHOD FOR CONTINUOUS RVs (SLIDES)

## EXAMPLE: Triangular Density (SEE SLIDES)



# program spuRs/resources/scripts/rejecttriangle.r

rejectionK <- function(fx, a, b, K) {
  # simulates from the pdf fx using the rejection algorithm
  # assumes fx is 0 outside [a, b] and bounded by K
  # note that we exit the infinite loop using the return statement
  while (TRUE) {
    x <- runif(1, a, b)
    y <- runif(1, 0, K)
    if (y < fx(x)) return(x)
  }
}

fx<-function(x){
  # triangular density
  if ((0<x) && (x<1)) {
    return(x)
  } else if ((1<x) && (x<2)) {
    return(2-x)
  } else {
    return(0)
  }
}

# generate a sample
set.seed(21)
nreps <- 3000
Observations <- rep(0, nreps)
for(i in 1:nreps)   {
  Observations[i] <- rejectionK(fx, 0, 2, 1)
}

# plot a scaled histogram of the sample and the density on top
hist(Observations, breaks = seq(0, 2, by=0.1), freq = FALSE,
     ylim=c(0, 1.05), main="")
lines(c(0, 1, 2), c(0, 1, 0))

### General Rejection Method

# (SEE SLIDES)

### EXAMPLE: Gamma


# program spuRs/resources/scripts/gamma.sim.r

gamma.sim <- function(lambda, m) {
  # sim a gamma(lambda, m) rv using rejection with an exp envelope
  # assumes m > 1 and lambda > 0
  f <- function(x) lambda^m*x^(m-1)*exp(-lambda*x)/gamma(m)
  h <- function(x) lambda/m*exp(-lambda/m*x)
  k <- m^m*exp(1-m)/gamma(m)
  while (TRUE) {
    X <- -log(runif(1))*m/lambda
    Y <- runif(1, 0, k*h(X))
    if (Y < f(X)) return(X)
  }
}

set.seed(1999)
n <- 10000
g <- rep(0, n)
for (i in 1:n) g[i] <- gamma.sim(1, 2)
hist(g, breaks=20, freq=F, xlab="x", ylab="pdf f(x)",
     main="theoretical and simulated gamma(1, 2) density")
x <- seq(0, max(g), .1)
lines(x, dgamma(x, 2, 1))

### Simulating Normals

# Central Limit Theorem

