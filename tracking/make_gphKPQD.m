function [KP, KQ] = make_gphKPQD(n1, n2, Eg1, Eg2, target, source, PA_matrix, LR_matrix, DV_matrix, PA_matrix_src, LR_matrix_src, DV_matrix_src, lambdas)
% make node-affinity and edge affinity matrices
% Inputs
%     n1          -   num nodes in target gph
%     n2          -   num nodes in source gph
%     Eg1         -   edges in target gph
%     Eg2         -   edges in source gph
%     target      -   target points
%     source      -   source points
%     PA_matrix   -   target PA matrix
%     LR_matrix   -   target LR matrix
%     DV_matrix   -   target DV matrix
%     PA_matrix_src   -   source PA matrix
%     LR_matrix_src   -   source LR matrix
%     DV_matrix_src   -   source DV matrix
%     
% Outputs
%     KP      -   node-affinity n1 x n2
%     KQ      -   edge-affinity m1 x m2



% node-affinity (unary potential)
% can be replaced by registration based or any other feature based affinity
KP = zeros(n1,n2);


% edge-affinity (pairwise potential)
m1 = size(Eg1,2);
m2 = size(Eg2,2);
KQ = zeros(m1,m2);
for i = 1:m1/2
    for j = 1:m2/2
        if PA_matrix(Eg1(1,i),Eg1(2,i)) == PA_matrix_src(Eg2(1,j),Eg2(2,j))
            edge_pot_PA = 1;
        else
            edge_pot_PA = 0;
        end
        if LR_matrix(Eg1(1,i),Eg1(2,i)) == LR_matrix_src(Eg2(1,j),Eg2(2,j))
            edge_pot_LR = 1;
        else
            edge_pot_LR = 0;
        end
        if DV_matrix(Eg1(1,i),Eg1(2,i)) == DV_matrix_src(Eg2(1,j),Eg2(2,j))
            edge_pot_DV = 1;
        else
            edge_pot_DV = 0;
        end
        pos = [target(Eg1(1,i),:);target(Eg1(2,i),:)];
        pos_src = [source(Eg2(1,j),:);source(Eg2(2,j),:)];
        angle_matrix = get_relative_angles(pos_src(:,1),pos_src(:,2),pos_src(:,3),pos(:,1),pos(:,2),pos(:,3),1,2);
        edge_pot_angle = angle_matrix(1,2);
        
        KQ(i,j) = lambdas(1,1)*edge_pot_PA + lambdas(1,2)*edge_pot_LR + lambdas(1,3)*edge_pot_DV + lambdas(1,4)*edge_pot_angle;
        KQ(i + m1/2, j + m2/2) = lambdas(1,1)*edge_pot_PA + lambdas(1,2)*edge_pot_LR + lambdas(1,3)*edge_pot_DV + lambdas(1,4)*edge_pot_angle;
        KQ(i + m1/2, j) = lambdas(1,1)*(1 - edge_pot_PA) + lambdas(1,2)*(1 - edge_pot_LR) + lambdas(1,3)*(1 - edge_pot_DV) + lambdas(1,4)*(-edge_pot_angle);
        KQ(i, j + m2/2) = lambdas(1,1)*(1 - edge_pot_PA) + lambdas(1,2)*(1 - edge_pot_LR) + lambdas(1,3)*(1 - edge_pot_DV) + lambdas(1,4)*(-edge_pot_angle);
    end
end
