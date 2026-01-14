function [S,errormsg] = reshape_traj(waveform)
% this function plots waveforms from data matrix size N x M
% file locations = s.obj.eventSeriesHash.value{i}.waveforms
%waveform = data matrix
%
%each waveform should be -10+y+21 voltage traces at 25kHz


l = size(waveform);
B = waveform;
BB = max(abs(B'));

% delete repeats, takes the first value
[x,y] = find(BB==abs(B'));
[uniqueA, yy,xx] = unique(y,'first');
x = x(yy);

%in case window is not matching
try
    for i = 1:length(x)
        X = x(i);
        Y = y(i);
        if X > 10
            S(i,:) = (B(Y,(X-11):(X+40)));
        else
            X = round(mean(x));
            S(i,:) = (B(Y,(X-11):(X+40)));
        end
    end

catch
    S = NaN(11,52);
    errormsg = sprintf('Unable to choose window')
end

end