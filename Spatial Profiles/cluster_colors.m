colors = {'#054b7d','#2e94db','#fe7f2d','#9d0208','#f0cb67','#8bcdfc','#00c49a','#35c8db','#ab8620'};
clusterColors = [];
layerColors = [];
for colorID = 1:length(colors)
    
    
    currColor = hex2rgb(colors(colorID));
    clusterColors = [clusterColors, {currColor}];
%     for layerID = 1:size(colors,1)
%         
%         currColor = hex2rgb(colorsByLayer(layerID,colorID));
%         layerColors = [layerColors, {currColor}];
%         
%     end
end