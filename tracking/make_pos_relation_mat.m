%%% function to make position relationship matrices of source set for tracking
%%% cells in video using CRF

function [PA_matrix,LR_matrix,DV_matrix] = make_pos_relation_mat(source)
PA_matrix = zeros(size(source,1),size(source,1));
LR_matrix = zeros(size(source,1),size(source,1));
DV_matrix = zeros(size(source,1),size(source,1));
for i = 1:size(source,1)
    anterior = find(source(i,1) < source(:,1));
    PA_matrix(i,anterior) = 1;
    right = find(source(i,2) < source(:,2));
    LR_matrix(i,right) = 1;
    ventral = find(source(i,3) < source(:,3));
    DV_matrix(i,ventral) = 1;
end