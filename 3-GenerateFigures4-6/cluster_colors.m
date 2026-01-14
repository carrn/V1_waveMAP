res1_0 = {'#054b7d','#2e94db','#fe7f2d','#9d0208','#f0cb67','#416EB6','#00c49a','#17A9C9','#896B29'};
colors_gen ={'#93CEB3','#C5E3EA','#F2D0BF'};%,'#9d0208','#f0cb67','#8bcdfc','#00c49a','#35c8db','#ab8620'}; Old colors
colors_layer = {'#B9529F','#3953A4','#6ABD45','#E8D652','#5C21EA','#ffffff'}; % 5/6, 4C, 4AB, 2/3, WM, NAN
colors_cluster = {'#054b7d','#416EB6','#fe7f2d','#9d0208','#f0cb67','#8bcdfc','#00c49a','#17A9C9','#896B29'};
colors_7 = {'#33BA97','#287C64','#FFFFFF'};
colors = colors_cluster;
clusterColors = [];
layerColors = [];
for colorID = 1:length(colors)

    currColor = hex2rgb(colors(colorID));
    clusterColors = [clusterColors, {currColor}];

end

colors = clusterColors;