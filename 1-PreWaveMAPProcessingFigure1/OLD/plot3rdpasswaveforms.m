% Previous steps:
% - Shude_waveforms_extract_ID.m - normalizes and averages all waveforms, snr
% sort
% - Waves1.m - 2 Pass Manual Sort
% - manualsort_ID_extract.m - normalizes and averages manual sort waveforms
% - compareSNRandWaveform.m - compares the SNR sorted waveforms to the manual sorted waveforms
%
% This program requires:
% - extractarray()
%
% Outputs:
% - plots of final waveforms to be exported to WaveMAP
figure

for sessionID = 1:maxsession
    
    normalizedwaveformspos = allWaveforms(sessionID).waveform.align_pos;
    normalizedwaveformsneg = allWaveforms(sessionID).waveform.align_neg;
    
    originalarray = allWaveforms(sessionID).depth;
    originalIDs = allWaveforms(sessionID).avg_waveformID;
    
    depth_pos = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_pos(:,1), originalarray);
    depth_neg = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_neg(:,1), originalarray);
    %% normalized waveform figure
    %t = [0:0.03333:1.73]; % Time samples at 30000 Hz, 52 samples
    time = linspace(0,82/30000*1000,82); % Time samples at 30000 Hz, 82 samples
    t = time(1:52); % Time samples at 30000 Hz, 52 samples
    subplot(5,1,sessionID)
    
    title(sprintf(['S',num2str(sessionID),' Waveforms']))
    ylabel('Normalized Amplitude')
    xlabel('Time [ms]')
    plot(t, normalizedwaveformsneg,'color',[ 0.8902    0.5176    0.5176])
    hold on
    plot(t, normalizedwaveformspos,'color',[0.2275    0.5961    0.8392])
    
    hold on
    %set(gca,'xtick',[],'XColor', 'none')
    set(gca,'box','off','TickDir','out')
end
% print -depsc -tiff -r300 -painters allsessionsWaveforms.eps
%%
figure
for sessionID = 1:maxsession
    
    normalizedwaveformspos = allWaveforms(sessionID).waveform.align_pos;
    normalizedwaveformsneg = allWaveforms(sessionID).waveform.align_neg;
    
    originalarray = allWaveforms(sessionID).depth;
    originalIDs = allWaveforms(sessionID).avg_waveformID;
    
    depth_pos = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_pos(:,1), originalarray);
    depth_neg = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_neg(:,1), originalarray);
    % laminar figure
    %t = t/10;
    a = 100; % this is the scale factor
    b = 10; % this is the scatter plot range
    subplot(1,5,sessionID)
    ylabel('Distance from Layer 4 [um]')
    hold on
    for m = 1:size(normalizedwaveformsneg,1)
        r = 0 + (b-0)*rand();
        d = normalizedwaveformsneg(m,:)*a+depth_neg(m);
        plot(t+r,d,'color',[ 0.8902    0.5176    0.5176])
        hold on
    end
    
    for n = 1:size(normalizedwaveformspos,1)
        r = 0 + (b-0)*rand();
        d = normalizedwaveformspos(n,:)*a+depth_pos(n);
        plot(t+r,d,'color',[0.2275    0.5961    0.8392])
        hold on
    end
    %ylim([-1500 3000])
    hold on
    if sessionID == 4
        
        yline(([allWaveforms(sessionID).depth_mat(:,1); allWaveforms(sessionID).depth_mat(5,2)]-allWaveforms(sessionID).depth_mat(1,1)));
        ylim([-1500 3000])
        
    elseif sessionID == 5
        yline(([allWaveforms(sessionID).depth_mat(:,1); allWaveforms(sessionID).depth_mat(5,2)]-allWaveforms(sessionID).depth_mat(1,1)));
        ylim([-1500 3000])
    else
        yline(([allWaveforms(sessionID).depth_mat(:,1); allWaveforms(sessionID).depth_mat(4,2)]-allWaveforms(sessionID).depth_mat(1,2)));
        ylim([-1500 2000])
        
    end
    hold on
    
    % avgLayerBounds = [ 0 -488; 285.4 0; 588.8 285.4; 1039.4 588.8; -488 -990];
    % yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'LineWidth',3)
    depth_all = [depth_neg; depth_pos];
    allWaveforms(sessionID).waveform.depth_all = depth_all;
    allWaveforms(sessionID).waveform.depth_pos = depth_pos;
    allWaveforms(sessionID).waveform.depth_neg = depth_neg;
    %saveas(gcf, sprintf(['S',num2str(sessionID),' Waveforms']),'pdf')
    disp(['Total Number of Waveforms in session ',num2str(sessionID),' = ',num2str(size(allWaveforms(sessionID).waveform.ID_all,1))])
    set(gca,'box','off','TickDir','out')
end
%set(gca,'xtick',[],'XColor', 'none')
% print -depsc -tiff -r300 -painters allsessionsDepths.eps
%%
%  sessionID = 2;
%
% yline(([allWaveforms(sessionID).depth_mat(:,1); allWaveforms(sessionID).depth_mat(5,2)]-allWaveforms(sessionID).depth_mat(1,1)));
% ylim([-1500 3000])
% set(gca,'xtick',[],'XColor', 'none')
% set(gcf,'renderer','Painters')
% print -depsc -tiff -r300 -painters session2raw.eps