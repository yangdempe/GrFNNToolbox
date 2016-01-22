function [X1i, X2i, Zi, N1, N2, D, CON1, CON2, mask] = threeFreqMatsAll(fromFreqs, toFreqs)

if nargin < 2
    toFreqs = fromFreqs; 
    selfie = true;
else
    selfie = false;
end

N1 = length(fromFreqs);
N2 = length(toFreqs);
tol = .01;


% THese are the resonant relationships we are looking for.
% All up to a certain order. We could use an algorithm to
% generate these ...
k1 = [ 1,  1]'; %,  1,  1,  1,  1,  2 % ,  1,  1, -1,  2,  2, -2
k2 = [ 1, -1]'; %,  1, -1,  2, -2, -1 % ,  3, -3,  3,  3, -3,  3
m  = [ 1,  1]'; %,  2,  2,  1,  1,  1 % ,  1,  1,  1,  1,  1,  1

% Mesh grid does this differently from the way I think
% about it. But this seems to be the right way to do it.
% Something about the way ind2sub (below) works, probably.
[F2, F1, Ft] = meshgrid(fromFreqs, fromFreqs, toFreqs);

IDX = []; K1 = []; K2 = []; M = [];
for nn = 1:length(k1)
    % Test for the resonant relations
%     if selfie
        idx = find( (F1 ~= F2) & (F1 ~= Ft) & (F2 ~= Ft) & ...
                    (abs(k1(nn)*F1) >= abs(k2(nn)*F2)) & ...
                    (abs(k1(nn)*F1 + k2(nn)*F2 - m(nn)*Ft) < m(nn)*Ft*tol) );
%     else  
%         idx = find( (F1 ~= F2) & ...
%                     (abs(k1(nn)*F1) >= abs(k2(nn)*F2)) & ...
%                     (abs(k1(nn)*F1 + k2(nn)*F2 - m(nn)*Ft) < m(nn)*Ft*tol) );
%     end
    % These are the indices
    IDX = [IDX; idx];
    
    % These are the cooeficients of the resonant relationships
    K1  = [K1;  k1(nn)*ones(size(idx))];
    K2  = [K2;  k2(nn)*ones(size(idx))];
    M   = [M ;  m(nn) *ones(size(idx))];
end

% Now we decode the indices into vectors 
[f1, f2, ft] = ind2sub([N1,N2,N2], IDX);

% Sort to make the next step easier
[tmp sortorder] = sort(ft);
f1 = f1(sortorder);
f2 = f2(sortorder);
ft = ft(sortorder);
K1 = K1(sortorder);
K2 = K2(sortorder);
M  = M (sortorder);

% Put the results into 2D matrices, where rows correspons to toFreqs
% and columns contain pairs (ugly, but it works!)
iiprev = 0;
nn = 0;
for ii = ft'
    ii;
    nn = nn + 1;
    if ii == iiprev 
        jj = jj + 1;
    else 
        jj = 1;
    end
    X1i(ii,jj) = f1(nn);
    X2i(ii,jj) = f2(nn);
    Zi(ii,jj)  = ft(nn);
    N1(ii,jj)  = K1(nn);
    N2(ii,jj)  = K2(nn);
    D(ii,jj)   = M(nn);
    
    iiprev = ii;
end

mask = X1i>0;

% Now these are indices into the state vectors
% zeros are not allowed, so we replace them with
% ones. They remain zeroed out in the exponent 
% matrices. And we have a mask.
X1i(find(X1i==0))=1;
X2i(find(X2i==0))=1;
Zi (find(Zi ==0))=1;
D  (find(D ==0))=1;

% These tells which variable need to be conjugated
CON1 = N1<0;
CON2 = N2<0;

% And then the exponents themselves are all positive
N1 = abs(N1);
N2 = abs(N2);