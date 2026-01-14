reviewer1 = gooda;
reviewer2 = good;
reject = [];
storage = [];
inarray = 0;
for i = 1:length(reviewer2)
    x = reviewer2(i);
    inarray = 0;
    for j = 1:length(reviewer1)
        y = reviewer1(j);
        if x == y
            storage = [storage,reviewer2(i)];
        end  
    end    
end
reject = setxor(reviewer1,reviewer2);
secondr = [reject' ; noisya' ; noisy'];
secondr2 = [secondr'];
secondr2 = unique(secondr2);

data_path = '/Users/alecperliss/Downloads';
filename = 'manualsort_ID.mat';
full_filename = fullfile(data_path, filename);
load(full_filename);
secondalign = [];
for i = 1:length(secondr2)
   for j = 1:length(ID_all)
       if secondr(i) == ID_all(j)
       secondalign = [secondalign,j];
       end
    end
   savesecondalign = 'secondalign.mat';
   save(savesecondalign,'secondalign')
end
