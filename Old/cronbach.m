function a=cronbach(X)

% X is the data matrix with each column representing one rater
% and each row representing the nominal score given to each waveform
% with 0 = artifact, 1 = good, 0.5 = noisy


% Calculate the number of items
k=size(X,2);
% Calculate the variance of the items' sum
VarTotal=var(sum(X'));
% Calculate the item variance
SumVarX=sum(var(X));
% Calculate the Cronbach's alpha
a=k/(k-1)*(VarTotal-SumVarX)/VarTotal;


end