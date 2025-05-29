function [fr] = firing_rate(templateID, stim_onset, spike_timing, spikeID)
% this functioncalculates the firing rate for a unit 300 ms before, after, and during stimulus
% 
% templateID = ID of the unit analyzed
% stim_onset = the Nx1 matrix containing times of stim onset
% spike_timing = the Mx1 matrix containing times of spiking
% spikeID = the Mx1 matrix containing ID of the spike at the time


events = find(stim_onset)





end