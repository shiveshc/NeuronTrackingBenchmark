function Eg = make_edges(n)
% make edges of a graph depending on graph structure
% Inputs
%     n       -   num nodes in gph
%    
% Output
%     Eg      -   gph edges 2 x m
%     
    
    
% fully connected
num_undirected_edges = n*(n-1)/2;
Eg = zeros(2,num_undirected_edges);
cnt = 1;
for i = 1:n
    for j = i+1:n
        Eg(:,cnt) = [i;j];
        cnt = cnt + 1;
    end
end
Eg = cat(2,Eg,Eg([2,1],:));
    