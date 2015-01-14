%% odeRK4fs
%   M = odeRK4fs(M)
%
%  Fixed-step 4th-order Runge-Kutta ODE numerical integration.
%  Steps by *direct indexing* of stimulus vector.
%
%  Params
%   Model    
%
%  Output
%   M - Model

%%
function M = odeRK4fs(M)

clear global M
global M circular
load('MyColormaps', 'IF_colormap');
circular = IF_colormap;

zfun = M.dotfunc;
cfun = M.cfun;
s = M.s;
ispan = [1 length(s.x)];

%% Error checking
if( ~isa(zfun,'function_handle') )
    error('odeRK4fs: odefun param must be a function handle');
end
if(ispan(1) < 1)
    error('odeRK4fs: index start < 1: %f',ispan(1));
end
if(ispan(2) <= ispan(1) || ispan(2) > length(s.x))
    error('odeRK4fs: index stop out of range: %f',ispan(2));
end

step = single(1);
h = single(s.dt);                   % For variable step size, else h = dt;
numNet = length(M.n);

%% Display initial conditions if dStep > 0
for nx = 1:numNet
    if M.n{nx}.dStep
        networkDisplay(0, nx);
    end
    for cx = M.n{nx}.conLearn
        if M.n{nx}.con{cx}.dStep
            connectionDisplay(0, nx, cx);
        end
    end
end

%% Integration loop
for ix = ispan(1) : step : ispan(2)-step
    ind = ix; % time step for which to calculate k1
    
    %% Get Runge-Kutta k-values
    for kx = 1:4

        %% ... for each network
        for nx = 1:numNet
            M.n{nx}.k{kx} = h*zfun(ind, nx);

            %% ... and for each learned connection to the network
            for cx = M.n{nx}.conLearn
                M.n{nx}.con{cx}.k{kx} = h*cfun(nx, cx);
            end
        end
        
        %% Update z, C and ind for the next k-step
        switch kx
            case 1
                for nx = 1:numNet
                    M.n{nx}.zPrev = M.n{nx}.z;
                    M.n{nx}.z = M.n{nx}.zPrev + M.n{nx}.k{1}/2;
                    for cx = M.n{nx}.conLearn
                        M.n{nx}.con{cx}.CPrev = M.n{nx}.con{cx}.C;
                        M.n{nx}.con{cx}.C = M.n{nx}.con{cx}.CPrev + M.n{nx}.con{cx}.k{1}/2;
                    end
                end
                ind = ix + step/2; % time step for k2 and k3
            case 2
                for nx = 1:numNet
                    M.n{nx}.z = M.n{nx}.zPrev + M.n{nx}.k{2}/2;
                    for cx = M.n{nx}.conLearn
                        M.n{nx}.con{cx}.C = M.n{nx}.con{cx}.CPrev + M.n{nx}.con{cx}.k{2}/2;
                    end
                end
            case 3
                for nx = 1:numNet
                    M.n{nx}.z = M.n{nx}.zPrev + M.n{nx}.k{3};
                    for cx = M.n{nx}.conLearn
                        M.n{nx}.con{cx}.C = M.n{nx}.con{cx}.CPrev + M.n{nx}.con{cx}.k{3};
                    end
                end
                ind = ix + step; % time step for k4
            case 4
                for nx = 1:numNet
                    M.n{nx}.z = M.n{nx}.zPrev + ...
                        (M.n{nx}.k{1} + 2*M.n{nx}.k{2} + 2*M.n{nx}.k{3} + M.n{nx}.k{4})/6;
                    if M.n{nx}.sStep && ~mod(ix, M.n{nx}.sStep)
                        M.n{nx}.Z(:,ix/M.n{nx}.sStep+1) = M.n{nx}.z;
                    end
                    if M.n{nx}.dStep && ~mod(ix, M.n{nx}.dStep)
                        networkDisplay(ix, nx);
                    end
                    for cx = M.n{nx}.conLearn
                        M.n{nx}.con{cx}.C = M.n{nx}.con{cx}.CPrev + ...
                            (M.n{nx}.con{cx}.k{1} + 2*M.n{nx}.con{cx}.k{2} + 2*M.n{nx}.con{cx}.k{3} + M.n{nx}.con{cx}.k{4})/6;
                        if M.n{nx}.con{cx}.sStep && ~mod(ix, M.n{nx}.con{cx}.sStep)
                            M.n{nx}.con{cx}.C3(:,:,ix/M.n{nx}.con{cx}.sStep+1) = M.n{nx}.con{cx}.C;
                        end
                        if M.n{nx}.con{cx}.dStep && ~mod(ix, M.n{nx}.con{cx}.dStep)
                            connectionDisplay(ix, nx, cx);
                        end
                    end
                end
        end
    end
end
end

%% function: computes one 4th-order Runge-Kutta step
%   See http://www.physics.utah.edu/~detar/phys6720/handouts/ode/ode/node6.html
%
%  k1 = h*f(ti, yi)
%  k2 = h*f(ti+h/2, yi+k1/2)
%  k3 = h*f(ti+h/2, yi+k2/2)
%  k4 = h*f(t(i+1), yi+k3)
%
%  y(i+1) = yi + 1/6*(k1 + 2*k2 + 2*k3 + k4)

%% function: Displays instantaneous network state
function networkDisplay(ix, nx)
global M 
net = M.n{nx};
if ix == 0
    if isfield(net,'nAx') && ishghandle(net.nAx)
        axes(net.nAx)
    else
        figure(10000+nx);
    end
    
% Commenting out old way of doing this
% 
%     M.n{nx}.nH = plot(1:net.N, abs(net.z), '.-'); % nH: lineseries object handle
%     set(gca, 'YLim', [0 .8/sqrt(net.e)]);
%     set(gca, 'XTick', net.tck, 'XTickLabel', net.tckl);
    switch net.fspac
        case 'log'
            M.n{nx}.nH = semilogx(net.f, abs(net.z), '.-');  % nH: lineseries object handle
        case 'lin'
            M.n{nx}.nH = plot(net.f, abs(net.z), '.-');  % nH: lineseries object handle
    end
    title(sprintf('Amplitudes of oscillators in network %d',nx));
    xlabel('Oscillator natural frequency (Hz)');
    ylabel('Amplitude');
    set(gca, 'XLim',[min(net.f) max(net.f)]);
    set(gca, 'YLim', [0 1/sqrt(net.e)]);
    if ~isempty(net.tick)
        set(gca, 'XTick', net.tick);
    end
    
    grid
else
    set(net.nH, 'YData', abs(net.z));
end

drawnow

end

%% function: Displays instantaneous connection state
function connectionDisplay(ix, nx, cx)
global M circular
con = M.n{nx}.con{cx};
f1 = M.n{con.n1}.f;
f2 = M.n{con.n2}.f;
if ix == 0
    if isfield(con,'aAx') && ishghandle(con.aAx)
        axes(con.aAx)
    elseif ~ishghandle(10000+1000*nx+100*cx)
        figure(10000+1000*nx+100*cx);
        set(gcf, 'Position', [2 550 500 400]);
    else
        figure(10000+1000*nx+100*cx);
    end
    M.n{nx}.con{cx}.aH = imagesc(f1, f2, abs(con.C));
    title(sprintf('Amplitudes of connection matrix %d to network %d',cx,nx));
    xlabel(sprintf('Oscillator natural frequency (Hz): Network %d',M.n{con.n1}.id));
    ylabel(sprintf('Oscillator natural frequency (Hz): Network %d',nx));
    set(gca, 'xscale', 'log', 'yscale', 'log');
    set(gca, 'CLim', [.001 .75/sqrt(con.e)]);
    
% Commenting out old way of doing this
% 
%     set(gca, 'XTick', M.n{con.n1}.tck, 'XTickLabel', M.n{con.n1}.tckl)
%     set(gca, 'YTick', M.n{con.n2}.tck, 'YTickLabel', M.n{con.n2}.tckl)

    if ~isempty(M.n{con.n1}.tick)
        set(gca, 'XTick', M.n{con.n1}.tick);
    end
    
    if ~isempty(M.n{con.n2}.tick)
        set(gca, 'YTick', M.n{con.n2}.tick);
    end
    
    grid on
    colormap(flipud(hot)); colorbar;
    
    if isfield(con,'pAx') && ishghandle(con.pAx)
        axes(con.pAx)
    elseif ~ishghandle(10000+1000*nx+100*cx+1)
        figure(10000+1000*nx+100*cx+1);
        set(gcf, 'Position', [500 550 500 400]);
    else
        figure(10000+1000*nx+100*cx+1);  
    end
    M.n{nx}.con{cx}.pH = imagesc(f1, f2, angle(con.C));
    title(sprintf('Phases of connection matrix %d to network %d',cx,nx));
    xlabel(sprintf('Oscillator natural frequency (Hz): Network %d',M.n{con.n1}.id));
    ylabel(sprintf('Oscillator natural frequency (Hz): Network %d',nx));
    set(gca, 'xscale', 'log', 'yscale', 'log');
    set(gca, 'CLim', [-pi pi]);
    
% Commenting out old way of doing this
% 
%     set(gca, 'XTick', M.n{con.n1}.tck, 'XTickLabel', M.n{con.n1}.tckl)
%     set(gca, 'YTick', M.n{con.n2}.tck, 'YTickLabel', M.n{con.n2}.tckl)
    
    if ~isempty(M.n{con.n1}.tick)
        set(gca, 'XTick', M.n{con.n1}.tick);
    end
    
    if ~isempty(M.n{con.n2}.tick)
        set(gca, 'YTick', M.n{con.n2}.tick);
    end
    
    grid on
    colormap(circular);
    cb = colorbar;
    set(cb, 'YTick',      [-pi, -pi/2, 0, pi/2, pi])
    set(cb, 'YTickLabel', {sprintf('-pi  '); '-pi/2'; ' 0  '; ' pi/2'; ' pi  '})
    
else
    set(con.aH, 'CData', (abs(con.C)));
    set(con.pH, 'CData', angle(con.C));
end

drawnow

end
