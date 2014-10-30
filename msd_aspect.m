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

hf1 = figure(1);
set(hf1,'Position',[0 50 1000 600],'color','w');
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
    title(int2str(t))


    
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
 
    subplot(1,2,1)
    plot(cnd(:,1),cnd(:,2),'*r')
    plot_ellipse(cnd(:,7)/2,cnd(:,8)/2,degtorad(180-cnd(:,4)),cnd(:,1),cnd(:,2));
    title(int2str(t))
  
    hold off
    if mv
        frame=getframe;
        writeVideo(aviobj,frame);
    end
    out(t).improp = improp;
    cnt = [cnt; cnd];
    pause(0.01)
end

if mv
  close(aviobj);
end

%%%%%particle tracking
param.mem = 5;
param.good = 10;
param.dim = 2;
param.quiet = 1;
maxdisp = 20;
trks = track(cnt,maxdisp,param);
%%%%%%%particle tracking
trks_part = trks;
trks_part(:,3:8) = [];
trks_theta = [trks(:,4) zeros(size(trks,1),1) trks(:,9:10)];
out = MSD(trks_part);
out_theta = MSD(trks_theta);


figure;
for k=1:max(trks(:,10)); ind=find(trks(:,10)==k); 
plot(trks(ind,1),trks(ind,2));xlabel('pixel');ylabel('pixel');hold all;
end
figure;
loglog(out(:,1),out(:,2),out_theta(:,1),out_theta(:,2),'r');xlabel('lag time (in frames)');ylabel('MSD (in pixels)');
figure;
hist(cnd(:,7));

%start by computing the aspect ratio for all particles
% modify this line so that a is a vector of aspect ratios for all the particles and that a(1) is the aspect ratio of particle 1 and a(i) is the aspect ratio of particle i.
a=cnd(:,7)/cnd(:,8);

%use the sort function to sort the values of a
[sorted_a, inds]=sort(a,'ascend');

%then make a plot of the xy_msd and theta_msd vs aspect ratio by coloring the plots by their aspect ratio.

%let's make a plot where the color changes linearly with aspect ratio.  

da=0.5; % might have to play with da
abins=min(a):da:(max(a)+da);
nbins=length(abins);

% generate colors
bincolors=jet(nbins);
figure;
for i=1:max(trks(:,10))
%compute bin for particle
ind_1=find(abins(1:end-1)>a(i) & abins(2:end)<=a(i),1,'First');
% modify this line so that lagtimes and msd are the lagtimes and msd for particle i 
plot(out(:,1), out(:,2), '-', 'color', bincolors(ind_1,:));hold all
end
