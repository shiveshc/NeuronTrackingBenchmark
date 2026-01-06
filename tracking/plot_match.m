%%% function to plot matchings in each iteration in wasserstein barycenter
%%% code

function plot_match(X,Y,T)
    figure,scatter(X(1,:),X(3,:),'.b')
    hold on
    scatter(Y(1,:),Y(3,:),'.r')
    for n = 1:size(X,2)
        [prob,curr_match] = sort(T(n,:),'descend');
        plot([X(1,n),Y(1,curr_match(1,1))],[X(3,n),Y(3,curr_match(1,1))],'color','k')
    end
end