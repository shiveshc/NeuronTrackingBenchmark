%%% algorithm 3 from the paper "Fast computation of wasserstein
%%% barycenters" modified for fused gromov-wasserstein

function [T,alpha_i,loss] = gromov_wass_algo3(a,b,M_i,C,C_prime,iter)
    lambda0 = 1000;
    lambda = lambda0;
    
    N = size(a,1);
    M = size(b,1);
    one_N = ones(N,1);
    one_M = ones(M,1);
    p = 1/N*one_N;
    q = 1/M*one_M;
    T = p*q';
    
    C_PA = C(:,:,1); C_LR = C(:,:,2); C_DV = C(:,:,3);
    C_prime_PA = C_prime(:,:,1); C_prime_LR = C_prime(:,:,2); C_prime_DV = C_prime(:,:,3);
    
    max_iter1 = 100;
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
        
        K = exp(-lambda*(alpha*M_i + (1-alpha)*(lambda_PA*Q_PA+lambda_LR*Q_LR+lambda_DV*Q_DV)));
        K(K < 1e-100) = 1e-100;
        b = ones(M,1);
        curr_iter1 = 1;
        while curr_iter1<max_iter1
            a = p./(K*b);
            b = q./(K'*a);
            curr_iter1 = curr_iter1 + 1;
        end
        T = diag(a)*K*diag(b);
        alpha_i = -1/lambda*log(a) + 1/(lambda*size(a,1))*(log(a)'*ones(size(a,1),1))*ones(size(a,1),1);
        curr_iter2 = curr_iter2 + 1;
        
        h_T = -sum(sum(T.*log(T)));
        loss = 0;
    end
end