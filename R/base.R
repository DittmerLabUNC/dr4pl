# -----------------------------------------------------------------------------
### Dose response relation analysis (drra)
### Hyowon An, UNC Lineberger Comprehensive Cancer Center
### Last updated: 09/02/2016
#
DoseResponseCurve <- function(x, theta) {
  f <- theta[1] + (theta[4] - theta[1])/(1 + (x/theta[2])^theta[3])

  return(f)
}

Residual <- function(theta, x, y) {
  f <- theta[1] + (theta[4] - theta[1])/(1 + (x/theta[2])^theta[3])

  return(y - f)
}

ErrorFunction <- function(theta, dose, response) {
  # Sum of squared residuals
  #
  # Args:
  #   theta: Parameters
  #   x: Dose
  #   y: Response
  #
  # Returns:
  #   The value of the sum of squared residuals
  f <- theta[1] + (theta[4] - theta[1])/(1 + (dose/theta[2])^theta[3])

  return(sum((response - f)^2)/length(response))
}

GradientFunction <- function(theta, dose, response) {
  x <- dose
  y <- response

  theta.1 <- theta[1]
  theta.2 <- theta[2]
  theta.3 <- theta[3]
  theta.4 <- theta[4]

  eta <- (x/theta.2)^theta.3
  f <- theta.1 + (theta.4 - theta.1)/(1 + eta)

  deriv.f.theta.1 <- 1 - 1/(1 + eta)
  deriv.f.theta.2 <- (theta.4 - theta.1)*theta.3/theta.2*eta/(1 + eta)^2
  deriv.f.theta.3 <- -(theta.4 - theta.1)/theta.3*log(eta)*eta/(1 + eta)^2
  deriv.f.theta.4 <- 1/(1 + eta)

  deriv.f.theta.2[eta == Inf] <- 0
  deriv.f.theta.3[eta == Inf] <- 0

  return(-2*(y - f)%*%cbind(deriv.f.theta.1, deriv.f.theta.2, deriv.f.theta.3, deriv.f.theta.4))
}

DerivativeF <- function(theta, x) {
  # Compute the Jacobian matrix
  #
  # Args:
  #   theta: Parameters
  #
  # Returns:
  #   A Jacobian matrix
  eta <- (x/theta[2])^theta[3]
  f <- theta[1] + (theta[4] - theta[1])/(1 + eta)

  deriv.f.theta.1 <- 1 - 1/(1 + eta)
  deriv.f.theta.2 <- (theta[4] - theta[1])*theta[3]/theta[2]*eta/(1 + eta)^2
  deriv.f.theta.3 <- -(theta[4] - theta[1])/theta[3]*log(eta)*eta/(1 + eta)^2
  deriv.f.theta.4 <- 1/(1 + eta)

  deriv.f.theta.2[eta == Inf] <- 0
  deriv.f.theta.3[eta == Inf] <- 0

  return(cbind(deriv.f.theta.1, deriv.f.theta.2, deriv.f.theta.3, deriv.f.theta.4))
}

Hessian <- function(theta, x, y) {
  # Compute the Hessian matrix
  #
  # Args:
  #    theta: Parameters
  #    x: Dose
  #
  # Returns:
  #    A Hessian matrix
  n <- length(x)  # Number of observations
  p <- length(theta)  # Number of parameters

  # Second order derivatives of f
  second.deriv.f <- array(dim = c(p, p, n))

  # eta: terms needed in the Hessian matrix computation
  eta <- (x/theta[2])^theta[3]
  eta[x == 0] <- 0

  deriv.eta.2 <- -theta[3]/theta[2]*eta
  deriv.eta.3 <- eta*log(x/theta[2])
  if(theta[3] < 0) {
    deriv.eta.3[x == 0] <- -Inf
  }else {
    deriv.eta.3[x == 0] <- Inf
  }

  second.deriv.f[1, 1, ] <- 0
  second.deriv.f[1, 2, ] <- deriv.eta.2/(1+eta)^2
  second.deriv.f[1, 3, ] <- deriv.eta.3/(1+eta)^2
  second.deriv.f[1, 4, ] <- 0

  second.deriv.f[2, 1, ] <- -theta[3]/theta[2]*eta/(1 + eta)^2
  second.deriv.f[2, 2, ] <- (theta[4] - theta[1])*theta[3]/theta[2]/(1 + eta)^2*
    (-eta/theta[2] + (1 - eta)/(1 + eta)*deriv.eta.2)
  second.deriv.f[2, 3, ] <- (theta[4] - theta[1])/theta[2]/(1 + eta)^2*
    (eta + theta[3]*(1 - eta)/(1 + eta)*deriv.eta.3)
  second.deriv.f[2, 4, ] <- theta[3]/theta[2]*eta/(1 + eta)^2

  second.deriv.f[3, 1, ] <- log(x/theta[2])*eta/(1 + eta)^2
  second.deriv.f[3, 1, x == 0] <- -Inf
  second.deriv.f[3, 2, ] <- (theta[4] - theta[1])/(1 + eta)^2*
    (eta/theta[2] - (log(x/theta[2]))*(1 - eta)/(1 + eta)*deriv.eta.2)
  if(theta[4] > theta[1]) {
    second.deriv.f[3, 2, x == 0] <- Inf
  }else {
    second.deriv.f[3, 2, x == 0] <- -Inf
  }

  second.deriv.f[3, 3, ] <- -(theta[4] - theta[1])*(log(x/theta[2]))*
    (1 - eta)/(1 + eta)^3*deriv.eta.3
  second.deriv.f[3, 3, x == 0] <- Inf
  second.deriv.f[3, 4, ] <- -log(x/theta[2])*eta/(1 + eta)^2
  second.deriv.f[3, 4, x == 0] <- Inf

  second.deriv.f[4, 1, ] <- 0
  second.deriv.f[4, 2, ] <- -deriv.eta.2/(1+eta)^2
  second.deriv.f[4, 3, ] <- -deriv.eta.3/(1+eta)^2
  second.deriv.f[4, 4, ] <- 0

  deriv.f <- DerivativeF(theta, x)
  residual <- Residual(theta, x, y)

  hessian <- 2*t(deriv.f)%*%deriv.f - 2*tensor(second.deriv.f, residual, 3, 1)

  return(hessian)
}