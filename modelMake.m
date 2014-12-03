%% modelMake
%  Input dotfunc handle first, then optionally cdot function handle.
%  Then stimulus structure, then each network structure.
%
%  Example calls:
%
%   m = modelMake(@zdot, s, n);
%   m = modelMake(@zdot, @cdot, s, n1, n2, n3);
%
%  collect output network with:
%  n = m.n{1};

%%
function model = modelMake(varargin)

  model.dotfunc      = varargin{1};
  if isa(varargin{2},'function_handle')
      model.cfun     = varargin{2};
      s              = varargin{3};
      ind            = 4;
  else
      model.cfun     = @cdot;
      s              = varargin{2};
      ind            = 3;
  end
  model.dt           = s.dt;
  model.tspan        = s.ts;
  
%% Make initial conditions. The varargs are the networks.
  model.n = varargin(ind:end);
  Nnets = length(model.n);
  z0 = [];
  for v = 1:Nnets
  
    z0 = [z0; model.n{v}.z0];
    
    t = s.t;

    if ~isempty(t) && model.n{v}.sStep > 0
        Nt = ceil(length(t)/model.n{v}.sStep);
        %model.n{v}.t = linspace(t(1), t(end), Nt);
        model.n{v}.t = t(1:model.n{v}.sStep:length(t));
        model.n{v}.Z = single(zeros(length(model.n{v}.z), Nt));
        model.n{v}.Z(:,1) = model.n{v}.z0;
    else
        model.n{v}.t = [];
        model.n{v}.Z = [];
    end
    
    for cx = model.n{v}.conLearn
        
        if ~isempty(t) && model.n{v}.con{cx}.sStep > 0
            Nt = ceil(length(t)/model.n{v}.con{cx}.sStep);
            %model.n{v}.con{cx}.t  = linspace(t(1), t(end), Nt);
            model.n{v}.con{cx}.t = t(1:model.n{v}.con{cx}.sStep:length(t));
            model.n{v}.con{cx}.C3 = single(zeros(size(model.n{v}.con{cx}.C,1), size(model.n{v}.con{cx}.C,2), Nt));
            model.n{v}.con{cx}.C3(:,:,1) = model.n{v}.con{cx}.C0;
        else
            model.n{v}.con{cx}.t  = [];
            model.n{v}.con{cx}.C3 = [];
        end

    end
    
  end
  model.z0 = z0;

  % Roll thru networks and make sure at least one is connected to stimulus
  stimcount = 0;
  for j = 1:length(model.n)
      stimcount = stimcount + model.n{j}.ext;
  end
  if ~ stimcount > 0
      model.n{1}.ext = 1;
  end
  
  % encapsulate stimulus in model
  model.s = s;

%% If dotfunc (override) option is empty, then use base dotfunc from network and oscillator-model

if isempty(model.dotfunc)
    n = varargin{1}; % for now, restrict to only one osc-model
    if strcmp(n.model, 'vdp')
        model.dotfunc = @zdotv;
    end
    if strcmp(n.model, 'wc')
        model.dotfunc = @zdotw_sc;
    end
    if strcmp(n.model, 'wce')
        model.dotfunc = @zdotw_sc;
    end
    if strcmp(n.model, 'hopft')
        model.dotfunc = @zdotw_sc;
    end
    if strcmp(n.model, 'hopfx')
        model.dotfunc = @zdotw_sc;
    end

end


n.gpuT  = @gpuT_undefined; 
