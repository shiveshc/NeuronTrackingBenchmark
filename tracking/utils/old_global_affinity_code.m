%                 for n = 1:size(nodes,2)
%                     for m  = n:size(labels,2)
%                         % make M
%                         tic
%                         if nodes(n) == nodes(m) && labels(n) == labels(m)
%                             %unary_pot
%                         elseif nodes(n) == nodes(m)
%                             edge_pot = 0;
%                             M(n,m) = edge_pot;
%                             M(m,n) = M(n,m);
%                         elseif labels(n) == labels(m)
%                             edge_pot = 0;
%                             M(n,m) = edge_pot;
%                             M(m,n) = M(n,m);
%                         else
%                             if PA_matrix(nodes(n),nodes(m)) == PA_matrix_src(labels(n),labels(m))
%                                 edge_pot_PA = 1;
%                             else
%                                 edge_pot_PA = 0;
%                             end
%                             if LR_matrix(nodes(n),nodes(m)) == LR_matrix_src(labels(n),labels(m))
%                                 edge_pot_LR = 1;
%                             else
%                                 edge_pot_LR = 0;
%                             end
%                             if DV_matrix(nodes(n),nodes(m)) == DV_matrix_src(labels(n),labels(m))
%                                 edge_pot_DV = 1;
%                             else
%                                 edge_pot_DV = 0;
%                             end
%                             pos = [target(nodes(n),:);target(nodes(m),:)];
%                             pos_src = [source(labels(n),:);source(labels(m),:)];
%                             angle_matrix = get_relative_angles(pos_src(:,1),pos_src(:,2),pos_src(:,3),pos(:,1),pos(:,2),pos(:,3),1,2);
%                             edge_pot_angle = angle_matrix(1,2);
%                             
%                             M(n,m) = edge_pot_PA + edge_pot_LR + edge_pot_DV + edge_pot_angle;
%                             M(m,n) = M(n,m);
%                         end
%                         M_t2 = M_t2 + toc;
%                         
%                         % make K
%                         tic
%                         if nodes_K(n) == nodes_K(m) && labels_K(n) == labels_K(m)
%                             %unary_pot
%                         elseif nodes_K(n) == nodes_K(m)
%                             edge_pot = 0;
%                             K(n,m) = edge_pot;
%                             K(m,n) = K(n,m);
%                         elseif labels_K(n) == labels_K(m)
%                             edge_pot = 0;
%                             K(n,m) = edge_pot;
%                             K(m,n) = K(n,m);
%                         else
%                             if PA_matrix(nodes_K(n),nodes_K(m)) == PA_matrix_src(labels_K(n),labels_K(m))
%                                 edge_pot_PA = 1;
%                             else
%                                 edge_pot_PA = 0;
%                             end
%                             if LR_matrix(nodes_K(n),nodes_K(m)) == LR_matrix_src(labels_K(n),labels_K(m))
%                                 edge_pot_LR = 1;
%                             else
%                                 edge_pot_LR = 0;
%                             end
%                             if DV_matrix(nodes_K(n),nodes_K(m)) == DV_matrix_src(labels_K(n),labels_K(m))
%                                 edge_pot_DV = 1;
%                             else
%                                 edge_pot_DV = 0;
%                             end
%                             pos = [target(nodes_K(n),:);target(nodes_K(m),:)];
%                             pos_src = [source(labels_K(n),:);source(labels_K(m),:)];
%                             angle_matrix = get_relative_angles(pos_src(:,1),pos_src(:,2),pos_src(:,3),pos(:,1),pos(:,2),pos(:,3),1,2);
%                             edge_pot_angle = angle_matrix(1,2);
%                             
%                             K(n,m) = edge_pot_PA + edge_pot_LR + edge_pot_DV + edge_pot_angle;
%                             K(m,n) = K(n,m);
%                         end
%                         K_t2 = K_t2 + toc;
%                         
%                     end    
%                 end