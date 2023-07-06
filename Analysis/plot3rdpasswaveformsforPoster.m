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
maxsession = 5;
minsession = 2;
close all
figure
count = 1;
for sessionID = [minsession maxsession]

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
    subplot(2,1,count)
    hold on
    title(sprintf(['S',num2str(sessionID),' Waveforms']))
    ylabel('Normalized Amplitude')
    xlabel('Time [ms]')
    plot(t, normalizedwaveformsneg,'color',[ 0.8902    0.5176    0.5176])
    plot(t, normalizedwaveformspos,'color',[0.2275    0.5961    0.8392])
    set(gca,'TickDir','out')
   count = count + 1;
end
 print -depsc -tiff -r300 -painters cleanwaveforms.eps
%%
figure
count = 1;
for sessionID = [minsession maxsession]
normalizedwaveformspos = allWaveforms(sessionID).waveform.align_pos;
normalizedwaveformsneg = allWaveforms(sessionID).waveform.align_neg;

originalarray = allWaveforms(sessionID).depth;
originalIDs = allWaveforms(sessionID).avg_waveformID;

depth_pos = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_pos(:,1), originalarray);
depth_neg = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_neg(:,1), originalarray);
    %% laminar figure
    %t = t/10;
    a = 100; % this is the scale factor
    b = 15; % this is the scatter plot range
    subplot(1,2,count)
    ylabel('Distance from Layer 4 (um)')
    hold on
    title(sprintf(['S',num2str(sessionID),' Waveforms']))
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
    %ylim([-1500 3000])
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
    set(gca,'xtick',[],'XColor', 'none','TickDir','out')
    set(gcf,'renderer','Painters')
%     depth_all = [depth_neg; depth_pos];
%     allWaveforms(sessionID).waveform.depth_all = depth_all;
%     allWaveforms(sessionID).waveform.depth_pos = depth_pos;
%     allWaveforms(sessionID).waveform.depth_neg = depth_neg;
    %saveas(gcf, sprintf(['S',num2str(sessionID),' Waveforms']),'pdf')
    %disp(['Total Number of Waveforms in session ',num2str(sessionID),' = ',num2str(size(depth_all,1))])
    count = count + 1;
end

%%
%  sessionID = 2;
% 
% yline(([allWaveforms(sessionID).depth_mat(:,1); allWaveforms(sessionID).depth_mat(5,2)]-allWaveforms(sessionID).depth_mat(1,1)));
% ylim([-1500 3000])
% set(gca,'xtick',[],'XColor', 'none')
% set(gcf,'renderer','Painters')
% print -depsc -tiff -r300 -painters cleanwaveformsdepths.eps