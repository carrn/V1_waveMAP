function [desiredarray, realdesiredIDs, H, hh] = extractarray(originalIDs, desiredIDs, originalarray)
    % originalIDs = # units in session x 2 array of all unit IDs in session, this should
    % always be allWaveforms(sessionID).avg_waveformID.
    %
    % originalarray = # units in session x data type array of data type,
    % ie. depth, avg_waveform, stimID etc.
    %
    % - desiredIDs = n x 1 array of desired unit IDs
    % - desiredarray = n x data type
    % - H = # units in session x 1 logical array of matching units
    
    hh = ismember(originalIDs,desiredIDs);% # units in session x 2 logical array, true if desiredIDs present in originalID array
    H = hh(:,1);                          % # units in session x 1 logical array of matching units
    desiredarray = originalarray(H,:);    % 
    realdesiredIDs = originalIDs(H,:);    % 
    
end