## Copyright (C) 2023 Andreas Bertsatos <abertsatos@biol.uoa.gr>
##
## This file is part of the statistics package for GNU Octave.
##
## This program is free software: you can redistribute it and/or
## modify it under the terms of the GNU General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {statistics} {@var{nlogL} =} logilike (@var{params}, @var{x})
## @deftypefnx {statistics} {[@var{nlogL}, @var{acov}] =} logilike (@var{params}, @var{x})
## @deftypefnx {statistics} {[@dots{}] =} logilike (@var{params}, @var{x}, @var{censor})
## @deftypefnx {statistics} {[@dots{}] =} logilike (@var{params}, @var{x}, @var{censor}, @var{freq})
##
## Negative log-likelihood for the logistic distribution.
##
## @code{@var{nlogL} = logilike (@var{params}, @var{x})} returns the negative
## log likelihood of the data in @var{x} corresponding to the logistic
## distribution with (1) location parameter @var{mu} and (2) scale parameter
## @var{s} given in the two-element vector @var{params}.
##
## @code{[@var{nlogL}, @var{acov}] = logilike (@var{params}, @var{x})} also
## returns the inverse of Fisher's information matrix, @var{acov}.  If the input
## parameter values in @var{params} are the maximum likelihood estimates, the
## diagonal elements of @var{params} are their asymptotic variances.
##
## @code{[@dots{}] = logilike (@var{params}, @var{x}, @var{censor})} accepts a
## boolean vector, @var{censor}, of the same size as @var{x} with @qcode{1}s for
## observations that are right-censored and @qcode{0}s for observations that are
## observed exactly.  By default, or if left empty,
## @qcode{@var{censor} = zeros (size (@var{x}))}.
##
## @code{[@dots{}] = logilike (@var{params}, @var{x}, @var{censor}, @var{freq})}
## accepts a frequency vector, @var{freq}, of the same size as @var{x}.
## @var{freq} typically contains integer frequencies for the corresponding
## elements in @var{x}, but it can contain any non-integer non-negative values.
## By default, or if left empty, @qcode{@var{freq} = ones (size (@var{x}))}.
##
## Further information about the logistic distribution can be found at
## @url{https://en.wikipedia.org/wiki/Logistic_distribution}
##
## @seealso{logicdf, logiinv, logipdf, logirnd, logifit}
## @end deftypefn

function [nlogL, acov] = logilike (params, x, censor, freq)

  ## Check input arguments
  if (nargin < 2)
    error ("logilike: function called with too few input arguments.");
  endif

  if (! isvector (x))
    error ("logilike: X must be a vector.");
  endif

  if (length (params) != 2)
    error ("logilike: PARAMS must be a two-element vector.");
  endif

  ## Check censor vector
  if (nargin < 3 || isempty (censor))
    censor = zeros (size (x));
  elseif (! isequal (size (x), size (censor)))
    error ("logilike: X and CENSOR vector mismatch.");
  endif

  ## Check frequency vector
  if (nargin < 4 || isempty (freq))
    freq = ones (size (x));
  elseif (! isequal (size (x), size (freq)))
    error ("logilike: X and FREQ vector mismatch.");
  endif

  ## Expand frequency and censor vectors (if necessary)
  if (! all (freq == 1))
    xf = [];
    cf = [];
    for i = 1:numel (freq)
      xf = [xf, repmat(x(i), 1, freq(i))];
      cf = [cf, repmat(censor(i), 1, freq(i))];
    endfor
    x = xf;
    freq = ones (size (x));
    censor = cf;
  endif

  ## Get parameters
  mu = params(1);
  s = params(2);

  z = (x - mu) ./ s;
  logclogitz = log (1 ./ (1 + exp (z)));
  k = (z > 700);
  if (any (k))
    logclogitz(k) = z(k);
  endif

  L = z + 2 .* logclogitz - log (s);
  n_censored = sum (freq .* censor);
  ## Handle censored data
  if (n_censored > 0)
    censored = (censor == 1);
    L(censored) = logclogitz(censored);
  endif

  ## Sum up the neg log likelihood
  if (s < 0)
    nlogL = Inf;
  else
    nlogL = -sum (freq .* L);
  endif

  ## Compute asymptotic covariance
  if (nargout > 1)
    ## Compute first order central differences of the log-likelihood gradient
    dp = 0.0001 .* max (abs (params), 1);

    ngrad_p1 = logi_grad (params + [dp(1), 0], x, censor, freq);
    ngrad_m1 = logi_grad (params - [dp(1), 0], x, censor, freq);
    ngrad_p2 = logi_grad (params + [0, dp(2)], x, censor, freq);
    ngrad_m2 = logi_grad (params - [0, dp(2)], x, censor, freq);

    ## Compute negative Hessian by normalizing the differences by the increment
    nH = [(ngrad_p1(:) - ngrad_m1(:))./(2 * dp(1)), ...
          (ngrad_p2(:) - ngrad_m2(:))./(2 * dp(2))];

    ## Force neg Hessian being symmetric
    nH = 0.5 .* (nH + nH');
    ## Check neg Hessian is positive definite
    [R, p] = chol (nH);
    if (p > 0)
      warning ("logilike: non positive definite Hessian matrix.");
      acov = NaN (2);
      return
    endif
    ## ACOV estimate is the negative inverse of the Hessian.
    Rinv = inv (R);
    acov = Rinv * Rinv;
  endif

endfunction

## Helper function for computing negative gradient
function ngrad = logi_grad (params, x, censor, freq)
  mu = params(1);
  s = params(2);
  z = (x - mu) ./ s;
  logitz = 1 ./ (1 + exp (-z));
  dL1 = (2 .* logitz - 1) ./ sigma;
  dL2 = z .* dL1 - 1 ./ sigma;
  n_censored = sum (freq .* censor);
  if (n_censored > 0)
    censored = (censor == 1);
    dL1(censored) = logitz(censored) ./ sigma;
    dL2(censored) = z(censored) .* dL1(censored);
  endif
  ngrad = -[sum(freq .* dL1), sum(freq .* dL2)];
endfunction


## Test results
%!test
%! nlogL = logilike ([25.5, 8.7725], [1:50]);
%! assert (nlogL, 206.6769, 1e-4);
%!test
%! nlogL = logilike ([3, 0.8645], [1:5]);
%! assert (nlogL, 9.0699, 1e-4);

## Test input validation
%!error<logilike: function called with too few input arguments.> logilike (3.25)
%!error<logilike: X must be a vector.> logilike ([5, 0.2], ones (2))
%!error<logilike: PARAMS must be a two-element vector.> ...
%! logilike ([1, 0.2, 3], [1, 3, 5, 7])
%!error<logilike: X and CENSOR vector mismatch.> ...
%! logilike ([1.5, 0.2], [1:5], [0, 0, 0])
%!error<logilike: X and FREQ vector mismatch.> ...
%! logilike ([1.5, 0.2], [1:5], [0, 0, 0, 0, 0], [1, 1, 1])
%!error<logilike: X and FREQ vector mismatch.> ...
%! logilike ([1.5, 0.2], [1:5], [], [1, 1, 1])
