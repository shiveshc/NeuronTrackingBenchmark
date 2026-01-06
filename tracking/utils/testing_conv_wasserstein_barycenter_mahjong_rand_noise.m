addpath('D:\Shivesh\OptimalTransport\tracking\2015-SIGGRAPH-convolutional-ot-master\code\convolutional_wasserstein')
addpath('D:\Shivesh\OptimalTransport\tracking\2015-SIGGRAPH-convolutional-ot-master\code\toolbox')
%% Read data

p0im = 'D:\Shivesh\OptimalTransport\tracking\2015-SIGGRAPH-convolutional-ot-master\data\images\mahjong\eight.png';
p1im = 'D:\Shivesh\OptimalTransport\tracking\2015-SIGGRAPH-convolutional-ot-master\data\images\mahjong\nine.png';

p0 = 1-im2double(rgb2gray(imread(p0im)));
% p0 = (p0 - min(p0(:)))/(max(p0(:))-min(p0(:)));
% p1 = (p1 - min(p1(:)))/(max(p1(:))-min(p1(:)));
p0 = double(p0 > .5);

imSize = size(p0);
max_idx = imSize(1,1)*imSize(1,2);


% make samples with added random noise
p = [];
num_samples = 50;
for n = 1:num_samples
    shot_noise = zeros(imSize);
    noise_idx = randperm(max_idx,100);
    shot_noise(noise_idx) = 1;
    
    displacement_noise = round(-8 + 16*rand(1,2));
    noisy_p0 = imtranslate(p0,displacement_noise);
    
    noisy_img = noisy_p0 + shot_noise;
%     noisy_img = shot_noise; % only random noise
    noisy_img = noisy_img(:);
    noisy_img = noisy_img + 1e-7;
    noisy_img = noisy_img / sum(noisy_img);
    
    p = cat(2,p,noisy_img);
end

p0 = p0(:);
n = length(p0);
areaWeights = ones(n,1)/n;

%%
help imfilter

%% Set up blur

filterSize = 3; %was 5

h = fspecial('gaussian',[1 max(imSize)],filterSize);% hsize sigma
h = h / sum(h);

imBlur = @(x) imfilter(imfilter(x,h,'replicate'),h','replicate');
imagesc(imBlur(reshape(p0,imSize)));

%blurColumn = @(x) reshape(fastBlur(reshape(x,imSize),filterSize),[],1);
blurColumn = @(x) reshape(imBlur(reshape(x,imSize)),[],1);
blurAll = @(x) cell2mat(cellfun(blurColumn, num2cell(x,1), 'UniformOutput', false));

imagesc(reshape(blurAll(p0),imSize));
axis equal;
axis off;

%% Compute barycenter

averages = cell(1,1);
barycenters = cell(1,1);
alpha = ones(1,size(p,2))/size(p,2);

entropies = -sum(p.*log(p).*repmat(areaWeights,1,size(p,2)));
minEntropy = min(entropies);
targetEntropy = minEntropy;

close all;
fprintf('Test %d\n',1);

a = sum(bsxfun(@times,p,alpha),2);
averages{1} = reshape(a,imSize);

subplot(1,2,1);
imagesc(averages{1});axis equal;axis off;
colormap gray

b = convolutionalBarycenter(p,alpha,areaWeights,blurAll,blurAll,targetEntropy);
barycenters{1} = reshape(b,imSize);

subplot(1,2,2);
imagesc(barycenters{1});axis equal;axis off;
colormap gray

drawnow;

%%

close all
for i=1:length(barycenters)
    scale = 1;
    while 1
        ind = barycenters{i}>max(barycenters{i}(:))/scale;
        
        if sum(ind(:))>sum(p0(:)>2e-5)*.8 || sum(ind(:))>sum(p1(:)>2e-5)*.8
            break;
        end
        scale = scale + .0025;
    end
    
    ind = -ind;
    ind = (ind - min(ind(:)))/(max(ind(:))-min(ind(:)));
    imwrite(ind,sprintf('t%g.png',steps(i)));
%     imshow(ind);

    b = -barycenters{i};
    b = (b-min(b(:)))/(max(b(:))-min(b(:)));
    imwrite(b,sprintf('b%g.png',steps(i)));
    
    b = -averages{i};
    b = (b-min(b(:)))/(max(b(:))-min(b(:)));
    imwrite(b,sprintf('a%g.png',steps(i)));
end

%%

save mahjong.mat