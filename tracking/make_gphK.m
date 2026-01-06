function [K, M] = make_gphK(KP, KQ, Eg1, Eg2)
% Make global affinity matrices K and M
% Input
%     KP      -   node-affinity n1 x n2
%     KQ      -   edge-affinity m1 x m2
%     Eg1     -   target graph edges 2 x m1
%     Eg2     -   source graph edges 2 x m2
%     
% Output
%     K       -   global affinity matrix nn x nn (11, 21, 31, .... etc.)
%     M       -   global affinity matrix nn x nn (11, 12, 14, .... etc.)


[n1,n2] = size(KP);
[m1,m2] = size(KQ);
nn = n1*n2;

% make K for FGM and KerGM methods
I11 = repmat(Eg1(1,:)',1,m2);
I21 = repmat(Eg2(1,:),m1,1);
I12 = repmat(Eg1(2,:)',1,m2);
I22 = repmat(Eg2(2,:),m1,1);
idx1 = sub2ind([n1,n2],I11(:),I21(:));
idx2 = sub2ind([n1,n2],I12(:),I22(:));
vals = KQ(:);
K = zeros(nn,nn);
id = sub2ind(size(K),idx1,idx2);
K(id) = vals;
K = K + diag(KP(:));


% make M for Leordeanu methods
I11 = repmat(Eg1(1,:),m2,1);
I21 = repmat(Eg2(1,:)',1,m1);
I12 = repmat(Eg1(2,:),m2,1);
I22 = repmat(Eg2(2,:)',1,m1);
idx1 = sub2ind([n2,n1],I21(:),I11(:));
idx2 = sub2ind([n2,n1],I22(:),I12(:));
KQ_flip = permute(KQ,[2,1]);
vals = KQ_flip(:);
M = zeros(nn,nn);
id = sub2ind(size(M),idx1,idx2);
M(id) = vals;
KP_flip = permute(KP,[2,1]);
M = M + diag(KP_flip(:));
