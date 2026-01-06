%%% algorithm 1 from the paper "Fast computation of wasserstein
%%% barycenters"

function [a] = wass_algo1(alpha_star)
    t0 = 5;
    t = t0;
    max_iter = 100;
    iter = 1;
    a_tilda = 1/size(alpha_star,1)*ones(size(alpha_star,1),1);
    a_hat = a_tilda;
    while iter < max_iter
        beta = (t+1)/2;
        a = (1 - 1/beta)*a_hat + 1/beta*a_tilda;
        alpha = mean(alpha_star,2);
        a_tilda = a_tilda.*exp(-t0*beta*alpha);
        a_tilda = a_tilda/sum(a_tilda);
        a_hat = (1 - 1/beta)*a_hat + 1/beta*a_tilda;
        t = t + 1;
        
        iter = iter + 1;
    end
end