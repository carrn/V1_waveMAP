close all
N = [2:15];
Steps = 10.^[-5:.05:1.5];

for sessionID = 1:5
    HistogramISIn(allWaveforms(sessionID).spike_timing,N,Steps);
end