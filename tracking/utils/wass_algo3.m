%%% algorithm 3 from the paper "Fast computation of wasserstein
%%% barycenters"

function [T_i,alpha_i,loss] = wass_algo3(a,b,M,iter)
    lambda0 = 100000;
    lambda = lambda0;
    
    K = exp(-lambda*M);
    K(K < 1e-100) = 1e-100;
    K_tilda = diag(1./a)*K;
    K_tilda(K_tilda < 1e-100) = 1e-100;
    
    u = 1/size(a,1)*ones(size(a,1),1);

    max_iter = 1000;
    iter = 1;
    tol = 1e-3;
    u_new = 1./(K_tilda*(b./(K'*u)));
    while sum(abs(u-u_new)./u) > tol && iter < max_iter
        u = u_new;
        u_new = 1./(K_tilda*(b./(K'*u)));
        iter = iter + 1;
    end
    v = b./(K'*u_new);
    alpha_i = -1/lambda*log(u) + 1/(lambda*size(u,1))*(log(u)'*ones(size(u,1),1))*ones(size(u,1),1);
    T_i = diag(u)*K*diag(v);
    
    h_T = -sum(sum(T_i.*log(T_i)));
    loss = trace(T_i'*M) - 1/lambda*h_T;
end