function [matchingunits, icc] = matchingSNR_manual(smaller,larger)


    %[ ~,jj]=ismember(A,B)
    hh = ismember(smaller,larger);
    matchingunits = hh(:,1);
    icc = sum(matchingunits);%/size(hh,1)
    
    
end
