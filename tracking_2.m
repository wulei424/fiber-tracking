clear

imlst = dir('Series016*tif');
cnt = [];
mv=0;
% mv = input('make movie?:');
if mv
    aviobj = VideoWriter('Series016.avi','Uncompressed AVI');
    aviobj.FrameRate = 20; %aviobj.Quality = 100;
    open(aviobj);
end
for t=1:length(imlst)
    t;
    im = (imread(imlst(t).name));  % read the image
    subplot(1,2,1)
    imagesc(im);colormap gray; axis image;
    hold on
    im = bpass(im,1,11);  %bpass
    th = 2;  %set the threshold for binary image

    imbw = im>th; %creating a binary image (black and white) 

    subplot(1,2,2)
    imagesc(im); axis image


    
    % load imbw
    imlb = bwlabel(imbw);  % create an image with each connected region indexed. 

    improp = regionprops(imlb,im,'Area','Orientation','Perimeter','WeightedCentroid',...
        'Eccentricity','MajorAxisLength','MinorAxisLength','PixelIdxList','PixelList');
    % build-in regrionprops function, can get more properties if needed,
    % returns a structure contain properties for each connected area


    %%re-organize data into a matrix if you need
    cnd = zeros(length(improp),9);
    for i=1:length(improp)
%         i
        cnd(i,:) = [improp(i).WeightedCentroid,improp(i).Area, improp(i).Orientation, improp(i).Perimeter,  ...
            improp(i).Eccentricity, improp(i).MajorAxisLength, improp(i).MinorAxisLength, t];

    end
    cnd(cnd(:,3)<20,:)=[];
    % overlap image with 
%     im = imread('Pentanol_4_2.tif');

    % im(improp(i).PixelIdxList)=0;
%     imagesc(im); axis image; colormap gray
%     hold on
    subplot(1,2,1)
    plot(cnd(:,1),cnd(:,2),'*r')
    plot_ellipse(cnd(:,7)/2,cnd(:,8)/2,degtorad(180-cnd(:,4)),cnd(:,1),cnd(:,2));
    title(int2str(t))
    % plot(improp(2).WeightedCentroid(1),improp(2).WeightedCentroid(2),'o')
    % plot(improp(25).PixelList(:,1),improp(25).PixelList(:,2),'.b')
    hold off
    if mv
        frame=getframe;
        writeVideo(aviobj,frame);
    end
    out(t).improp = improp;
    cnt = [cnt; cnd];
    pause(0.01)
end

%%%%%particle tracking
param.mem = 5;
param.good = 10;
param.dim = 2;
param.quiet = 1;
maxdisp = 20;
trks = track(cnt,maxdisp,param);
%%%%%%%%particle tracking
% trks_part = trks;
% trks_part(:,3:8) = [];

id = trks(:,10) == 1;

msd_xy = msd_calculator([trks(id,9) sqrt(trks(id,1).^2+trks(id,2).^2)]);
msd_theta = msd_calculator([trks(id,9) trks(id,4)]);


%%
figure(2)
for t=1:length(imlst)
    
    id = trks(:,9) == t;
    im = (imread(imlst(t).name));  % read the image
%     subplot(1,2,1)
    imagesc(im);colormap gray; axis image;
    hold on
    
%     subplot(1,2,1)
    plot(trks(id,1),trks(id,2),'*r')
    plot_ellipse(trks(id,7)/2,trks(id,8)/2,degtorad(180-trks(id,4)),trks(id,1),trks(id,2));
    title(int2str(t))
    % plot(improp(2).WeightedCentroid(1),improp(2).WeightedCentroid(2),'o')
    % plot(improp(25).PixelList(:,1),improp(25).PixelList(:,2),'.b')
    hold off
    if mv
        frame=getframe;
        writeVideo(aviobj,frame);
    end
    pause(0.01)
end
%%
if mv
  close(aviobj);
end
save cnt cnt;
figure;for k=1:max(trks(:,10)); ind=find(trks(:,10)==k); plot(trks(ind,1),trks(ind,2));hold all;end


