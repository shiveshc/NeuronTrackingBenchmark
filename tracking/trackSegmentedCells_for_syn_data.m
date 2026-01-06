function [allCenters,regCenters,guesses,discrepancies]=trackSegmentedCells_for_syn_data(rootName,segNorm1,allCenters,allImg,refFrame,skipCells,writeVideoBool)

%there are very few meaningful free parameters here. Most are just below,
%but I haven't seen much of a change without picking ridiculous parameters.

% Init full set of options %%%%%%%%%% %If necessary, include these are
% arguments to allow changing the parameters
opt.method='nonrigid'; % use nonrigid registration
opt.beta=3;            % the width of Gaussian kernel (smoothness)
opt.lambda=3;          % regularization weight

opt.viz=0;              % DON't show every iteration
opt.outliers=0.3;       % Noise weight
opt.fgt=0;              % do not use FGT (default)
opt.normalize=1;        % normalize to unit variance and zero mean before registering (default)
opt.corresp=1;          % compute correspondence vector at the end of registration (not being estimated by default)

opt.max_it=100;         % max number of iterations
opt.tol=1e-10;          % tolerance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%TODO: !!!!!!!
%Zimmer's Videos are 2 um z-slices, with 170/513 pixel dimension (~0.3314
%um/pixel). Possibly compensate for this.

disp('Phase II (Tracking)...')
numFrames=size(allCenters,2);
videoName=[rootName '.avi'];
maxVidValue= 0; %maximum value in video, useful for making video
prevCENTERS=reshape([allCenters{refFrame}.Centroid],3,[]);
numObj=numel(allCenters{refFrame});

if writeVideoBool %initialize video, if desired
    disp('Writing Video!')
    v = VideoWriter(videoName); 
    v.FrameRate=15; %default Framerate is 30
    open(v)
end

regCenters=zeros(3,numObj,numFrames); %This stores the registered Centers (including estimates)
% maxInt=zeros(numObj,numFrames); %This stores the local maximum intensity in each blob
% meanInt=zeros(numObj,numFrames);
% mean20Int=zeros(numObj,numFrames);
guesses=false(numObj,numFrames); %this stores which centers were guessed

discrepancies=NaN*ones(1,numFrames); %This stores discrepancy count

for x=1:numFrames
%     act1=double(allImg(:,:,:,x));
%     thisShow=max(act1,[],3); %3d display is hard, maybe I can get away with using projection
%     meanThisFrame=mean(act1(:)); %simple background correction
%     backInts(x)=meanThisFrame;
    
    tempCENTERS=reshape([allCenters{x}.Centroid],3,[]); 
    if numel(tempCENTERS)<10 %a rarity, but relevant if the worm goes offscreen or something crazy happens
        %Just copy everything from the previous frame, but make sure to
        %note that everything is a guess
        guesses(:,x)=1;
        %CENTERS is implicitly carried forward
    else
        if x>1
            oldCENTERS=CENTERS; %From previous frame
        end
        CENTERS=tempCENTERS;
        if x~=refFrame
            [Transform, match]=cpd_register(CENTERS',prevCENTERS', opt);
           

             %Acquire distances, ordered by objects in this frame
             mindistsq=NaN*ones(1,numel(match));
             for y=1:numel(match) %kind of awkward that this is needed
                mindistsq(y)=sum((Transform.Y(y,:)'-CENTERS(:,match(y))).^2);
             end
             % integrate information from previous frame if reasonable
             if x>1
                [TransformOld, matchOld]=cpd_register(CENTERS',oldCENTERS', opt);
                %Acquire distances, ordered by objects in this frame
                mindistsqOld=NaN*ones(1,size(CENTERS,2));
                for y=1:numel(matchOld) %kind of awkward that this is needed
                   mindistsqOld(y)=sum((TransformOld.Y(y,:)'-CENTERS(:,matchOld(y))).^2);
                end
                %examine discrepancies and resolve based on which one is closer
                %in transformed distance
                discrepancy=(match~=matchOld);
                for y=find(discrepancy)'
                    if mindistsq(y)>mindistsqOld(y)
                        match(y)=matchOld(y);
                    end
                end
                discrepancies(x)=sum(discrepancy);
             end 
             
             matchCenters=CENTERS(:,match); %reorganize to match redCenters order
             nonMatchCenters=CENTERS;
             nonMatchCentersIndices=1:size(CENTERS,2);
             nonMatchCenters(:,match)=[]; %Nonmatched points
             nonMatchCentersIndices(match)=[]; %Original indices (in green) of these unmatched points
             mindistsq=sum((Transform.Y'-matchCenters).^2);

        %         Replace the matches that aren't the best with a guess as to where
        %         it should be, looking first for 2nd, 3rd place matches. This
        %         is basically Gale-Shapeley
        
            allMatches=unique(match);
            if numel(allMatches)~=numel(match) %otherwise, we don't ahve to do any of this
                homelessPoints=struct([]);
                for y=1:numel(allMatches)
                    mask=(match==allMatches(y));
                    theseMatches=find(mask);
                   if numel(theseMatches)>1
                        [~,keep]=min(mindistsq(mask));
                        mask(theseMatches(keep(1)))=0; %arbitrarily only keep the first minimum, if there is somehow more than 1
                        for z=1:numel(mask) %there are better ways to do this
                            if mask(z)
                                homelessPoints(end+1).index=z; %#ok<AGROW>
                                homelessPoints(end).loc=Transform.Y(z,:)';
                                homelessPoints(end).assign=0; %dummy
                            end
                        end
                   end
                end

                %for each homeless point, calculate distance to nonmatched points
                %This is inefficient if the number of points is high, but hopefully
                %it is not (otherwise we should do kdtreesearch or something)
                for y=1:numel(homelessPoints)
                    homelessPoints(y).sqdistances=NaN*ones(1,size(nonMatchCenters,2));
                    for z=1:size(nonMatchCenters,2)
                        homelessPoints(y).sqdistances(z)=sum((nonMatchCenters(:,z)-homelessPoints(y).loc).^2);
                    end
                    [~,ordering]=sort(homelessPoints(y).sqdistances);
                    homelessPoints(y).ordering=ordering;
                end
                %match each point to nearest unmatched, with competition. Continue
                %until unchanged or no more homeless points. Iteration limit
                %%just in case I messed up (should be guaranteed to terminate)
                iterlimit=100;
                iter=0;
                matchedPoints=-ones(1,size(nonMatchCenters,2)); %stores which ones have already been matched. Using -1 as the dummy variable
                lastMatchedPoints=zeros(1,size(nonMatchCenters,2));
                while (iter<iterlimit) && ~isempty(find(~[homelessPoints.assign],1)) && ~isequal(lastMatchedPoints,matchedPoints) %there's a reason I didn't originally want to do this...
                    lastMatchedPoints=matchedPoints;
                    for y=1:numel(homelessPoints)
                        if ~homelessPoints(y).assign
                            for z=1:numel(homelessPoints(y).ordering)
                                if matchedPoints(homelessPoints(y).ordering(z))<0
%                                     if homelessPoints(y).sqdistances(homelessPoints(y).ordering(z))<30 %arbitrary limit - it should be closer than 30 pixels, to avoid crazy assignments
                                        %ten pixel limit on distance from previous frame, only
                                        %valid for zimmer videos
                                        
                                    if x==1 || sum((oldCENTERS(:,homelessPoints(y).index)...
                                        -CENTERS(:,nonMatchCentersIndices(homelessPoints(y).ordering(z)))).^2)<100 %Note no sqrt
                                        matchedPoints(homelessPoints(y).ordering(z))=y;
                                        homelessPoints(y).assign=homelessPoints(y).ordering(z);
                                        break
                                    end
                                    
%                                     end
                                else
                                    %Fight!
                                   if x==1 || sum((oldCENTERS(:,homelessPoints(y).index)...
                                            -CENTERS(:,nonMatchCentersIndices(homelessPoints(y).ordering(z)))).^2)<100 %Note no sqrt
                                       opponent=matchedPoints(homelessPoints(y).ordering(z));
                                       if homelessPoints(y).sqdistances(homelessPoints(y).ordering(z))<homelessPoints(opponent).sqdistances(homelessPoints(y).ordering(z))
                                           %this point wins and takes over
                                           matchedPoints(homelessPoints(y).ordering(z))=y;
                                           homelessPoints(y).assign=homelessPoints(y).ordering(z);
                                           homelessPoints(opponent).assign=0;
                                           break;
                                       end
                                   end
                                       %otherwise: sorry, point is taken, keep
                                       %looking
                                end
                            end
                        end
                    end
                    if ~find(~[homelessPoints.assign],1) %no more homeless points
                        break
                    end
                    iter=iter+1;
                end
                if iter==iterlimit
                   warning('Iteration limit reached on point search!') 
                end

                for y=1:numel(homelessPoints)
                    if homelessPoints(y).assign %0 was used as the dummy
                        match(homelessPoints(y).index)=nonMatchCentersIndices(homelessPoints(y).assign);
                    else
                        %Use transformed location as guess for any still remaining
                        %homeless points
                        %and update guesses{x}
                        guesses(homelessPoints(y).index,x)=true;
                        allCenters{x}(end+1).Area=[];
                        allCenters{x}(end).PixelList=[]; 
                        allCenters{x}(end).Centroid=homelessPoints(y).loc';
                        CENTERS(:,end+1)= homelessPoints(y).loc'; %#ok<AGROW>
                        match(homelessPoints(y).index)=numel(allCenters{x});

                    end
                end
            end
            regCenters(:,:,x)=CENTERS(:,match);
            CENTERS=CENTERS(:,match);
            allCenters{x}=allCenters{x}(match);
            thisS3=allCenters{x};
            assert(isempty(find(reshape([allCenters{x}.Centroid],3,numel(allCenters{x}))~=CENTERS,1)))
        else
           thisS3=allCenters{x};
        end
    end
    regCenters(:,:,x)=CENTERS;
    
    if writeVideoBool
        if isempty(skipCells) %plot all cells
            imshow([double(thisShow)./maxVidValue max(segNorm1(:,:,:,x),[],3)],[])
        else %plot only some cells
            tempImage=zeros(size(segNorm1,1),size(segNorm1,2),size(segNorm1,3));
            for y=1:numObj
                if ~isempty(find(skipCells==y,1))
                    continue
                end
                for z=1:size(thisS3(y).PixelList,1)
                    tempImage(thisS3(y).PixelList(z,2),thisS3(y).PixelList(z,1),thisS3(y).PixelList(z,3))=1;
                end
            end
            imshow([double(thisShow)./maxVidValue max(tempImage,[],3)],[])
        end
    end
%     %get maximum intensities, write text
%     %tempIm(tempSyn(y).PixelList(z,2),tempSyn(y).PixelList(z,1))=y;
%     %%reminder that this is how pixel list works
%     for y=1:numObj
%        if guesses(y,x) ||  isempty(thisS3(y).PixelList)
%            %Use 11 pixel square to get maximum (5 pixels in z)
%            %Sphere would be better...
% %            [xBottom,xTop] = edgeBound(CENTERS(1,y),5,size(act1,1));
% %            [yBottom,yTop] = edgeBound(CENTERS(2,y),5,size(act1,2));
% %            [zBottom,zTop] = edgeBound(CENTERS(3,y),2,size(act1,3));
% %            tempPixels=act1(xBottom:xTop,yBottom:yTop,zBottom:zTop);
% %            tempPixels=tempPixels(:);
% %            maxInt(y,x)=max(tempPixels)-meanThisFrame;
% %            meanInt(y,x)=mean(tempPixels)-meanThisFrame;
% %            reTempPixels=sort(tempPixels,1,'descend');
% %            if numel(reTempPixels)>=10
% %                reTempPixels=reTempPixels(1:10);
% %            end
% %            mean20Int(y,x)=mean(reTempPixels)-meanThisFrame;
% %            just set to nan...
%            maxInt(y,x)= NaN;
%            meanInt(y,x)=NaN;
%            mean20Int(y,x)=NaN;
%        else
%            tempPixels=zeros(size(thisS3(y).PixelList,1),1);
%            for z=1:size(thisS3(y).PixelList,1)
%                %This should be the right order->in 3d PixelList is the same
%                %order as Centroid
%                tempPixels(z)=act1(thisS3(y).PixelList(z,1),thisS3(y).PixelList(z,2),thisS3(y).PixelList(z,3));
%            end
%            maxInt(y,x)=max(tempPixels)-meanThisFrame;
%            meanInt(y,x)=mean(tempPixels)-meanThisFrame;
%            reTempPixels=sort(tempPixels,1,'descend');
%            if numel(reTempPixels)>=10
%                reTempPixels=reTempPixels(1:10);
%            end
%            mean20Int(y,x)=mean(reTempPixels)-meanThisFrame;
%        end
%        if writeVideoBool && isempty(find(skipCells==y,1))
%            tempstr=num2str(y);
%            if guesses(y,x)
%                tempstr(end+1)='*'; %#ok<AGROW>
%            end
%            text(CENTERS(2,y)+size(thisShow,2),CENTERS(1,y),tempstr,'Color',[1 0 0])
%        end
%     end
    if writeVideoBool
        text(10,10,num2str(x),'Color',[1 1 1]) %frame number
        currFrame = getframe;
        writeVideo(v,currFrame);
    end
end
if writeVideoBool
    disp('Video done!')
    close(v)
end



end