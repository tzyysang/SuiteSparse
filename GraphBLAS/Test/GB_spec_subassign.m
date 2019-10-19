function C = GB_spec_subassign (C, Mask, accum, A, I, J, descriptor, scalar)
%GB_SPEC_SUBASSIGN a MATLAB mimic of GrB_subassign
%
% Usage:
% C = GB_spec_subassign (C, Mask, accum, A, I, J, descriptor, scalar)
%
% Computes C(I,J)<Mask> = accum(C(I,J),A), in GraphBLAS notation.
%
% This function does the same thing as GrB_Matrix_subassign,
% GrB_Vector_subassign, GrB_Matrix_subassign_TYPE, GrB_Vector_subassign_TYPE,
% GrB_Row_subassign, and GrB_Col_subassign functions.  In all cases, the Mask
% is the same size as A (after optionally being transpose) and the submatrix
% C(I,J).  Entries outside the C(I,J) submatrix are never modified.

% SuiteSparse:GraphBLAS, Timothy A. Davis, (c) 2017, All Rights Reserved.
% http://suitesparse.com   See GraphBLAS/Doc/License.txt for license.

%-------------------------------------------------------------------------------
% get inputs
%-------------------------------------------------------------------------------

if (nargout > 1 || nargin ~= 8)
    error ('usage: C = GB_spec_subassign (C, Mask, accum, A, I, J, descriptor, scalar)') ;
end

% Convert inputs to dense matrices with explicit patterns and classes,
% and with where X(~X.pattern)==identity for all matrices A, B, and C.
C = GB_spec_matrix (C) ;
A = GB_spec_matrix (A) ;

% Mask is a dense logical matrix, not a struct
Mask = GB_mex_cast (full (Mask), 'logical') ;
[C_replace Mask_comp Atrans ignore] = GB_spec_descriptor (descriptor) ;

%-------------------------------------------------------------------------------

% apply the descriptor to A
if (Atrans)
    A.matrix = A.matrix' ;
    A.pattern = A.pattern' ;
end

% expand I and J if empty
if (isempty (I))
    nrows = size (C.matrix, 1) ;
    I = 1:nrows ;
end
if (isempty (J))
    ncols = size (C.matrix, 2) ;
    J = 1:ncols ;
end

if (scalar)
    % scalar expansion: expand A into a matrix
    ni = length (I) ;
    nj = length (J) ;
    A.matrix  (1:ni, 1:nj) = A.matrix (1,1) ;
    A.pattern (1:ni, 1:nj) = true ;
end

S.matrix  = C.matrix  (I,J)  ;
S.pattern = C.pattern (I,J)  ;
S.class   = C.class  ;

% T = A
T.matrix  = A.matrix ;
T.pattern = A.pattern ;

% S<Mask> = accum (S,T): apply the accum, then Mask, and return the result
S = GB_spec_accum_mask (S, Mask, accum, T, C_replace, Mask_comp, 0) ;

C.matrix  (I,J) = S.matrix  ;
C.pattern (I,J) = S.pattern  ;
C.class         = S.class  ;
