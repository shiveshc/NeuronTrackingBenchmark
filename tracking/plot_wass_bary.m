%%% function to plot iterations of wasserstein barycenter

function plot_wass_bary(X,X_new,Y,loss)
    figure
    for i = 1:size(Y,2)
        Y_i = Y{1,i};
        scatter(Y_i(:,1),Y_i(:,3),'.g')
        hold on
    end
    scatter(X(1,:),X(3,:),'.r')
    scatter(X_new(1,:),X_new(3,:),'.b')
    title(loss)
end