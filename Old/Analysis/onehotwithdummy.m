%% 

k = 1
allData = A(:,[1]);
X = dummyvar(allData + 1);
X(:, end+1) = A(:,2);
%X(:,end+1) = 1;
 
[b,bi,c,ci,st] = regress(coeff(:,k), X); %z-scored candidate cell type(1.0), depth;
varExplained(6) = st(1);


X = dummyvar(allData + 1);
[b,bi,c,ci,st] = regress(coeff(:,k), X); %z-scored candidate cell type(1.0);
varExplained(7) = st(1);


%%

 X1 = A(:,[2 13 14]); % Depth; UMAP X; UMAP Y
 X1(:,end+1) = 1;
 
[b,bi,c,ci,st] = regress(coeff(:,k), X1); %z-scored candidate cell type(1.0);
%varExplained(7) = st(1);


%%
allData = A(:,[1]);
T = table(coeff(:,1), categorical(allData), A(:,2));
formula = 'Var1 ~ Var2 + Var3';
m1      = fitlme(T,formula,'DummyVarCoding', 'reference');

allData = A(:,[15]);
T = table(coeff(:,1), categorical(allData), A(:,2));
formula = 'Var1 ~ Var2 + Var3';
m2      = fitlme(T,formula,'DummyVarCoding', 'reference');