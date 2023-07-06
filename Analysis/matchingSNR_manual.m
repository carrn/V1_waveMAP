function [matchingunits, icc] = matchingSNR_manual(smaller,larger)
% This fuction takes two matrices containing true unit ID numbers, 
% and compares the two for matching units    
    hh = ismember(smaller,larger); 
    matchingunits = hh(:,1);              % Logical array size of larger matrix
    icc = sum(matchingunits)/size(hh,1);  % ICC Score of how well matched 
    
end


