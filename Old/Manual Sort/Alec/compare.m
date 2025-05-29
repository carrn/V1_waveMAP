a = gooda;
n = good;
reject = [];
storage = [];
inarray = 0;
for i = 1:length(n)
    x = n(i);
    inarray = 0;
    for j = 1:length(a)
        y = a(j);
        if x == y
            storage = [storage,n(i)];
        end  
    end    
end
reject = setxor(a,n);
secondr = [reject' ; noisya' ; noisy'];
secondr2 = [secondr'];
secondr2 = unique(secondr2);
data_path = '/Users/alecperliss/Downloads';
filename = 'S1_manualsort_ID.mat';
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
