%% average Boundaries

avgLayerBounds = [-488 0; 0 285.4; 285.4 588.8 ; 588.8 1039.4; -990 -488]; % [1 2 3 4 5]

 t = [0:0.03333:1.73];
%%
sessionID = 1;
figure
for sessionID =1:5
    allWaveforms(sessionID).scaled_depth = NaN(size(allWaveforms(sessionID).depth));
    
    sessionDepth = allWaveforms(sessionID).depth;
    if sessionID == 4
        layerBound = (allWaveforms(sessionID).depth_mat-allWaveforms(sessionID).depth_mat(1,1))*-1;
        layerBound = [layerBound(:,2), layerBound(:,1)];
        sessionDepth = sessionDepth*-1;
    elseif sessionID == 5
        layerBound = (allWaveforms(sessionID).depth_mat-allWaveforms(sessionID).depth_mat(1,1))*-1;
        layerBound = [layerBound(:,2), layerBound(:,1)];
        sessionDepth = sessionDepth*-1;
    else
        layerBound = allWaveforms(sessionID).depth_mat-allWaveforms(sessionID).depth_mat(1,2);
        sessionDepth = sessionDepth;
    end
    
    for layerID = 1:5

        mini = layerBound(layerID,1);
        maxi = layerBound(layerID,2);
        
        depthsBoundIdx = find(sessionDepth<=maxi & sessionDepth>=mini);
        depthsBound = sessionDepth(sessionDepth<=maxi & sessionDepth>=mini);
        
        
        %scaled = scaledDepths(avgLayerBounds(layerID,1),avgLayerBounds(layerID,2), depthsBound);
        scaled = rescale(depthsBound, avgLayerBounds(layerID,1),avgLayerBounds(layerID,2));
        allWaveforms(sessionID).scaled_depth(depthsBoundIdx) = scaled;
        disp(size(depthsBound))



    end

    
    %% Plotting
    normalizedwaveformspos = allWaveforms(sessionID).waveform.align_pos;
    normalizedwaveformsneg = allWaveforms(sessionID).waveform.align_neg;
    
    originalarray = allWaveforms(sessionID).scaled_depth;
    originalIDs = allWaveforms(sessionID).avg_waveformID;
    
    depth_pos = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_pos(:,1), originalarray);
    depth_neg = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_neg(:,1), originalarray);
    %% laminar figure scaled
    %t = t/10;
    time = linspace(0,82/30000*1000,82); % Time samples at 30000 Hz, 82 samples
    t = time(1:52); % Time samples at 30000 Hz, 52 samples
    a = 70; % this is the scale factor %100
    b = 10; % this is the scatter plot range %40
    ylabel('Distance from Layer 4 [um]')
    hold on
    for m = 1:size(normalizedwaveformsneg,1)
        r = 0 + (b-0)*rand();
        d = normalizedwaveformsneg(m,:)*a+depth_neg(m);
        plot(t+r,d,'color',[ 0.8902    0.5176    0.5176])
    end
    
    for n = 1:size(normalizedwaveformspos,1)
        r = 0 + (b-0)*rand();
        d = normalizedwaveformspos(n,:)*a+depth_pos(n);
        plot(t+r,d,'color',[0.2275    0.5961    0.8392])
        
    end
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)])
    set(gca,'xtick',[],'XColor', 'none')
    set(gcf,'renderer','Painters')
    %saveas(gcf, sprintf(['S',num2str(sessionID),' Waveforms']),'pdf')
    %disp(['Total Number of Waveforms in session ',num2str(sessionID),' = ',num2str(size(depth_all,1))])
    depth_all = [depth_neg; depth_pos];
        allWaveforms(sessionID).waveform.depth_all_scaled = depth_all;
        allWaveforms(sessionID).waveform.depth_pos_scaled = depth_pos;
        allWaveforms(sessionID).waveform.depth_neg_scaled = depth_neg;
        %saveas(gcf, sprintf(['S',num2str(sessionID),' Waveforms']),'pdf')
        disp(['Total Number of Waveforms in session ',num2str(sessionID),' = ',num2str(size(depth_all,1))])

        
        
end

 %print -depsc -tiff -r300 -painters scaledDepths.eps