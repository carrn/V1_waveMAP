idx = 4;
array_name = align_pos;
unitID = allWaveforms.ID_pos(idx);


figure; 
plot(array_name(idx,:));

figure; 
plot(allWaveforms.avg_waveform(allWaveforms.avg_waveformID(:, 1) ==unitID, :));


