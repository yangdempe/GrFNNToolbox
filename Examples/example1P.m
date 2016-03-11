%% example1P.m
%
% A one layer network with plastic internal connections (and no input)
%
% https://github.com/MusicDynamicsLab/GrFNNToolbox/wiki/05.-Example-1-Plastic

%% Network parameters
alpha = 1; beta1 = -1; beta2 = -1000; neps = 1; % Limit Cycle

%% Parameter sets for Hebbian plasiticity
w = .05;
% lambda =  -.1; mu1 =  0; mu2 =  0; ceps =  4; kappa = 1; % Linear learning rule
% lambda =   0; mu1 = -1; mu2 = -50; ceps =  4; kappa = 1; % Critical learning rule
% lambda =   0; mu1 = -1; mu2 = -50; ceps = 16; kappa = 1; % Critical, stronger nonlinearity
lambda = .001; mu1 = -1; mu2 = -50; ceps = 16; kappa = 1; % Supercritical learning rule

%% Make the model
s = stimulusMake(1, 'fcn', [0 100], 40, {'exp'}, 1, 0);

n = networkMake(1, 'hopf', alpha, beta1,  beta2, 0, 0, neps, ...
    'log', .5, 2, 201, 'save', 1, ...
    'display', 10, 'Tick', [.5 .67 .75 1 1.25 1.33 1.50 2]);

n = connectAdd(n, n, [], 'weight', w, 'type', 'all2freq', ...
    'learn', lambda, mu1, mu2, ceps, kappa, ...
    'display', 10,'phasedisp', 'save', 500);

M = modelMake(@zdot, @cdot, s, n);
% M = modelMake(@zdot_gpu, @cdot_gpu, s, n_; % uncomment to use gpu

M.odefun = @odeRK4fs;
% M.odefun = @odeRK4fs_gpu; % uncomment to use gpu

tic;
M = M.odefun(M);
toc;

% <<<<<<< HEAD
% % M = modelMake(@zdot, @cdot, s, n);
% evalc('M = modelMake(@zdot, @cdot, s, n);');
% =======
% if usegpu
%     
%     M = modelMake(@zdot_gpu, @cdot_gpu, s, n);
% >>>>>>> gpu
%         % The network is not connected to the stimulus, but the model needs
%         % a stimulus to get a time vector
%         
%     %% Run the network
%     
%     tic
%     Mtemp = odeRK4fs_gpu(M);
%     toc
%     
%     for i = 1:numel(M.n)
%         M.n{i}.Z = Mtemp.n{i}.Z;
%     end
%     
% else
%     
%     M = modelMake(@zdot, @cdot, s, n);
%     
%     %% Run the network
%     
%     tic
%     M = odeRK4fs(M);
%     toc
%     
% end

% outputDisplay(M, 'net', 1, a1, 'ampx', a2, 'fft', a3, 'oscfft')