% img=mIJ.getCurrentImage;
imlst = dir('Series016*tif');
for kk=1:length(imlst)
    im = (imread(imlst(kk).name));  % read the image
    img(:,:,kk)=im;
end
%%

mv=true;
% mv = input('make movie?:');
if mv
    ensureeven=true;
    aviobj = VideoWriter('Series016.avi','Uncompressed AVI');
    aviobj.FrameRate = 20; %aviobj.Quality = 100;
    open(aviobj);
end

recalc=true;

for kk=1:size(img,3)
    
    
    I=img(:,:,kk);
    
        if recalc

    
    %I2=(imdenoise(double(I),7,1e-3));
    %lvl=graythresh(getNormalized(I2));
    %bw=im2bw(getNormalized(I2),lvl);
    %bw2=(bwareaopen(bw,50));
    
    I2=bpass(double(I),1,31);
    th=2;
    bw=I2>th;
    bw2=(bwareaopen(bw,20));
    
    stats=regionprops(bw2,'Centroid','Orientation','MajorAxisLength','MinorAxisLength');
    else
        stats=allstats{kk};
    
    end
    
    figure(1);
    
    imagesc(I); hold all;for k=1:length(stats); plot(stats(k).Centroid(1),stats(k).Centroid(2),'r+'); plot_ellipse(stats(k).MajorAxisLength/2,stats(k).MinorAxisLength/2,degtorad(180-stats(k).Orientation),stats(k).Centroid(1),stats(k).Centroid(2),'k'); hold all;end
    title(['frame = ',int2str(kk)])
    hold off;
    if mv
        frame=getframe;
        if ensureeven
            %drop points from the edges of the frame if it has an odd
            %number of pixels
            ysize=size(frame.cdata,1);
            xsize=size(frame.cdata,2);
            frame.cdata=frame.cdata(1:(2*floor(ysize/2)),1:(2*floor(xsize/2)),:);
        end
        writeVideo(aviobj,frame);
    end
    
    allstats{kk}=stats;
    
    
    pause(0.01);
    
end


if mv
    close(aviobj);
end
save('Series016.mat','img','allstats');

%convert video using
%ffmpeg -r 30 -i "Series016.avi" -c:v libx264 -crf 23 -pix_fmt yuv420p Series016.mp4
