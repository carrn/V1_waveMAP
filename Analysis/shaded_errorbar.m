function [S] = shaded_errorbar(time, avg, error_avg, color, alpha, LineStyle, LineWidth)


 if ~exist('LineStyle','var')
     % third parameter does not exist, so default it to something
      LineStyle = '-';
 end
 
 
 if ~exist('LineWidth','var')
     % third parameter does not exist, so default it to something
      LineWidth = 1;
 end

plot(time, avg,'color', color, 'Linestyle',LineStyle,'Linewidth',LineWidth)
hold on
patch = fill([time fliplr(time)] , [avg+error_avg , fliplr(avg-error_avg)], color);
set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
hold on;
