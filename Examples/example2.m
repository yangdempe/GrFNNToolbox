%% example2.m
%
% A simple afferent chain network with no learning

%% Explore different parameter sets
alpha1 = 0.01; beta11 = -1; beta12 =  -10; neps1 = 1; % Linear
alpha2 =   -1; beta21 =  4; beta22 =  -3; neps2 = 1; % Critical

%% Make the model
s = stimulusMake('fcn', [0 1], 4000, {'exp'}, [100], .025, 0, 'ramp', 0.01, 1);
stimulusShow(s, 1); drawnow;

n1 = networkMake(1, 'hopf', alpha1, beta11,  beta12,  0, 0, neps1, ...
                    'log', 50, 200, 200, 'channel', 1, 'save', 1, ...
                    'display', 10, 'Tick', [50 67 75 100 133 150 200]);
n2 = networkMake(2, 'hopf', alpha2, beta21,  beta22,  0, 0, neps2, ...
                    'log', 50, 200, 200, 'save', 1, ...
                    'display', 10, 'Tick', [50 67 75 100 133 150 200]);

C     = connectMake(n1, n2, 'one', 1, 1);
n2    = connectAdd(n1, n2,  C, 'weight', 1, 'type', '1freq');

M = modelMake(@zdot, @cdot, s, n1, n2);

%% Run the network
tic
M = odeRK4fs(M);
toc

%% Display the output
figure(11); clf;
a1 = subplot(2,1,1);
a2 = subplot(2,1,2);

outputDisplay(M,'net',1,a1,'ampx')
outputDisplay(M,'net',2,a2,'ampx')

figure(12); clf;
a3 = subplot(2,1,1);
a4 = subplot(2,1,2);

outputDisplay(M,'net',1,a3,'fft')
outputDisplay(M,'net',2,a4,'fft')