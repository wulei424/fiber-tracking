%=================================
%msd_calculator created by Eleanor Millman, June 2006
%
%PURPOSE: takes in a trajectory and calculates the mean squared
%         displacement(MSD) versus some time tau and the error associated with the
%         MSD
%
%INPUT: a nx2 matrix where the first column is time and the second column
%       is position (note: this program assumes the times are equally spaced and that n>1)
%
%OUTPUT: a nx3 matrix where the first column is tau, the second column is
%        MSD, and the third column is the error, the error associated with the MSD
%
%MODIFICATION HISTORY:
%       - March 2007: now can handle trajectories  with missing data --
%       make sure trajectory has all times, but put NaN's in for all the missing positions

function out=msd_distribution_calculator(trajectory, tau)

%=================================
%constants that can be played with

data_points=2;     %the number of datapoints needed to create a meaningful average

%=================================
%constants determined by input



dt=trajectory(2,1)-trajectory(1,1);  %the time interval

t=trajectory(end,1)-trajectory(1,1);  %the total time of the experiment

%=================================
%calculations

%calculate the mean squared displacement
[~,nc] = size(trajectory);

c = tau/dt;

    msd=0;    %mean squared displacement
    squared_displacement=[];  %the list of squared displacements put together to
    n=floor(t/tau)-1;  %the number of squared displacements averaged together to get the msd
    
    for index=1:n
        if nc == 3
        squared_displacement=[ squared_displacement ; ...
            (trajectory(c*(index+1),2)-trajectory(c*index,2))^2 ...
            + (trajectory(c*(index+1),3)-trajectory(c*index,3))^2];
        else
            squared_displacement=[ squared_displacement ; ...
            (trajectory(c*(index+1),2)-trajectory(c*index,2))^2];
        end
    end
    
    squared_displacement=squared_displacement(isfinite(squared_displacement));
    n=length(squared_displacement);
    
    output{1}=tau;
    output{2}=sum(squared_displacement)/n;
    output{3}=std(squared_displacement)/sqrt(n);
    
    output{4}= squared_displacement/tau;
    
    % do histogram here or somewhere else
    
    


%=================================
%return data

out=output;