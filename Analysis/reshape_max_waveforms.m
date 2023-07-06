function [S,errormsg] = reshape_max_waveforms(waveform)
% this function plots waveforms from waveform 1 x M
% file locations = s.obj.eventSeriesHash.value{i}.waveforms
%waveform = data matrix
%
%each waveform should be -10+y+21 voltage traces at 25kHz


l = size(waveform);
R = waveform;
A = abs(R);
% find minimum
maximum = max(R);
[x,y] = find(R==maximum);

try
    S = (R(1,(y-11):(y+40)));
catch
    errormsg = sprintf('Unable to choose window')
    
end

end