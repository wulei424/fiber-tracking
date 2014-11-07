clear

expid='';

datapath=fullfile('/Research/Projects/Others/LeiWu/fiber-tracking/',expid);

outpath=fullfile('/Research/Projects/Others/LeiWu/fiber-tracking/',expid);

imlst = dir(fullfile(datapath,[expid,'*tif']));
cnt = [];
mv=0;
% mv = input('make movie?:');
if mv
    aviobj = VideoWriter(fullfile(outpath,[expid,'.avi']),'Uncompressed AVI');
    aviobj.FrameRate = 20; %aviobj.Quality = 100;
    open(aviobj);
end

hf1 = figure(1);
set(hf1,'Position',[0 50 1000 600],'color','w');
for t=1:length(imlst)
    t;
    im = (imread(imlst(t).name));  % read the image
    subplot(1,2,1);
    imagesc(im);colormap gray; axis image;
    hold on
    im = bpass(im,1,11);  %bpass
    th = 2;  %set the threshold for binary image

    imbw = im>th; %creating a binary image (black and white) 

    subplot(1,2,2);
    imagesc(im); axis image;
    title(int2str(t));


    
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

%%
%%%%%particle tracking
param.mem = 0;
param.good = 10;
param.dim = 2;
param.quiet = 1;
maxdisp = 20;
trks = track(cnt,maxdisp,param);

%% caculate MSD using MSD function
%%%%%%%particle tracking
% trks_part = trks;
% trks_part(:,3:8) = [];
% trks_theta = [trks(:,4) zeros(size(trks,1),1) trks(:,9:10)];
% out = MSD(trks_part);
% out_theta = MSD(trks_theta);
%% plot trajectories
fps=1/(0.11);
ppm=1/(0.18);
figure;
for k=1:max(trks(:,10)); 
    ind=find(trks(:,10)==k);
    plot(trks(ind,1)/(ppm.^2),trks(ind,2)/(ppm.^2));xlabel('X [\mu m]');ylabel('Y [\mu m]');
    hold all;
end

%% make a mv with identified particles
mv=0;
% mv = input('make movie?:');
if mv
    aviobj = VideoWriter('Series016_tracked.avi','Uncompressed AVI');
    aviobj.FrameRate = 20; %aviobj.Quality = 100;
    open(aviobj);
end
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
save cnt cnt




%% calculate translational and rotational MSD using msd_calculator function
number_particles=max(trks(:,10));

for id=1:number_particles
    ind=find(trks(:,10)==id);
    msd_xy{id} = msd_calculator([trks(ind,9) trks(ind,1) trks(ind,2)]);
    msd_theta{id} = msd_calculator([trks(ind,9) trks(ind,4) zeros(size(trks(ind,4)))]);
   
end

%% plot translational and rotational MSD VS time

figure;
for id=1:length(msd_xy);
    loglog(msd_xy{id}(:,1)/fps,msd_xy{id}(:,2)/(ppm.^2)); xlabel('Time [sec]');ylabel('Translational MSD [\mu m^2]');hold all;
   
end

figure;
for id=1:length(msd_theta);
    loglog(msd_theta{id}(:,1)/fps,msd_theta{id}(:,2)/(57.^2)); xlabel('Time [sec]');ylabel('Rotational MSD [rad^2]');hold all;
end
%% plot MSD vs Time using MSD function
% figure;
% loglog(out(:,1)/fps,out(:,2)/(ppm.^2));xlabel('Time [sec]');ylabel('Translational MSD [\mu m^2]');
% figure;
% loglog(out_theta(:,1)/fps,out(:,2)/(57.^2));xlabel('Time [sec]');ylabel('Rotational MSD [rad^2]');
%% plot major axis length distribution

figure;
x1=trks(:,7)/ppm;
numberOfBins = 50;
[counts, binValues] = hist(x1, numberOfBins);
bar(binValues, counts, 'barwidth', 1);
xlabel('Major Axis Length [\mu m]');
ylabel('Absolute Count');
figure;
normalizedCounts = 100 * counts / sum(counts);
bar(binValues, normalizedCounts, 'barwidth', 1);
xlabel('Major Axis Length [\mu m]');
ylabel('Normalized Count [%]');
%% plot minor axis length distribution
figure;
x2=trks(:,8)/ppm;
numberOfBins = 50;
[counts, binValues] = hist(x2, numberOfBins);
bar(binValues, counts, 'barwidth', 1);
xlabel('minor axis length [\mu m]');
ylabel('Absolute Count');
figure;
normalizedCounts = 100 * counts / sum(counts);
bar(binValues, normalizedCounts, 'barwidth', 1);
xlabel('Minor Axis Length [\mu m]');
ylabel('Normalized Count [%]');
%% caculate aspect ratio

%%start by computing the aspect ratio for all particles

a=[];

for id=1:max(trks(:,10))
ind=find(trks(:,10)==id);
majorax=trks(ind,7);
minorax=trks(ind,8);
a(id)=mean(majorax)/mean(minorax);
end
%% caculate and plot Translational D VS Aspect ration
D_xy=[];
figure;for id=1:length(msd_xy);
   
    D_xy{id}=mean((msd_xy{id}(:,2)/(ppm.^2))./(4*(msd_xy{id}(:,1)/fps)));
    
    semilogy(a(id),D_xy{id},'o'); xlabel('Aspect ratio');ylabel('Translational diffusion coefficient [\mu m^2/s]');hold all;
end
%% plot translational D VS major axis length

D_xy=[];
A_major=[];

figure;for id=1:length(msd_xy);
    ind=find(trks(:,10)==id);
    majorax=trks(ind,7);
    A_major(id)=mean(majorax);
    
    D_xy{id}=mean((msd_xy{id}(:,2)/(ppm.^2))./(4*(msd_xy{id}(:,1)/fps)));
    
    semilogy(A_major(id)/ppm,D_xy{id},'s'); xlabel('Major axis length [\mu m]');ylabel('Translational diffusion coefficient [\mu m^2/s]');hold all;
end

    
  %% calculate rotational D and plot rotational D vs aspect ratio
D_theta=[];
tau=[]; % tau is the time for the fiber to diffuse 1 rad
figure(1);
figure(2);
for id=1:length(msd_theta);
D_theta{id}=mean((msd_theta{id}(:,2)/(57.^2))./(2*(msd_theta{id}(:,1)/fps)));
tau(id)=1./(2*D_theta{id}); 

figure(1);
semilogy(a(id),D_theta{id},'*'); xlabel('Aspect ratio');ylabel('Rotational diffusion coefficient [rad^2/s]');hold all;
figure(2);
semilogy(a(id),tau(id),'<'); xlabel('Aspect ratio');ylabel('Tau [s]');hold all;
end

%% plot rorational D vs major axis length

figure(1);
figure(2);
for id=1:length(msd_theta);
    ind=find(trks(:,10)==id);
    majorax=trks(ind,7);
    A_major(id)=mean(majorax);
    D_theta{id}=mean((msd_theta{id}(:,2)/(57.^2))./(2*(msd_theta{id}(:,1)/fps)));
    tau(id)=1./(2*D_theta{id}); % tau is the time for the fiber to diffuse 1 rad
   figure(1);
    semilogy(A_major(id)/ppm,D_theta{id},'d'); xlabel('Major axis length [\mu m]');ylabel('Translational diffusion coefficient [rad^2/s]');hold all;
   figure(2);
    semilogy(A_major(id)/ppm,tau(id),'>'); xlabel('Major axis length [\mu m]');ylabel('Tau [s]');hold all;
end
%%
%use the sort function to sort the values of a
[sorted_a, inds]=sort(a,'ascend');

%then make a plot of the xy_msd and theta_msd vs aspect ratio by coloring the plots by their aspect ratio.

%let's make a plot where the color changes linearly with aspect ratio.  

da=0.5; % might have to play with da
abins=(min(a)-da):da:(max(a)+da);
nbins=length(abins);

% generate colors
bincolors=jet(nbins);
figure(1);
figure(2);
for i=1:max(trks(:,10))
%compute bin for particle
ind_1=find(abins(1:end-1)<a(i) & abins(2:end)>=a(i),1,'First');

out=[];
out(:,1)=msd_xy{i}(:,1);
out(:,2)=msd_xy{i}(:,2);

figure(1);
loglog(out(:,1)/fps, out(:,2)/(ppm.^2), '-', 'color', bincolors(ind_1,:));xlabel('Time [sec]');ylabel('Translational MSD [\mu m^2]');hold all

figure(2);
plot(i,a(i),'s', 'color', bincolors(ind_1,:));xlabel('particle ID');ylabel('aspect ratio');hold all

end

%%
%%plot aspect ratio distribution
figure;
numberOfBins = 20;
[counts, binValues] = hist(a, numberOfBins);
bar(binValues, counts, 'barwidth', 1);
xlabel('aspect ratio');
ylabel('Absolute Count');
figure;
normalizedCounts = 100 * counts / sum(counts);
bar(binValues, normalizedCounts, 'barwidth', 1);
xlabel('aspect ratio');
ylabel('Normalized Count [%]');
%%

abins2=1:2:11;
trks_xy = [trks(:,1) trks(:,2) trks(:,9:10)];    
trks_theta = [trks(:,4) zeros(size(trks,1),1) trks(:,9:10)];
for bin=1:length(abins2)-1
    particle_inds=find(a>abins2(bin) & a<=abins2(bin+1),1,'First');
    ind=[];
    for j=1:length(particle_inds)
    ind=[ind,find(trks_xy(:,4)==particle_inds(j))];
    end
    sub_trks_xy = trks_xy(ind,:);
    sub_trks_theta = trks_theta(ind,:);
    grp_msd_xy{bin} = MSD(sub_trks_xy); % time, msd, number of observations
    grp_msd_theta{bin} = MSD(sub_trks_theta);
end    

%% plot Translational and rotational MSD VS Time using bins
nbins=length(abins2)-1;

% generate colors
bincolors=jet(nbins);
figure(1);
figure(2);

for i=1:nbins

out_theta=[];
out_theta(:,1)=grp_msd_theta{i}(:,1);
out_theta(:,2)=grp_msd_theta{i}(:,2);

out_xy=[];

out_xy(:,1)=grp_msd_xy{i}(:,1); 
out_xy(:,2)=grp_msd_xy{i}(:,2);

figure(1);
loglog(out_theta(:,1)/fps, out_theta(:,2)/(57.^2), 's', 'color', bincolors(i,:));xlabel('Time [sec]');ylabel('Rotational MSD [rad^2]');hold all

figure(2);
loglog(out_xy(:,1)/fps, out_xy(:,2)/(ppm.^2), 's', 'color', bincolors(i,:));xlabel('Time [sec]');ylabel('Translational MSD [\mu m^2]');hold all

figure(3);
plot(i,abins2(i),'s', 'color', bincolors(i,:));hold all


end
    
%%
%%%%%%%particle tracking
% trks_part = trks;
% trks_part(:,3:8) = [];
% trks_theta = [trks(:,4) zeros(size(trks,1),1) trks(:,9:10)];
% out = MSD(trks_part);
% out_theta = MSD(trks_theta);


