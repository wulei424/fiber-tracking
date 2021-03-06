clear

expid='Series016';

datapath=fullfile('D:\UPenn\asbestos project\flurecent chrysotile\Lei_23Oct2014\Experiment\',expid);

outpath=fullfile('D:\UPenn\asbestos project\flurecent chrysotile\Lei_23Oct2014\Experiment\',expid);

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
fps=1/(0.11); % frame per sec
ppm=1/(0.18); % pixel per micrometer
dpr=1/(0.0175);% degree per radian

figure;
for k=1:max(trks(:,10)); 
    ind=find(trks(:,10)==k);
    plot(trks(ind,1)/(ppm.^2),trks(ind,2)/(ppm.^2));xlabel('X [\mum]');ylabel('Y [\mum]');
    hold all;
end

%% make a mv with identified particles
mv=0;
% mv = input('make movie?:');
if mv
    aviobj = VideoWriter('Series016_tracked.avi','Uncompressed AVI');
    aviobj.FrameRate = 20; %aviobj.Quality = 100;??
    open(aviobj);
end
figure(2)
for t=1:length(imlst)
    clf;
    id = trks(:,9) == t;
    im = (imread(imlst(t).name));  % read the image
%     subplot(1,2,1)
    imagesc(im);colormap gray; axis image;
    hold on
    
%     subplot(1,2,1)
    plot(trks(id,1),trks(id,2),'*r')
     C=get(gca,'colororder');
    for k=1:max(trks(:,10));
        
    % find this particle    
    ind=find(trks(:,10)==k);
    % find times before now for this particle
    ind2=find(trks(ind,9)<=t);
   
    if ~isempty(ind2)
        id=ind(ind2(end));
        hellipse=plot_ellipse(trks(id,7)/2,trks(id,8)/2,degtorad(180-trks(id,4)),trks(id,1),trks(id,2));
        mycolor=C(rem(k-1,size(C,1))+1,:);
        set(hellipse,'color',mycolor);
        hold all;
        %mycolor=get(hellipse,'Color');   
        plot(trks(ind(ind2),1),trks(ind(ind2),2),'-','Color',mycolor);
        
        
    end
    end
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




%% calculate translational and rotational MSD using (msd_calculator) function
number_particles=max(trks(:,10));


for id=1:number_particles
    ind=find(trks(:,10)==id);
    msd_xy{id} = msd_calculator([trks(ind,9) trks(ind,1) trks(ind,2)]);
    msd_theta{id} = msd_calculator([trks(ind,9) trks(ind,4) zeros(size(trks(ind,4)))]);
  
   
end


%%
%number_particles=max(trks(:,10));

%for id=1:number_particles
    %ind=find(trks(:,10)==id);
    
    
    
   % x(id)=trks(ind,1);
   % y(id)=trks(ind,2);
   % theta(id)=trks(ind,4);
    %time(id)=length(find(trks(:,10)==id));
    %for t=1:time
        %delta_x=x(t+1)-x(t);
        %delta_y=y(t+1)-y(t);
       % r1=cos(theta)*delta_x+sin(theta)*delta_y;
       % r2=-sin(theta)*delta_x+cos(theta)*delta_y;
        
    %end
%end

%% plot translational and rotational MSD VS time

figure;
for id=1:length(msd_xy);
    loglog(msd_xy{id}(:,1)/fps,msd_xy{id}(:,2)/(ppm.^2)); xlabel('Time [sec]');ylabel('Translational MSD [\mum^2]');hold all;
   
end

figure;
for id=1:length(msd_theta);
    loglog(msd_theta{id}(:,1)/fps,msd_theta{id}(:,2)/(dpr.^2)); xlabel('Time [sec]');ylabel('Rotational MSD [rad^2]');hold all;
end
%% plot MSD vs Time using MSD function
% figure;
% loglog(out(:,1)/fps,out(:,2)/(ppm.^2));xlabel('Time [sec]');ylabel('Translational MSD [\mum^2]');
% figure;
% loglog(out_theta(:,1)/fps,out(:,2)/(57.^2));xlabel('Time [sec]');ylabel('Rotational MSD [rad^2]');
%% plot major axis length distribution

figure;
x1=trks(:,7)/ppm; % major axis length
numberOfBins = 50;
[counts, binValues] = hist(x1, numberOfBins);
normalizedCounts = 100 * counts / sum(counts);
bar(binValues, normalizedCounts, 'barwidth', 1);
xlabel('Major Axis Length [\mum]');
ylabel('Normalized Count [%]');
%% plot minor axis length distribution
figure;
x2=trks(:,8)/ppm; % minor axis length
numberOfBins = 50;
[counts, binValues] = hist(x2, numberOfBins);
normalizedCounts = 100 * counts / sum(counts);
bar(binValues, normalizedCounts, 'barwidth', 1);
xlabel('Minor Axis Length [\mum]');
ylabel('Normalized Count [%]');
%% caculate aspect ratio

%%start by computing the aspect ratio for all particles

a=[];
A_major=[];
slope=[];

for id=1:max(trks(:,10))
ind=find(trks(:,10)==id);
majorax=trks(ind,7);
minorax=trks(ind,8);
a(id)=mean(majorax)/mean(minorax);
A_major(id)=mean(majorax);

slope=mean(diff(A_major/ppm)./diff(a)); % relation between aspect ration and major aixs length
plot(a(id),A_major(id)/ppm,'<');xlabel('Aspect ratio');ylabel('Major axis length [\mum]');hold all;
end

 
%% calculate and plot Translational D (including theoretical D) VS Aspect ratio
Kb=1.38*10^(-23);  % Boltzmann constant
T=298; % sample temperature
eta=0.89*10^(-3); % viscosity for water at 23 C
r1=-0.114;% parallel end-correction coefficient. --ref.Broersma J.Chem.Phys.(1960)
r2=0.886;% perpendicular end-correction coefficient. --ref.Broersma J.Chem.Phys.(1960)
r3=-0.447;% rotational end-correction coefficient.--ref.Broersma J.Chem.Phys.(1960)
D_xy_theo_a=[];% theoretical D_xy as a function of aspect ratio
D_xy_theo_l=[];% theoretical D_xy as a function of major axis length
D_xy=[];
figure(1);
figure(2);
A_a=min(a):0.1:max(a);
A_l=min(x1):0.1:max(x1);



D_xy_theo_a=((Kb*T)./(6*pi*eta)).*((2*log(A_a)-r1-r2)./(slope*A_a*10.^(-6)));
D_xy_theo_l=((Kb*T)./(6*pi*eta)).*((2*log(A_l/slope)-r1-r2)./(A_l*10.^(-6)));
for id=1:length(msd_xy);
    D_xy{id}=mean((msd_xy{id}(:,2)/(ppm.^2))./(4*(msd_xy{id}(:,1)/fps)));
    figure(1);
    loglog(a(id),D_xy{id},'o',abs(A_a),D_xy_theo_a*10.^(12),'LineWidth',2); axis([1,11, 10^(-3), 10]); xlabel('Aspect ratio');ylabel('Translational diffusion coefficient [\mum^2/s]');hold all;
   
    figure(2);
    loglog(A_major(id)/ppm,D_xy{id},'s',abs(A_l),D_xy_theo_l*10.^(12),'LineWidth',2); axis([1,25, 10^(-3), 10]);xlabel('Major axis length [\mum]');ylabel('Translational diffusion coefficient [\mum^2/s]');hold all;
end



  %% calculate rotational D (including theoretical) and plot rotational D vs aspect ratio
D_theta=[];
D_theta_theo_a=[];% theoretical D_theta as a function of aspect ratio
D_theta_theo_l=[];% theoretical D_theta as a function of major axis length
tau=[]; % tau is the time for the fiber to diffuse 1 rad
figure(1);
figure(2);
D_theta_theo_a=((3*Kb*T)./(pi*eta)).*(((log(A_a)-r3))./(((slope*A_a)*10.^(-6)).^3));
D_theta_theo_l=((3*Kb*T)./(pi*eta)).*(((log(A_l/slope)-r3))./(((A_l)*10.^(-6)).^3));

for id=1:length(msd_theta);
D_theta{id}=mean((msd_theta{id}(:,2)/(dpr.^2))./(2*(msd_theta{id}(:,1)/fps)));
tau(id)=1./(2*D_theta{id}); 

figure(1);
loglog(a(id),D_theta{id},'d', abs(A_a),D_theta_theo_a,'LineWidth',2);axis([1,11, 10^(-4), 10^(2)]);xlabel('Aspect ratio');ylabel('Rotational diffusion coefficient [rad^2/s]');hold all;
figure(2);
loglog(A_major(id)/ppm,D_theta{id},'<',abs(A_l),D_theta_theo_l,'LineWidth',2); axis([1,25, 10^(-4), 10^(2)]); xlabel('Major axis length [\mum]');ylabel('Rotational diffusion coefficient [rad^2/s]');hold all;end
%% plot Dr/Dt as a function of aspect ratio
figure;
Y=[];
for id=1:number_particles
    Y(id)=D_xy{id}./D_theta{id};
loglog(a(id),Y(id),'o','LineWidth',2);axis([1,12, 10^(-4), 10^(4)]);xlabel('Aspect ratio');ylabel('Dr/Dt [rad^2/\mum^2]');hold all;
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
loglog(out(:,1)/fps, out(:,2)/(ppm.^2), 's', 'color', bincolors(ind_1,:));xlabel('Time [sec]');ylabel('Translational MSD [\mum^2]');hold all

figure(2);
plot(i,a(i),'s', 'color', bincolors(ind_1,:));xlabel('particle ID');ylabel('aspect ratio');hold all

end

%%
%%plot aspect ratio distribution
figure;
numberOfBins = nbins;
[counts, binValues] = hist(a, numberOfBins);
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
    grp_msd_xy_1{bin}=msd_distribution_calculator(sub_trks_xy,17);% MSD distribution at time tau
    grp_msd_theta_1{bin}=msd_distribution_calculator(sub_trks_theta,17);
end    



  
 %% plot Translational and rotational MSD (including theoretical MSD)VS Time using bins
nbins=length(abins2)-1;

% generate colors
bincolors=jet(nbins);

%figure(1);
%figure(2);


msd_xy_theo=[];% theoretical msd_xy as a function of time
msd_theta_theo=[];%theoretical msd_theta as a function of time



for i=1:nbins

out_theta=[];
v_theta=[];
out_theta(:,1)=grp_msd_theta{i}(:,1);% time
out_theta(:,2)=grp_msd_theta{i}(:,2);% angular
v_theta=out_theta(:,2)./out_theta(:,1);
out_theta_1(:,4)=grp_msd_theta_1{i}(:,4);

out_xy=[];
T_1=[];
v_xy=[];
out_xy(:,1)=grp_msd_xy{i}(:,1); 
out_xy(:,2)=grp_msd_xy{i}(:,2);
v_xy=out_xy(:,2)./out_xy(:,1);
out_xy_1(:,4)=grp_msd_xy_1{i}(:,4);

T_1=min(out_xy(:,1)/fps):0.01:max(out_xy(:,1)/fps);
msd_xy_theo=((Kb*T)./(6*pi*eta)).*((2*log(2*i)-r1-r2)./(slope*(2*i)*10.^(-6)))*4*T_1*(10^(12));
msd_theta_theo=((3*Kb*T)./(pi*eta)).*(((log(2*i)-r3))./(((slope*2*i)*10.^(-6)).^3))*2*T_1;
%figure(1);
%loglog(out_theta(:,1)/fps, out_theta(:,2)/(dpr.^2), 's', T_1,msd_theta_theo,'color', bincolors(i,:),'LineWidth',2);axis([10^(-1) 30 10^(-6) 10^(2)]); xlabel('Time [sec]');ylabel('Rotational MSD [rad^2]');hold all

%figure(2);
%loglog(out_xy(:,1)/fps, out_xy(:,2)/(ppm.^2), 's', T_1,msd_xy_theo,'color', bincolors(i,:),'LineWidth',2);axis([10^(-1) 30 10^(-3) 10^(2)]);xlabel('Time [sec]');ylabel('Translational MSD [\mum^2]');hold all

%figure(3);
%plot(i,abins2(i),'s', 'color', bincolors(i,:));hold all;
figure(1);
pd_v=fitdist(v_xy,'Exponential');
x_MSD_v=min(v_xy):0.1:max(v_xy);
y_MSD_v=pdf(pd_v,x_MSD_v);
semilogy(x_MSD_v,y_MSD_v, 'color',bincolors(i,:),'LineWidth',2);hold all

%pd=fitdist(out_xy(:,2)/(ppm.^2),'Normal');
%x_MSD_T = min(out_xy(:,2)/(ppm.^2)):0.01:max(out_xy(:,2)/(ppm.^2));
%y_MSD_T= pdf(pd,x_MSD_T);
%figure(4);
%plot(x_MSD_T,y_MSD_T, 'color',bincolors(i,:),'LineWidth',2);hold all
end

%% plot Translational and rotational MSD (including theoretical MSD)VS Time using bins
%t<<1sec
nbins=length(abins2)-1;

% generate colors
bincolors=jet(nbins);

%figure(1);
%figure(2);


%msd_xy_theo=[];% theoretical msd_xy as a function of time
%msd_theta_theo=[];%theoretical msd_theta as a function of time



for i=1:nbins

out_theta=[];

out_theta(:,1)=grp_msd_theta{i}(:,1);% time
out_theta(:,2)=grp_msd_theta{i}(:,2);% angular
figure(1);
if out_theta(:,1)/fps<1
   loglog(out_theta(:,1)/fps, out_theta(:,2)/(dpr.^2));hold all
end
%figure(2);
%out_xy=[];

%out_xy(:,1)=grp_msd_xy{i}(:,1); 
%out_xy(:,2)=grp_msd_xy{i}(:,2);
%if out_xy(:,1)/fps<1
    %loglog(out_xy(:,1)/fps, out_xy(:,2)/(ppm.^2));hols all
%end

%T_1=0.01:0.01:1;
%msd_xy_theo=((Kb*T)./(6*pi*eta)).*((2*log(2*i)-r1-r2)./(slope*(2*i)*10.^(-6)))*4*T_1*(10^(12));
%msd_theta_theo=((3*Kb*T)./(pi*eta)).*(((log(2*i)-r3))./(((slope*2*i)*10.^(-6)).^3))*2*T_1;
%figure(1);
%loglog(sub_out_theta(:,1)/fps, sub_out_theta(:,2)/(dpr.^2), 's', T_1,msd_theta_theo,'color', bincolors(i,:),'LineWidth',2);axis([10^(-1) 30 10^(-6) 10^(2)]); xlabel('Time [sec]');ylabel('Rotational MSD [rad^2]');hold all

%figure(2);
%loglog(sub_out_xy(:,1)/fps, sub_out_xy(:,2)/(ppm.^2), 's', T_1,msd_xy_theo,'color', bincolors(i,:),'LineWidth',2);axis([10^(-1) 30 10^(-3) 10^(2)]);xlabel('Time [sec]');ylabel('Translational MSD [\mum^2]');hold all

%figure(3);
%plot(i,abins2(i),'s', 'color', bincolors(i,:));hold all;


%pd=fitdist(out_xy(:,2)/(ppm.^2),'Normal');
%x_MSD_T = min(out_xy(:,2)/(ppm.^2)):0.01:max(out_xy(:,2)/(ppm.^2));
%y_MSD_T= pdf(pd,x_MSD_T);
%figure(4);
%plot(x_MSD_T,y_MSD_T, 'color',bincolors(i,:),'LineWidth',2);hold all
end
%%
for i=1:nbins

out_theta=[];

out_theta(:,1)=grp_msd_theta{i}(:,1);% time
out_theta(:,2)=grp_msd_theta{i}(:,2);% angular

out_xy=[];
out_xy(:,1)=grp_msd_xy{i}(:,1); 
out_xy(:,2)=grp_msd_xy{i}(:,2);
%x_MSD_T_mu=mean(out_xy(:,2));
%x_MSD_T_sigma=std(out_xy(:,2));
%x_h=(out_xy(:,2)-x_MSD_T_mu)/x_MSD_T_sigma;
figure(1);
subplot(2,3,1);
if i==1
x_MSD_T_mu=mean(out_xy(:,2)/(ppm.^2));
x_MSD_T_sigma=std(out_xy(:,2)/(ppm.^2));
x_h=(out_xy(:,2)/(ppm.^2)-x_MSD_T_mu)/x_MSD_T_sigma;

h=kstest(x_h)
[f,x_h_values] = ecdf(x_h);
F=plot(x_h_values,f,'s','color',bincolors(i,:),'LineWidth',2);

hold on;
G = plot(x_h_values,normcdf(x_h_values,0,1),'color',bincolors(i,:),'LineWidth',2);xlabel('Translational MSD [\mum^2]');ylabel('CDF');
legend([F G],'Exp. CDF','Standard Normal CDF','Location','SE');

hold all;
end

subplot(2,3,2);
if i==2
x_MSD_T_mu=mean(out_xy(:,2)/(ppm.^2));
x_MSD_T_sigma=std(out_xy(:,2)/(ppm.^2));
x_h=(out_xy(:,2)/(ppm.^2)-x_MSD_T_mu)/x_MSD_T_sigma;

h=kstest(x_h)
[f,x_h_values] = ecdf(x_h);
F=plot(x_h_values,f,'s','color',bincolors(i,:),'LineWidth',2);

hold on;
G = plot(x_h_values,normcdf(x_h_values,0,1),'color',bincolors(i,:),'LineWidth',2);xlabel('Translational MSD [\mum^2]');ylabel('CDF');
legend([F G],'Exp. CDF','Standard Normal CDF','Location','SE');

hold all;
end

subplot(2,3,3);
if i==3
x_MSD_T_mu=mean(out_xy(:,2)/(ppm.^2));
x_MSD_T_sigma=std(out_xy(:,2)/(ppm.^2));
x_h=(out_xy(:,2)/(ppm.^2)-x_MSD_T_mu)/x_MSD_T_sigma;

h=kstest(x_h)
[f,x_h_values] = ecdf(x_h);
F=plot(x_h_values,f,'s','color',bincolors(i,:),'LineWidth',2);

hold on;
G = plot(x_h_values,normcdf(x_h_values,0,1),'color',bincolors(i,:),'LineWidth',2);xlabel('Translational MSD [\mum^2]');ylabel('CDF');
legend([F G],'Exp. CDF','Standard Normal CDF','Location','SE');

hold all;
end

subplot(2,3,4);
if i==4
x_MSD_T_mu=mean(out_xy(:,2)/(ppm.^2));
x_MSD_T_sigma=std(out_xy(:,2)/(ppm.^2));
x_h=(out_xy(:,2)/(ppm.^2)-x_MSD_T_mu)/x_MSD_T_sigma;

h=kstest(x_h)
[f,x_h_values] = ecdf(x_h);
F=plot(x_h_values,f,'s','color',bincolors(i,:),'LineWidth',2);

hold on;
G = plot(x_h_values,normcdf(x_h_values,0,1),'color',bincolors(i,:),'LineWidth',2);xlabel('Translational MSD [\mum^2]');ylabel('CDF');
legend([F G],'Exp. CDF','Standard Normal CDF','Location','SE');

hold all;
end


subplot(2,3,5);
if i==5
x_MSD_T_mu=mean(out_xy(:,2)/(ppm.^2));
x_MSD_T_sigma=std(out_xy(:,2)/(ppm.^2));
x_h=(out_xy(:,2)/(ppm.^2)-x_MSD_T_mu)/x_MSD_T_sigma;

h=kstest(x_h)
[f,x_h_values] = ecdf(x_h);
F=plot(x_h_values,f,'s','color',bincolors(i,:),'LineWidth',2);

hold on;
G = plot(x_h_values,normcdf(x_h_values,0,1),'color',bincolors(i,:),'LineWidth',2);xlabel('Translational MSD [\mum^2]');ylabel('CDF');
legend([F G],'Exp. CDF','Standard Normal CDF','Location','SE');

hold all;
end

figure(2);
subplot(2,3,1);
if i==1
x_MSD_R_mu=mean(out_theta(:,2)/(dpr.^2));
x_MSD_R_sigma=std(out_theta(:,2)/(dpr.^2));
x_hr=(out_theta(:,2)/(dpr.^2)-x_MSD_R_mu)/x_MSD_R_sigma;
hr=kstest(x_hr)
[f_r,x_hr_values] = ecdf(x_hr);
F_r=plot(x_hr_values,f_r,'s','color',bincolors(i,:),'LineWidth',2);

hold on;
G_r = plot(x_hr_values,normcdf(x_hr_values,0,1),'color',bincolors(i,:),'LineWidth',2);xlabel('Rotational MSD [rad^2]');ylabel('CDF');
legend([F_r G_r],'Exp. CDF','Standard Normal CDF','Location','SE');

hold all;
end
subplot(2,3,2);
if i==2
x_MSD_R_mu=mean(out_theta(:,2)/(dpr.^2));
x_MSD_R_sigma=std(out_theta(:,2)/(dpr.^2));
x_hr=(out_theta(:,2)/(dpr.^2)-x_MSD_R_mu)/x_MSD_R_sigma;
hr=kstest(x_hr)
[f_r,x_hr_values] = ecdf(x_hr);
F_r=plot(x_hr_values,f_r,'s','color',bincolors(i,:),'LineWidth',2);

hold on;
G_r = plot(x_hr_values,normcdf(x_hr_values,0,1),'color',bincolors(i,:),'LineWidth',2);xlabel('Rotational MSD [rad^2]');ylabel('CDF');
legend([F_r G_r],'Exp. CDF','Standard Normal CDF','Location','SE');

hold all;
end

subplot(2,3,3);
if i==3
x_MSD_R_mu=mean(out_theta(:,2)/(dpr.^2));
x_MSD_R_sigma=std(out_theta(:,2)/(dpr.^2));
x_hr=(out_theta(:,2)/(dpr.^2)-x_MSD_R_mu)/x_MSD_R_sigma;
hr=kstest(x_hr)
[f_r,x_hr_values] = ecdf(x_hr);
F_r=plot(x_hr_values,f_r,'s','color',bincolors(i,:),'LineWidth',2);

hold on;
G_r = plot(x_hr_values,normcdf(x_hr_values,0,1),'color',bincolors(i,:),'LineWidth',2);xlabel('Rotational MSD [rad^2]');ylabel('CDF');
legend([F_r G_r],'Exp. CDF','Standard Normal CDF','Location','SE');

hold all;
end


subplot(2,3,4);
if i==4
x_MSD_R_mu=mean(out_theta(:,2)/(dpr.^2));
x_MSD_R_sigma=std(out_theta(:,2)/(dpr.^2));
x_hr=(out_theta(:,2)/(dpr.^2)-x_MSD_R_mu)/x_MSD_R_sigma;
hr=kstest(x_hr)
[f_r,x_hr_values] = ecdf(x_hr);
F_r=plot(x_hr_values,f_r,'s','color',bincolors(i,:),'LineWidth',2);

hold on;
G_r = plot(x_hr_values,normcdf(x_hr_values,0,1),'color',bincolors(i,:),'LineWidth',2);xlabel('Rotational MSD [rad^2]');ylabel('CDF');
legend([F_r G_r],'Exp. CDF','Standard Normal CDF','Location','SE');

hold all;
end

subplot(2,3,5);
if i==5
x_MSD_R_mu=mean(out_theta(:,2)/(dpr.^2));
x_MSD_R_sigma=std(out_theta(:,2)/(dpr.^2));
x_hr=(out_theta(:,2)/(dpr.^2)-x_MSD_R_mu)/x_MSD_R_sigma;
hr=kstest(x_hr)
[f_r,x_hr_values] = ecdf(x_hr);
F_r=plot(x_hr_values,f_r,'s','color',bincolors(i,:),'LineWidth',2);

hold on;
G_r = plot(x_hr_values,normcdf(x_hr_values,0,1),'color',bincolors(i,:),'LineWidth',2);xlabel('Rotational MSD [rad^2]');ylabel('CDF');
legend([F_r G_r],'Exp. CDF','Standard Normal CDF','Location','SE');

hold all;
end

end

%%
 for i=1:nbins

out_theta=[];

out_theta(:,1)=grp_msd_theta{i}(:,1);% time
out_theta(:,2)=grp_msd_theta{i}(:,2);% angular



out_xy=[];
T_1=[];

out_xy(:,1)=grp_msd_xy{i}(:,1); 
out_xy(:,2)=grp_msd_xy{i}(:,2);
x_MSD_T_mu=mean(out_xy(:,2)/(ppm.^2))
x_MSD_T_sigma=std(out_xy(:,2)/(ppm.^2))

data=normrnd(x_MSD_T_mu,x_MSD_T_sigma,1e4,1);

if i==1
[D PD] = allfitdist(data,'PDF');

end

if i==2
[D PD] = allfitdist(data,'PDF');hold all
end

if i==3
[D PD] = allfitdist(data,'PDF');hold all 
end

if i==4
[D PD] = allfitdist(data,'PDF');hold all
end

if i==5
[D PD] = allfitdist(data,'PDF');hold all
end
 end

%%

%%%%%caculate MSD using MSD function
% trks_part = trks;
% trks_part(:,3:8) = [];
% trks_theta = [trks(:,4) zeros(size(trks,1),1) trks(:,9:10)];
% out = MSD(trks_part);
% out_theta = MSD(trks_theta);


