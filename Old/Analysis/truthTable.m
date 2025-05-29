TruthTable = [];
for sessionID = 1:5
    truthRow = [];
    for clusterID = 1:5

        
        a = size(allWaveforms(sessionID).clusters(clusterID).ID,1);
        truthRow = [truthRow , a];

    end
    TruthTable = [TruthTable ; truthRow];
end
