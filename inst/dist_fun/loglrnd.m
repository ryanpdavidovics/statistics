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
## @deftypefn  {statistics} {@var{r} =} loglrnd (@var{a}, @var{b})
## @deftypefnx {statistics} {@var{r} =} loglrnd (@var{a}, @var{b}, @var{rows})
## @deftypefnx {statistics} {@var{r} =} loglrnd (@var{a}, @var{b}, @var{rows}, @var{cols}, @dots{})
## @deftypefnx {statistics} {@var{r} =} loglrnd (@var{a}, @var{b}, [@var{sz}])
##
## Random arrays from the log-logistic distribution.
##
## @code{@var{r} = loglrnd (@var{a}, @var{b})} returns an array of random
## numbers chosen from the log-logistic distribution with scale parameter
## @var{a} and shape parameter @var{b}.  The size of @var{r} is the common size
## of @var{a} and @var{b}.  A scalar input functions as a constant matrix of the
## same size as the other inputs.
##
## Both parameters must be positive reals, otherwise @qcode{NaN} is returned.
##
## When called with a single size argument, @code{loglrnd} returns a square
## matrix with the dimension specified.  When called with more than one scalar
## argument, the first two arguments are taken as the number of rows and columns
## and any further arguments specify additional matrix dimensions.  The size may
## also be specified with a row vector of dimensions, @var{sz}.
##
## Further information about the log-logistic distribution can be found at
## @url{https://en.wikipedia.org/wiki/Log-logistic_distribution}
##
## MATLAB compatibility: MATLAB uses an alternative parameterization given by
## the pair @math{μ, s}, i.e. @var{mu} and @var{s}, in analogy with the logistic
## distribution.  Their relation to the @var{a} and @var{b} parameters is given
## below:
##
## @itemize
## @item @qcode{@var{a} = exp (@var{mu})}
## @item @qcode{@var{b} = 1 / @var{s}}
## @end itemize
##
## @seealso{loglcdf, loglinv, loglpdf, loglfit, logllike}
## @end deftypefn

function r = loglrnd (a, b, varargin)

  ## Check for valid number of input arguments
  if (nargin < 2)
    error ("loglrnd: function called with too few input arguments.");
  endif

  ## Check for common size of A, and B
  if (! isscalar (a) || ! isscalar (b))
    [retval, a, b] = common_size (a, b);
    if (retval > 0)
      error ("loglrnd: A and B must be of common size or scalars.");
    endif
  endif

  ## Check for X, A, and B being reals
  if (iscomplex (a) || iscomplex (b))
    error ("loglrnd: A and B must not be complex.");
  endif

  ## Parse and check SIZE arguments
  if (nargin == 2)
    sz = size (a);
  elseif (nargin == 3)
    if (isscalar (varargin{1}) && varargin{1} >= 0 ...
                               && varargin{1} == fix (varargin{1}))
      sz = [varargin{1}, varargin{1}];
    elseif (isrow (varargin{1}) && all (varargin{1} >= 0) ...
                                && all (varargin{1} == fix (varargin{1})))
      sz = varargin{1};
    elseif
      error (strcat (["loglrnd: SZ must be a scalar or a row vector"], ...
                     [" of non-negative integers."]));
    endif
  elseif (nargin > 3)
    posint = cellfun (@(x) (! isscalar (x) || x < 0 || x != fix (x)), varargin);
    if (any (posint))
      error ("loglrnd: dimensions must be non-negative integers.");
    endif
    sz = [varargin{:}];
  endif

  ## Check that parameters match requested dimensions in size
  if (! isscalar (a) && ! isequal (size (a), sz))
    error ("loglrnd: A and B must be scalars or of size SZ.");
  endif

  ## Check for class type
  if (isa (a, "single") || isa (b, "single"))
    is_type = "single";
  else
    is_type = "double";
  endif

  ## Generate random sample from log-logistic distribution
  p = rand (sz, is_type);
  r = a .* (p ./ (1 - p)) .^ (1 ./ b);

  ## Force output to NaN for invalid parameters A and B
  k = (a <= 0 | b <= 0);
  r(k) = NaN;

endfunction

## Test output
%!assert (size (loglrnd (1, 1)), [1 1])
%!assert (size (loglrnd (1, ones (2,1))), [2, 1])
%!assert (size (loglrnd (1, ones (2,2))), [2, 2])
%!assert (size (loglrnd (ones (2,1), 1)), [2, 1])
%!assert (size (loglrnd (ones (2,2), 1)), [2, 2])
%!assert (size (loglrnd (1, 1, 3)), [3, 3])
%!assert (size (loglrnd (1, 1, [4, 1])), [4, 1])
%!assert (size (loglrnd (1, 1, 4, 1)), [4, 1])
%!assert (size (loglrnd (1, 1, 4, 1, 5)), [4, 1, 5])
%!assert (size (loglrnd (1, 1, 0, 1)), [0, 1])
%!assert (size (loglrnd (1, 1, 1, 0)), [1, 0])
%!assert (size (loglrnd (1, 1, 1, 2, 0, 5)), [1, 2, 0, 5])

## Test class of input preserved
%!assert (class (loglrnd (1, 1)), "double")
%!assert (class (loglrnd (1, single (1))), "single")
%!assert (class (loglrnd (1, single ([1, 1]))), "single")
%!assert (class (loglrnd (single (1), 1)), "single")
%!assert (class (loglrnd (single ([1, 1]), 1)), "single")

## Test input validation
%!error<loglrnd: function called with too few input arguments.> loglrnd ()
%!error<loglrnd: function called with too few input arguments.> loglrnd (1)
%!error<loglrnd: A and B must be of common size or scalars.> ...
%! loglrnd (ones (3), ones (2))
%!error<loglrnd: A and B must be of common size or scalars.> ...
%! loglrnd (ones (2), ones (3))
%!error<loglrnd: A and B must not be complex.> loglrnd (i, 2, 3)
%!error<loglrnd: A and B must not be complex.> loglrnd (1, i, 3)
%!error<loglrnd: SZ must be a scalar or a row vector of non-negative integers.> ...
%! loglrnd (1, 2, -1)
%!error<loglrnd: SZ must be a scalar or a row vector of non-negative integers.> ...
%! loglrnd (1, 2, 1.2)
%!error<loglrnd: SZ must be a scalar or a row vector of non-negative integers.> ...
%! loglrnd (1, 2, ones (2))
%!error<loglrnd: SZ must be a scalar or a row vector of non-negative integers.> ...
%! loglrnd (1, 2, [2 -1 2])
%!error<loglrnd: SZ must be a scalar or a row vector of non-negative integers.> ...
%! loglrnd (1, 2, [2 0 2.5])
%!error<loglrnd: dimensions must be non-negative integers.> ...
%! loglrnd (1, 2, 2, -1, 5)
%!error<loglrnd: dimensions must be non-negative integers.> ...
%! loglrnd (1, 2, 2, 1.5, 5)
%!error<loglrnd: A and B must be scalars or of size SZ.> ...
%! loglrnd (2, ones (2), 3)
%!error<loglrnd: A and B must be scalars or of size SZ.> ...
%! loglrnd (2, ones (2), [3, 2])
%!error<loglrnd: A and B must be scalars or of size SZ.> ...
%! loglrnd (2, ones (2), 3, 2)
