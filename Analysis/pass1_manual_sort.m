pass1_manual = load('storage.mat', 'storage');
manualpass1_templates = load('manualsort_normalizedwaveforms.mat', 'align_all');
manualpass1_templates = manualpass1_templates.align_all;
p = 3;
for i = 1:max(storage(:,2))
    
    allWaveforms(i).manualpass1_ID = sort(storage(storage(:,2) == i));
    allWaveforms(i).manualpass1_templates = manualpass1_templates(storage(:,2) == i,:);
    
end



manualpass1_align_all = cat(1,allWaveforms(1:p).manualpass1_templates); 

