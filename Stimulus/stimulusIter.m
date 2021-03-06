%% stimulusIter
%  y = stimulusIter(y, iter, Niter)
%
%  Transforms signal vector y with a delay-and-add circuit using iter,
%  length of delay in samples, and Niter, number of iterations.

%%
function y = stimulusIter(y, iter, Niter)

xx = zeros(size(y));

for i = 1:Niter                           % delay-and-add circuit for making
    xx(1:end-iter) = y(iter+1:end);       % iterated ripple noise. This method
    xx(end-iter+1:end) = y(1:iter);       % does not change length of s.x
    y = (xx + y) / 2;
end