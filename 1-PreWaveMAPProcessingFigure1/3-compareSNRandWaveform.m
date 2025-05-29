% compares the SNR sorted waveforms to the manual sorted waveforms
% Requires:
% - SNR sorted waveform unit IDs and avg waveforms
% - manual sorted waveform unit IDs and avg waveforms
% - matchingSNR_manual.m function that returns a logical array of all
%  units in that session (1 if matching, 0, if not), and an icc (intra
%  class correlation) score
%
% Outputs:
% - allWaveforms(sessionID).waveform
%   This contains IDs, depths, and logical array of matching units
for sessionID = 1:5
    
    [matchingunits_all, icc] = matchingSNR_manual(allWaveforms(sessionID).snrsort.ID_all, allWaveforms(sessionID).manual.ID_all);
    [matchingunits_pos, ~] = matchingSNR_manual(allWaveforms(sessionID).snrsort.ID_pos, allWaveforms(sessionID).manual.ID_pos);
    [matchingunits_neg, ~] = matchingSNR_manual(allWaveforms(sessionID).snrsort.ID_neg, allWaveforms(sessionID).manual.ID_neg);
    
    
    allWaveforms(sessionID).waveform.all = matchingunits_all;
    allWaveforms(sessionID).waveform.icc = icc;
    allWaveforms(sessionID).waveform.ID_all = allWaveforms(sessionID).snrsort.ID_all(matchingunits_all,:);
    allWaveforms(sessionID).waveform.align_all = allWaveforms(sessionID).snrsort.align_all(matchingunits_all,:);
    allWaveforms(sessionID).waveform.pos = matchingunits_pos;
    allWaveforms(sessionID).waveform.ID_pos = allWaveforms(sessionID).snrsort.ID_pos(matchingunits_pos,:);
    allWaveforms(sessionID).waveform.align_pos = allWaveforms(sessionID).snrsort.align_pos(matchingunits_pos,:);
    allWaveforms(sessionID).waveform.neg = matchingunits_neg;
    allWaveforms(sessionID).waveform.ID_neg = allWaveforms(sessionID).snrsort.ID_neg(matchingunits_neg,:);
    allWaveforms(sessionID).waveform.align_neg = allWaveforms(sessionID).snrsort.align_neg(matchingunits_neg,:);
    
end



