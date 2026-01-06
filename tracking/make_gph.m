function gph = make_gph(Pts, Eg)
% make gph from Pts and edges in the graph
% this will be used later by some methods as input for graph matching
%
% Input
%   Pts         -   Pts in the graph 3 x n
%   Eg          -   Edges in the graph 2 x (2m)
%
% Output
%   gph         -   gph structure
%       Pts     -   Pts in gph
%       G       -   node incidence matrix (starting point) 2 x (2m)
%       H       -   node incidence matrix (ending point) 2 x (2m)


gph  = struct();
gph.Pts = Pts;
n = size(Pts,1);

G = zeros(n,size(Eg,2));
H = zeros(n,size(Eg,2));
for i = 1:size(Eg,2)
    G(Eg(1,i),i) = 1;
    H(Eg(2,i),i) = 1;
end
gph.G = G;
gph.H = H;

% edge vector
Pt1 = Pts(Eg(1, :),:);
Pt2 = Pts(Eg(2, :),:);
PtD = Pt1 - Pt2;
% distance
dsts = real(sqrt(sum(PtD .^ 2, 2)));
gph.dsts = dsts;
end
    