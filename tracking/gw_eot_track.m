%%%% function for gw_eot track of source and target sets

function [curr_labels, lambda_PA, lambda_LR, lambda_DV, lambda_angle, alpha] = gw_eot_track(PA_matrix_src, LR_matrix_src, DV_matrix_src, PA_matrix, LR_matrix, DV_matrix, source, target)

X = target(:,1);
Y = target(:,2);
Z = target(:,3);
X_norm = (X-min(X))/(max(X)-min(X));

X_src = source(:,1);
Y_src = source(:,2);
Z_src = source(:,3);
X_src_norm = (X_src-min(X_src))/(max(X_src)-min(X_src));

N = size(X,1);
M = size(X_src,1);
one_N = ones(N,1);
one_M = ones(M,1);
p = 1/N*one_N;
q = 1/M*one_M;
T = p*q';


%%% define linear cost
loc_sigma = 0.2;
mu = [X,Y,Z];
l2_distance  = repmat(diag(X_norm*X_norm'),1,size(X_src_norm,1)) + repmat(diag(X_src_norm*X_src_norm')',size(X_norm,1),1) - 2*X_norm*X_src_norm';
% l2_distance  = repmat(diag(mu*mu'),1,size(mu_r,1)) + repmat(diag(mu_r*mu_r')',size(mu,1),1) - 2*mu*mu_r';
l2_C = l2_distance;

%%% define quadratic cost
C_PA = PA_matrix;
C_prime_PA = PA_matrix_src;

C_LR = LR_matrix;
C_prime_LR = LR_matrix_src;

C_DV = DV_matrix;
C_prime_DV = DV_matrix_src;

% tic
% L_angle = zeros(size(X,1),size(X,1),size(X_src,1),size(X_src,1));
% for i = 1:size(X,1)
%     for k = i:size(X,1)
%         if i == k
%             L_angle(i,k,:,:) = 1;
%         else
%             pi = [X(i,1),Y(i,1),Z(i,1)];
%             pk = [X(k,1),Y(k,1),Z(k,1)];
%             angle_matrix = zeros(size(X_src,1),size(X_src,1));
%             for j = 1:size(X_src,1)
%                 for l = j:size(X_src,1)
%                     if j==l
%                         angle_matrix(j,l) = 1;
%                     else
%                         pj = [X_src(j,1),Y_src(j,1),Z_src(j,1)];
%                         pl = [X_src(l,1),Y_src(l,1),Z_src(l,1)];
%                         angle_matrix(j,l) = - (pj-pl)*(pi-pk)'/(norm(pj-pl)*norm(pi-pk));
%                         angle_matrix(l,j) = (pj-pl)*(pi-pk)'/(norm(pj-pl)*norm(pi-pk));
%                     end
%                 end
%             end
%             L_angle(i,k,:,:) = angle_matrix;
%             L_angle(k,i,:,:) = angle_matrix';
%         end
%     end
% end
% toc

%%% optimize
epsilon = 0.01;
max_iter1 = 1000;
max_iter2 = 10;
alpha = 0.75;
lambda_PA = 1;
lambda_LR = 1;
lambda_DV = 1;
lambda_angle = 0;

curr_iter2 = 1;
while curr_iter2 < max_iter2
    Q_PA = (C_PA.^2)*p*one_M' + one_N*q'*(C_prime_PA.^2)' - C_PA*T*(2*C_prime_PA');
    Q_LR = (C_LR.^2)*p*one_M' + one_N*q'*(C_prime_LR.^2)' - C_LR*T*(2*C_prime_LR');
    Q_DV = (C_DV.^2)*p*one_M' + one_N*q'*(C_prime_DV.^2)' - C_DV*T*(2*C_prime_DV');
%     Q_angle = zeros(size(T));
%     for i = 1:size(Q_angle,1)
%         for j = 1:size(Q_angle,2)
%             temp = permute(L_angle(i,:,j,:),[2,4,1,3]);
%             Q_angle(i,j) = temp(:)'*T(:);
%         end
%     end
    
    K = exp(-(alpha*l2_C + (1-alpha)*(lambda_PA*Q_PA+lambda_LR*Q_LR+lambda_DV*Q_DV))/epsilon);
    b = ones(M,1);
    curr_iter1 = 1;
    while curr_iter1<max_iter1
        a = p./(K*b);
        b = q./(K'*a);
        curr_iter1 = curr_iter1 + 1;
    end
    T = diag(a)*K*diag(b);
    curr_iter2 = curr_iter2 + 1;
end

[sort_nodeBel,nodeBel_sort_index] = sort(T,2,'descend');
curr_labels = nodeBel_sort_index(:,1);
% figure,scatter(X,Z,'b')
% hold on
% scatter(X_src,Z_src,'r')
% for n = 1:size(X,1)
%     plot([X(n,1),X_src(curr_labels(n,1),1)],[Z(n,1),Z_src(curr_labels(n,1),1)],'color','k')
% end
end




