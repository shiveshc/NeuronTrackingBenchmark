%%%% function for CRF based tracking of source and target sets
%%%% Changes - 
%%%% 1. Geodesic distance based edge potentials
%%%% 2. log linear hard edge potentials
%%%% 3. Handle duplicates
%%%%    3a. Reassign all duplicate nodes
%%%%    3b. Form graph structure of all nodes, change potential so that
%%%%    unassigned nodes can be assigned unassigned labels, clamp potential
%%%%    for assigned nodes
%%%% 4. Hide landmarks and check their predicted identities
%%%% 5. Node potential based on normalized distance along PA
%%%% 6. Relative angle based edge-potentials

function [node_label, lambda_PA, lambda_LR, lambda_DV, lambda_angle, loc_sigma] = CRF_track(PA_matrix, LR_matrix, DV_matrix, source, target, lambdas)

X = target(:,1);
Y = target(:,2);
Z = target(:,3);
X_norm = (X-min(X))/(max(X)-min(X));

X_src = source(:,1);
Y_src = source(:,2);
Z_src = source(:,3);
X_src_norm = (X_src-min(X_src))/(max(X_src)-min(X_src));


addpath(genpath('D:\Shivesh\OptimalTransport\annotation\UGM'))
% addpath(genpath('/storage/coda1/p-hl94/0/schaudhary9/rich_project_pchbe2/Annotation/ParameterSearch/UGM'))

%%% create node and edge potential
adj = ones(size(target,1),size(target,1)); % fully connected graph structure of CRF
adj = adj - diag(diag(adj));
nStates = size(PA_matrix,1);
nNodes = size(target,1);
edgeStruct = UGM_makeEdgeStruct(adj,nStates);

node_pot =  ones(nNodes,nStates);
loc_sigma = 0;

% loc_sigma = 0.2;
% node_pot = zeros(nNodes,nStates);
% for i = 1:nNodes
%     node_pot(i,:) = diag(exp(-((ones(size(X_src_norm))*X_norm(i,1) - X_src_norm)*(ones(size(X_src_norm))*X_norm(i,1) - X_src_norm)')/(2*loc_sigma^2)))';
% end

orig_node_pot = node_pot;


lambda_PA = lambdas(1,1);
lambda_LR = lambdas(1,2);
lambda_DV = lambdas(1,3);
lambda_geo = lambdas(1,4);
lambda_angle = lambdas(1,5);
edge_pot = zeros(nStates, nStates, edgeStruct.nEdges);
orig_edge_pot = zeros(nStates, nStates, edgeStruct.nEdges);
for i = 1:edgeStruct.nEdges
    node1 = edgeStruct.edgeEnds(i,1);
    node2 = edgeStruct.edgeEnds(i,2);
    angle_matrix = get_relative_angles(X_src,Y_src,Z_src,X,Y,Z,node1,node2);
    if X(node1,1) < X(node2,1)
        if Y(node1,1) < Y(node2,1)
            if Z(node1,1) < Z(node2,1)
                pot = exp(lambda_PA*PA_matrix).*exp(lambda_DV*DV_matrix).*exp(lambda_LR*LR_matrix).*exp(lambda_angle*angle_matrix);
            else
                pot = exp(lambda_PA*PA_matrix).*exp(lambda_DV*DV_matrix').*exp(lambda_LR*LR_matrix).*exp(lambda_angle*angle_matrix);
            end
        else
            if Z(node1,1) < Z(node2,1)
                pot = exp(lambda_PA*PA_matrix).*exp(lambda_DV*DV_matrix).*exp(lambda_LR*LR_matrix').*exp(lambda_angle*angle_matrix);
            else
                pot = exp(lambda_PA*PA_matrix).*exp(lambda_DV*DV_matrix').*exp(lambda_LR*LR_matrix').*exp(lambda_angle*angle_matrix);
            end
        end
    else
        if Y(node1,1) < Y(node2,1)
            if Z(node1,1) < Z(node2,1)
                pot = exp(lambda_PA*PA_matrix').*exp(lambda_DV*DV_matrix).*exp(lambda_LR*LR_matrix).*exp(lambda_angle*angle_matrix);
            else
                pot = exp(lambda_PA*PA_matrix').*exp(lambda_DV*DV_matrix').*exp(lambda_LR*LR_matrix).*exp(lambda_angle*angle_matrix);
            end
        else
            if Z(node1,1) < Z(node2,1)
                pot = exp(lambda_PA*PA_matrix').*exp(lambda_DV*DV_matrix).*exp(lambda_LR*LR_matrix').*exp(lambda_angle*angle_matrix);
            else
                pot = exp(lambda_PA*PA_matrix').*exp(lambda_DV*DV_matrix').*exp(lambda_LR*LR_matrix').*exp(lambda_angle*angle_matrix);
            end
        end
    end
    orig_edge_pot(:, :, i) = pot;
    pot(find(pot<0.01)) = 0.001; %  small potential of incompatible matches
    pot = pot - diag(diag(pot)) + 0.001*eye(size(pot,1)); 
    edge_pot(:, :, i) = pot;
end

% set landmark information if available
clamped = zeros(nNodes,1);
clamped_neurons = [];


[nodeBel,edgeBel,logZ] = UGM_Infer_Conditional(node_pot,edge_pot,edgeStruct,clamped,@UGM_Infer_LBP);
% conserved_nodeBel = nodeBel; %node belief matrix to maintain marginal probabilities after clamping in subsequent steps
% optimal_decode = UGM_Decode_Conditional(node_pot,edge_pot,edgeStruct,clamped,@UGM_Decode_LBP);
[sort_nodeBel,nodeBel_sort_index] = sort(nodeBel,2,'descend');
curr_labels = nodeBel_sort_index(:,1);
% curr_labels = optimal_decode;
[PA_score,LR_score,DV_score,tot_score] = consistency_scores(nNodes,curr_labels,X,Y,Z,PA_matrix,LR_matrix,DV_matrix);
node_label = curr_labels;

%%% handle duplicate assignments 
node_label = duplicate_labels(curr_labels,X,Y,Z,PA_matrix,LR_matrix,DV_matrix,clamped_neurons);
cnt = 2;
while find(node_label(:,1) == 0)
    assigned_nodes = find(node_label(:,1) ~= 0);
    assigned_labels = node_label(node_label(:,1) ~= 0,1);
    unassigned_nodes = find(node_label(:,1) == 0);
    
    node_pot = orig_node_pot;
    node_pot(unassigned_nodes,assigned_labels) = 0;
    node_pot(find(node_pot<0.01)) = 0.001;
    
    edge_pot = zeros(nStates,nStates,edgeStruct.nEdges);
    for i = 1:size(edgeStruct.edgeEnds,1)
        node1 = edgeStruct.edgeEnds(i,1);
        node2 = edgeStruct.edgeEnds(i,2);
        pot = orig_edge_pot(:, :, i);
        if node_label(node1,1) == 0 && node_label(node2,1) == 0 % unassigned-unassigned nodes
            pot(assigned_labels,assigned_labels) = 0;
        elseif node_label(node1,1) == 0 && node_label(node2,1) ~= 0 % unassigned-assigned nodes
            pot(assigned_labels,:) = 0;
        elseif node_label(node1,1) ~= 0 && node_label(node2,1) == 0 % assigned-unassigned nodes
            pot(:,assigned_labels) = 0;
        else
        end 
        pot(find(pot<0.01)) = 0.001; %  small potential of incompatible matches
        pot = pot - diag(diag(pot)) + 0.001*eye(size(pot,1));
        edge_pot(:,:,i) = pot;
    end
    
    clamped = zeros(nNodes,1);
    clamped(assigned_nodes) = assigned_labels;
    
    [nodeBel,edgeBel,logZ] = UGM_Infer_Conditional(node_pot,edge_pot,edgeStruct,clamped,@UGM_Infer_LBP);
    conserved_nodeBel(unassigned_nodes,:) = nodeBel(unassigned_nodes,:);
    [sort_nodeBel,nodeBel_sort_index] = sort(nodeBel,2,'descend');
    
    curr_labels = nodeBel_sort_index(:,1);
    [PAscore,LRscore,DVscore,totscore] = consistency_scores(nNodes,curr_labels,X,Y,Z,PA_matrix,LR_matrix,DV_matrix);
    PA_score(:,cnt) = PAscore;
    LR_score(:,cnt) = LRscore;
    DV_score(:,cnt) = DVscore;
    tot_score(:,cnt) = totscore;
    
    node_label = duplicate_labels(curr_labels,X,Y,Z,PA_matrix,LR_matrix,DV_matrix,clamped_neurons);
    cnt = cnt + 1;
    if cnt > 3
        break
    end
end
end