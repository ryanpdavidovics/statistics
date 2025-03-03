## Copyright (C) 2013-2019 Nir Krakauer <mail@nirkrakauer.net>
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
## @deftypefn  {statistics} {[@var{W}, @var{D}] =} wishrnd (@var{Sigma}, @var{df}, @var{D}, @var{n}=1)
##
## Return a random matrix sampled from the Wishart distribution with given
## parameters
##
## Inputs: the @math{p x p} positive definite matrix @var{Sigma} (or the
## lower-triangular Cholesky factor @var{D} of @var{Sigma}) and scalar degrees
## of freedom parameter @var{df}.
##
## @var{df} can be non-integer as long as @math{@var{df} > p}
##
## Output: a random @math{p x p}  matrix @var{W} from the
## Wishart(@var{Sigma}, @var{df}) distribution. If @var{n} > 1, then @var{W} is
## @var{p} x @var{p} x @var{n} and holds @var{n} such random matrices.
## (Optionally, the lower-triangular Cholesky factor @var{D} of @var{Sigma} is
## also returned.)
##
## Averaged across many samples, the mean of @var{W} should approach
## @var{df}*@var{Sigma}, and the variance of each element @var{W}_ij should
## approach @var{df}*(@var{Sigma}_ij^2 + @var{Sigma}_ii*@var{Sigma}_jj)
##
## @subheading References
##
## @enumerate
## @item
## Yu-Cheng Ku and Peter Bloomfield (2010), Generating Random Wishart Matrices
## with Fractional Degrees of Freedom in OX,
## http://www.gwu.edu/~forcpgm/YuChengKu-030510final-WishartYu-ChengKu.pdf
## @end enumerate
##
## @seealso{wishpdf, iwishpdf, iwishrnd}
## @end deftypefn

function [W, D] = wishrnd (Sigma, df, D, n=1)

  if (nargin < 2)
    print_usage ();
  endif

  if nargin < 3 || isempty(D)
    try
      D = chol(Sigma, 'lower');
    catch
      error (strcat (["iwishrnd: Cholesky decomposition failed;"], ...
                     [" SIGMA probably not positive definite."]));
    end_try_catch
  endif

  p = size(D, 1);

  if df < p
    df = floor(df); #distribution not defined for small noninteger df
    df_isint = 1;
  else
  #check for integer degrees of freedom
   df_isint = (df == floor(df));
  endif

  if ~df_isint
    [ii, jj] = ind2sub([p, p], 1:(p*p));
  endif

  if n > 1
    W = nan(p, p, n);
  endif

  for i = 1:n
    if df_isint
      Z = D * randn(p, df);
    else
      Z = diag(sqrt(chi2rnd(df - (0:(p-1))))); #fill diagonal
      ##note: chi2rnd(x) is equivalent to 2*randg(x/2), but the latter seems to
      ## offer no performance advantage
      Z(ii > jj) = randn(p*(p-1)/2, 1); #fill lower triangle
      Z = D * Z;
    endif
    W(:, :, i) = Z*Z';
  endfor
endfunction


%!assert(size (wishrnd (1,2)), [1, 1]);
%!assert(size (wishrnd (1,2,[])), [1, 1]);
%!assert(size (wishrnd (1,2,1)), [1, 1]);
%!assert(size (wishrnd ([],2,1)), [1, 1]);
%!assert(size (wishrnd ([3 1; 1 3], 2.00001, [], 1)), [2, 2]);
%!assert(size (wishrnd (eye(2), 2, [], 3)), [2, 2, 3]);

%% Test input validation
%!error wishrnd ()
%!error wishrnd (1)
%!error wishrnd ([1; 1], 2)
