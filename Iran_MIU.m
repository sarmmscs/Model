function varargout = Iran_MIU(action,varargin)
% IRAN MIU — چهار فایل، اجرای مستقل از نسخه قبلی، Dynare 6.3 / 7.1
% همه چهار فایل را کنار هم استخراج کنید و پوشه را Current Folder متلب کنید.
% اجرا:              runDir = Iran_MIU;
% مسیر دلخواه:       runDir = Iran_MIU('run','C:\dynare\7.1\matlab');
% ساخت دوباره گزارش بدون تخمین: Iran_MIU('report');
% داشبورد:           Iran_DSGE_Pro_Lab
%
% فقط تنظیمات ابتدای تابع settings را تغییر دهید. زیرتوابع انتهای فایل
% جایگزین پوشه توابع کمکی شده‌اند و برای اجرا نیازی به ویرایش آنها نیست.
% داده: نرخ‌های فصلیِ لگاریتمیِ میانگین‌زدایی‌شده، بدون ضرب در ۱۰۰.
% obs_pi تورم؛ obs_mu رشد اسمی پایه پولی؛ obs_dy رشد GDP حقیقی؛
% obs_dm رشد M1 حقیقی. year_jalali و quarter فقط برچسب تقویم شمسی‌اند.
% نمونه: ۱۳۷۰Q۲ تا ۱۴۰۴Q۳؛ GDP با تعدیل فصلی برآوردی پایگاه داده؛
% CPI/M1/پایه پولی با اثرات ثابت فصل در لگاریتم. بدون فیلتر HP.
% منبع داده: Iran_Database20261102.zip؛ میانگین‌ها در data_constants پایین.
% ضریب phi_pi متعلق به قاعده رشد پایه پولی است، نه قاعده نرخ بهره.
% خروجی‌ها خودکار در results ذخیره می‌شوند؛ فایل ورودی دیگری لازم نیست.
if nargin==0,action='run';end
% Numeric signature is used by Dynare's inline steady_state_model parser.
if isnumeric(action) && nargin==4
 sigT=varargin{2}*varargin{3};
 [L11,L21,sd_signal]=signal_gain(action,varargin{1},varargin{2},sigT);
 varargout={sigT,L11,L21,sd_signal};return;
end
switch lower(char(action))
 case 'run'
  cfg=settings();
  if ~isempty(varargin) && ~isempty(varargin{1}),cfg.DynarePath=varargin{1};end
  if numel(varargin)>=2,cfg=merge_settings(cfg,varargin{2});end
  varargout{1}=run_model(cfg);
 case 'settings',varargout{1}=settings();
 case 'signal'
  sigT=varargin{3}*varargin{4};
  [L11,L21,sd_signal]=signal_gain(varargin{1},varargin{2},varargin{3},sigT);
  varargout={sigT,L11,L21,sd_signal};
 case 'mode',varargout{1}=accept_mode(varargin{:});
 case 'export',varargout{1}=save_bundle(varargin{:});
 case 'restore',varargout{1}=restore_verified_mode(varargin{:});
 case 'defaults',varargout{1}=default_student_params();
 case 'complete',varargout{1}=complete_params(varargin{1});
 case 'simulate',varargout{1}=simulate_lookthrough(varargin{:});
 case 'validate',assert_valid_bundle(varargin{1});
 case 'plot',plot_posterior_axis(varargin{:});
 case 'load',[varargout{1},varargout{2}]=load_bundle(varargin{:});
 case 'report'
  [bundle,runDir]=load_bundle(varargin{:});make_reports(bundle);varargout{1}=runDir;
 case 'selftest',varargout{1}=numerical_selftest();
 otherwise,error('IranMIU:Action','Unknown action: %s',char(action));
end
end

function cfg=settings()
% ======================= تنظیمات دانشجو ================================
cfg.DynarePath='C:\dynare\7.1\matlab'; % برای 6.3 همین مسیر را عوض کنید
cfg.Stage=2;             % 2 اجرای کامل؛ 1 فقط مد؛ 0 حالت پایدار و شناسایی
cfg.MHReplic=250000;     % تعداد برداشت در هر زنجیره
cfg.MHBlocks=4;         % حداقل دو زنجیره برای بررسی همگرایی
use_pct=false;
cfg.Point='mode';       % نقطه سناریوها: mode / mean / median
cfg.Language='fa';      % زبان نمودارهای افزوده‌شده: fa / en
cfg.Horizon=60;         % افق حل سناریو بر حسب فصل
cfg.PlotHorizon=40;     % افق نمایش
cfg.LTWindow=8;         % طول پنجره نگاه گذرا
cfg.LTThreshold=.50;    % آستانه خروج زودهنگام
cfg.BandDraws=200;      % برداشت‌های مشترک واقعی برای بازه‌های پسین سناریو
cfg.PPCDraws=200;       % تکرارهای بررسی پیش‌بینی پسین
% ================= تنظیمات عددی؛ معمولاً تغییر ندهید ====================
cfg.MHDrop=.5;cfg.MHTargetAcceptance=.33;cfg.MHTuneGuess=.50;
cfg.Seed=8501;cfg.MaxRhat=1.01;cfg.MinESS=400;
cfg.AllowPreliminaryScenarios=false;cfg.BandMass=.90;cfg.ShockScale=1;
cfg.Font='';cfg.HistoricalStartQuarter='1397Q2';cfg.HistoricalHawkishMultiplier=1.5;
cfg.ModeGradientTolerance=.05;cfg.ModeHessianStep=5e-4;
cfg.ModeHessianRelativeTolerance=.05;cfg.ModeObjectiveTolerance=1e-3;
end

function cfg=merge_settings(cfg,changes)
keys=fieldnames(changes);
for k=1:numel(keys)
 if ~isfield(cfg,keys{k}),error('IranMIU:Setting','Unknown setting: %s',keys{k});end
 cfg.(keys{k})=changes.(keys{k});
end
end

function runDir=run_model(cfg)
root=fileparts(mfilename('fullpath'));addpath(root);
if cfg.Stage==3,cfg.Stage=2;end % سازگاری دکمه اجرای کامل داشبورد
validateattributes(cfg.Stage,{'numeric'},{'scalar','integer','>=',0,'<=',2});
validateattributes(cfg.MHReplic,{'numeric'},{'scalar','integer','>=',100});
validateattributes(cfg.MHBlocks,{'numeric'},{'scalar','integer','>=',2});
validateattributes(cfg.MHDrop,{'numeric'},{'scalar','>=',0,'<',1});
validateattributes(cfg.MHTargetAcceptance,{'numeric'},{'scalar','>',0,'<',1});
validateattributes(cfg.MHTuneGuess,{'numeric'},{'scalar','positive','finite'});
validateattributes(cfg.Horizon,{'numeric'},{'scalar','integer','positive'});
validateattributes(cfg.PlotHorizon,{'numeric'},{'scalar','integer','positive','<=',cfg.Horizon});
validateattributes(cfg.LTWindow,{'numeric'},{'scalar','integer','>=',0,'<=',cfg.Horizon});
if ~ismember(cfg.Point,{'mode','mean','median'}),error('IranMIU:Point','Point must be mode, mean, or median.');end
if cfg.Stage<2,cfg.Point='mode';end
if exist(fullfile(cfg.DynarePath,'dynare.m'),'file')~=2
 error('IranMIU:DynarePath','Dynare not found. Edit cfg.DynarePath near the top of Iran_MIU.m.');
end
if verLessThan('matlab','9.9'),error('IranMIU:MATLAB','MATLAB R2020b or newer is required for report graphics.');end
% Never add the old helper directory: local functions cannot shadow Dynare.
oldHelpers=which('mcmc_diagnostics');
if ~isempty(oldHelpers) && contains(fileread(oldHelpers),'function info=mcmc_diagnostics(chains)')
 error('IranMIU:OldPath','An old project helper shadows Dynare. Remove that old folder from the MATLAB path, then run again.');
end
read_input(fullfile(root,'iran_data.csv')); % validate BEFORE expensive estimation
addpath(cfg.DynarePath);
[~,token]=fileparts(tempname);
runDir=fullfile(root,'results',['run_' datestr(now,'yyyymmdd_HHMMSS') '_' token]);
nativeDir=fullfile(runDir,'native');mkdir(nativeDir);
copyfile(fullfile(root,'iran_miu.mod'),nativeDir);copyfile(fullfile(root,'iran_data.csv'),nativeDir);
save(fullfile(nativeDir,'run_settings.mat'),'cfg','-v7');
old=pwd;guard=onCleanup(@()cd(old));cd(nativeDir); %#ok<NASGU>
diary(fullfile(runDir,'run.log'));logGuard=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('Iran MIU — input: 1 MOD + 1 CSV + 1 MATLAB manager + student dashboard\n%s\n',runDir);
try
 point=find(strcmp({'mode','mean','median'},cfg.Point));
 dynare('iran_miu.mod','noclearall',sprintf('-DSTAGE=%d',cfg.Stage),...
  sprintf('-DMHDRAWS=%d',cfg.MHReplic),sprintf('-DMHBLOCKS=%d',cfg.MHBlocks),sprintf('-DPOINT=%d',point));
 if cfg.Stage>0
  % Reports can be rebuilt from this bundle without re-running estimation.
  [bundle,~]=load_bundle(runDir);make_reports(bundle);
  save(fullfile(root,'results','latest.mat'),'runDir','-v7');
 end
 fprintf('\nResults saved in:\n%s\n',runDir);
catch ME
 fid=fopen(fullfile(runDir,'error.txt'),'w','n','UTF-8');
 if fid>=0,fprintf(fid,'%s',getReport(ME,'extended','hyperlinks','off'));fclose(fid);end
 fprintf(2,'Run stopped. Logs and any completed MCMC files are preserved in:\n%s\n',runDir);
 rethrow(ME);
end
end

function T=read_input(file)
if exist(file,'file')~=2,error('IranMIU:Data','Missing iran_data.csv next to Iran_MIU.m.');end
D=readtable(file);cols={'obs_pi','obs_mu','obs_dy','obs_dm','year_jalali','quarter'};
if ~isequal(D.Properties.VariableNames,cols),error('IranMIU:DataColumns','CSV columns must be: %s',strjoin(cols,','));end
Y=D{:,1:4};date=D{:,5:6};
if height(D)<30 || any(~isfinite([Y(:);date(:)]))
 error('IranMIU:DataValues','CSV must contain at least 30 complete observations, with no missing/nonfinite values.');
end
if any(date(:,1)~=fix(date(:,1))) || any(date(:,2)~=fix(date(:,2)) | date(:,2)<1 | date(:,2)>4) || any(diff(4*date(:,1)+date(:,2))~=1)
 error('IranMIU:DataDates','Jalali year/quarter must be integer, consecutive quarters.');
end
if any(abs(mean(Y,1))>1e-8),error('IranMIU:DataMeans','Observables must be demeaned log rates, as in the delivered sample.');end
if rank(cov(Y))<4,error('IranMIU:DataRank','Observed covariance must have rank four.');end
Quarter=compose('%dQ%d',date(:,1),date(:,2));T=addvars(D(:,1:4),Quarter,'Before',1);
end

function c=data_constants()
% Sample means/calibrated trends for the delivered 138-observation sample.
% If rebuilding data for a new sample, update these AND barPi/growthY in .mod.
c=struct('barPi',1.0558084997938053,'growthY',1.0084833384586476,...
 'mean_pi',.054306823946866756,'mean_mu',.05395239828151953,...
 'mean_dy',.008447557163753092,'mean_dm',.0037121060527024116);
end

function priors=prior_metadata()
% Keep this plotting/independent-audit table identical to estimated_params.
Name={'xip';'iotap';'nu';'rho_mu';'phi_pi';'phi_y';'sigP';'ratioT';'sd_d';'sd_mu';'sd_v';'rho_v';'rhoP';'rhoT'};
Distribution={'beta_pdf';'beta_pdf';'gamma_pdf';'beta_pdf';'gamma_pdf';'gamma_pdf';'inv_gamma_pdf';'gamma_pdf';'inv_gamma_pdf';'inv_gamma_pdf';'inv_gamma_pdf';'beta_pdf';'beta_pdf';'beta_pdf'};
Mean=[.75;.5;1.25;.65;1.5;.15;.002;6;.01;.02;.02;.8;.95;.15];
SD=[.1;.2;.5;.15;.6;.1;.001;2;.007;.01;.01;.1;.03;.08];
LowerSupport=[zeros(7,1);1.1;zeros(4,1);.6;.001];
UpperSupport=[1;1;Inf;1;Inf;Inf;Inf;Inf;Inf;Inf;Inf;1;.995;.5];
priors=table(string(Name),string(Distribution),Mean,SD,LowerSupport,UpperSupport,...
 'VariableNames',{'Name','Distribution','Mean','SD','LowerSupport','UpperSupport'});
end

function certificate=accept_mode(M_,oo_,options_,estim_params_,bayestopt_,cfg)
% Native Hessian plus independent true-posterior curvature; never regularize hh.
runDir=fileparts(pwd);
save(fullfile(runDir,'native_mode_snapshot.mat'),'M_','oo_','options_','estim_params_','bayestopt_','-v7');
names=strtrim(cellstr(bayestopt_.name));names=names(:);n=numel(names);
if estim_params_.nvx~=0 || estim_params_.nvn~=0 || estim_params_.ncx~=0
 error('IranMIU:ParameterOrder','The delivered specification estimates structural parameters only.');
end
native=oo_.posterior.optimization;x=native.mode(:);V=native.Variance;
if numel(x)~=n || any(~isfinite(x)) || ~isequal(size(V),[n n]) || any(~isfinite(V(:)))
 error('IranMIU:NativeMode','Native mode/covariance has invalid dimensions or nonfinite values.');
end
[~,flag]=chol((V+V')/2);
if flag || any(diag(V)<=0),error('IranMIU:Hessian','Native inverse Hessian is not positive definite. Sampling stopped.');end
for k=1:n
 se=oo_.posterior_std_at_mode.parameters.(names{k});
 if ~isreal(se) || ~isfinite(se) || se<=0,error('IranMIU:ModeSD','Invalid native standard error for %s.',names{k});end
end
files=dir(fullfile(pwd,'**',[M_.fname '_mode.mat']));
if numel(files)~=1,error('IranMIU:ModeFile','Expected exactly one native mode file.');end
rawPath=fullfile(files(1).folder,files(1).name);raw=load(rawPath,'xparam1','hh');
if ~isfield(raw,'hh') || ~isfield(raw,'xparam1') || numel(raw.xparam1)~=n || max(abs(raw.xparam1(:)-x))>1e-10 || ~isequal(size(raw.hh),[n n]) || any(~isfinite(raw.hh(:)))
 error('IranMIU:ModeFile','Native saved mode/Hessian is inconsistent.');
end
[~,flag]=chol((raw.hh+raw.hh')/2);if flag,error('IranMIU:Hessian','Saved native Hessian is not positive definite.');end
base=parameter_struct(M_);T=read_input('iran_data.csv');
audit=audit_mode_point(x,names,base,T{:,2:5},prior_metadata(),cfg);
certificate=struct('passed',false,'names',{names},'values',x,'native_variance',V,...
 'native_hh',raw.hh,'native_negative_log_posterior',-native.log_density,...
 'mode_run_dir',runDir,'audit',audit);
if ~isfinite(native.log_density) || abs(audit.objective+native.log_density)>cfg.ModeObjectiveTolerance
 error('IranMIU:ModeObjective','Native/independent negative log posterior disagree: %.10g / %.10g.',-native.log_density,audit.objective);
end
if ~audit.passed
 save(fullfile(runDir,'mode_check_failed.mat'),'certificate','-v7');
 error('IranMIU:InvalidMode','Mode failed: scaled gradient %.4g, smallest Hessian eigenvalue %.4g, step sensitivity %.4g.',audit.max_gradient,audit.minimum_hessian_eigenvalue,audit.hessian_relative_step_difference);
end
certificate.passed=true;copyfile(rawPath,'accepted_mode.mat');
save(fullfile(runDir,'accepted_mode.mat'),'certificate','-v7');
fprintf('Native joint MAP validated; negative log posterior %.9f.\n',audit.objective);
end

function P=parameter_struct(M_)
names=strtrim(cellstr(M_.param_names));P=struct();
for k=1:numel(names),P.(names{k})=M_.params(k);end
end

function bundle=save_bundle(M_,oo_,options_,estim_params_,bayestopt_,cfg,stage,certificate)
if ~certificate.passed,error('IranMIU:Mode','Cannot export an invalid mode.');end
runDir=fileparts(pwd);names=strtrim(cellstr(bayestopt_.name));names=names(:);base=parameter_struct(M_);
bundle=struct('schema_version','3.0-four-files','stage',stage,'run_dir',runDir,...
 'native_dir',pwd,'config',cfg,'names',{names},'is_actual_estimation',true,'mode_validation',certificate);
for choice={'mode','mean','median'}
 key=['posterior_' choice{1}];P=base;
 if ~isfield(oo_,key) || ~isfield(oo_.(key),'parameters'),continue;end
 for k=1:numel(names),P.(names{k})=oo_.(key).parameters.(names{k});end
 bundle.points.(choice{1})=complete_params(P);
end
for k=1:numel(names)
 if abs(bundle.points.mode.(names{k})-certificate.values(k))>1e-10,error('IranMIU:ModeMismatch','Reported joint MAP differs from validated mode.');end
end
bundle.priors=prior_metadata();bundle.data=read_input('iran_data.csv');bundle.data_constants=data_constants();
bundle.draws=[];bundle.chain_info=struct();bundle.quality=struct('preliminary',true);bundle.smoother_parameter_set='none';
if stage==2
 [bundle.draws,bundle.chain_info]=read_mh_draws(pwd,names,cfg.MHDrop);
 bundle.quality=chain_quality(bundle.chain_info,cfg);
 bundle.sampler_support=audit_sampler_bounds(options_,names,bundle.priors,fullfile(runDir,'diagnostics'));
 bundle.quality.intended_posterior_target=bundle.sampler_support.available && bundle.sampler_support.matches_prior_support;
 bundle.quality.preliminary=bundle.quality.preliminary || ~bundle.quality.intended_posterior_target;
 bundle.smooth=oo_.SmoothedVariables;bundle.smoothed_shocks=oo_.SmoothedShocks;bundle.smoother_parameter_set=cfg.Point;
end
save(fullfile(runDir,'estimation_bundle.mat'),'bundle','-v7');
save(fullfile(runDir,'dynare_structures.mat'),'M_','oo_','options_','estim_params_','bayestopt_','-v7');
end

function [bundle,runDir]=load_bundle(runDir)
if nargin==0 || isempty(runDir)
 root=fileparts(mfilename('fullpath'));pointer=fullfile(root,'results','latest.mat');
 if exist(pointer,'file')~=2,error('IranMIU:NoRun','No completed estimation yet. Run Iran_MIU first.');end
 p=load(pointer,'runDir');runDir=p.runDir;
end
file=fullfile(runDir,'estimation_bundle.mat');
if exist(file,'file')~=2,error('IranMIU:NoBundle','No estimation bundle in %s. A Stage 0 run has no posterior; see run.log/error.txt for a failed run.',runDir);end
s=load(file,'bundle');bundle=s.bundle;assert_valid_bundle(bundle);
end

function make_reports(bundle)
runDir=bundle.run_dir;
plot_posterior_report(bundle,fullfile(runDir,'posterior_figures'));
if bundle.stage==2
 [~,~,chains]=read_mh_draws(bundle.native_dir,bundle.names,bundle.config.MHDrop);
 sampling_report(bundle,chains,fullfile(runDir,'diagnostics'));
 if ~bundle.quality.intended_posterior_target || (bundle.quality.preliminary && ~bundle.config.AllowPreliminaryScenarios)
  warning('IranMIU:SamplingReview','Sampling support/convergence requires review. See diagnostics. Posterior plots are preliminary; scenarios are withheld.');
 else
  empirical_report(bundle,fullfile(runDir,'empirical'));
  posterior_predictive_report(bundle,fullfile(runDir,'posterior_predictive'));
  posterior_scenario_report(bundle,fullfile(runDir,'scenarios'));
 end
end
export_native_png(bundle.native_dir,fullfile(runDir,'native_png'));
end

% ================== زیرتوابع محاسبات و نمودارسازی =======================
% Local functions are private to this file and do not shadow Dynare functions.

function P=complete_params(P)
% Shared transformations: both likelihood and scenario code use these conventions.
if ~isfield(P,'growthY'),P.growthY=1;end
if ~isfield(P,'thetap'),P.thetap=.2;end
if isfield(P,'ratioT'),P.sigT=P.sigP*P.ratioT;end
if ~isfield(P,'rho_m'),P.rho_m=0;end
P.beta_eff=P.beta*P.growthY^(1-P.sigma);
P.ibar=P.barPi*P.growthY^P.sigma/P.beta-1;
if ~(P.beta_eff>0 && P.beta_eff<1 && P.ibar>0 && P.rhoP>P.rhoT && P.rhoP<1 && P.rhoT>=0 && P.sigP>0 && P.sigT>0)
 error('IranMIU:ParameterDomain','Invalid inflation/growth/discount or cost-signal parameters.');
end
P.kap_p=(1-P.beta_eff*P.xip)*(1-P.xip)/P.xip;
P.eps_w=(1+P.thetaw)/P.thetaw;
P.kap_w=(1-P.beta_eff*P.xiw)*(1-P.xiw)/(P.xiw*(1+P.eta*P.eps_w));
[P.L11,P.L21,P.sd_signal]=signal_gain(P.rhoP,P.rhoT,P.sigP,P.sigT);
end

function [lp,lt,sd]=signal_gain(rp,rt,sp,st)
F=diag([rp rt]);H=[1 1];Q=diag([sp^2 st^2]);P=Q;
for k=1:100000
 S=H*P*H';L=P*H'/S;Pn=F*(P-L*H*P)*F'+Q;Pn=(Pn+Pn')/2;
 if max(abs(Pn(:)-P(:)))<1e-13*max(1e-10,max(abs(P(:))))
  P=Pn;S=H*P*H';L=P*H'/S;lp=L(1);lt=L(2);sd=sqrt(S);return
 end
 P=Pn;
end
error('IranMIU:Riccati','Signal Riccati iteration did not converge.');
end

function [A,B,C,D,F]=macro_matrices(P,lookthrough)
% A E[x(+1)] = B x + C x(-1) + D s.
% x=[y pi w h mu]'; s=[aPhat aThat d z uw v mpol]'.
P=complete_params(P);A=zeros(5);B=A;C=A;D=zeros(5,7);
A(1,[1 2])=[1 1/P.sigma];B(1,1)=1+P.ibar;B(1,4)=-P.nu*P.ibar/P.sigma;
D(1,3)=-1;D(1,6)=-P.nu*P.ibar/P.sigma;
A(2,2)=P.beta_eff;B(2,2)=1+P.beta_eff*P.iotap;B(2,3)=-P.kap_p;
C(2,2)=-P.iotap;D(2,1:2)=-1;D(2,4)=P.kap_p;
A(3,2:3)=P.beta_eff;B(3,1)=-P.kap_w*(P.sigma+P.eta);
B(3,2)=1;B(3,3)=1+P.beta_eff+P.kap_w;C(3,3)=-1;
D(3,4)=P.kap_w*P.eta;D(3,5)=-1;
B(4,[2 4 5])=[1 1 -1];C(4,4)=-1;
B(5,5)=1;
if ~lookthrough
 B(5,1)=(1-P.rho_mu)*P.phi_y;B(5,2)=(1-P.rho_mu)*P.phi_pi;
 C(5,5)=-P.rho_mu;D(5,7)=-1;
end
F=diag([P.rhoP P.rhoT P.rho_d P.rho_z P.rho_w P.rho_v P.rho_m]);
end

function K=policy_matrices(P,maxWindow)
% Exact terminal ACTIVE policy: no arbitrary finite-horizon zero terminal value.
[A,B,C,D,F]=macro_matrices(P,false);n=5;
MM=[B C;eye(n) zeros(n)];NN=[A zeros(n);zeros(n) eye(n)];
[AA,BB,Q,Z]=qz(complex(MM),complex(NN));
roots=diag(AA)./diag(BB);stable=abs(diag(AA))<(1-1e-8)*abs(diag(BB));
if sum(stable)~=n,error('IranMIU:BK','Active-policy stable root count %d; expected %d.',sum(stable),n);end
[AA,BB,Q,Z]=ordqz(AA,BB,Q,Z,stable); %#ok<ASGLU>
if rcond(Z(n+1:end,1:n))<1e-11,error('IranMIU:BKRank','Stable invariant subspace is singular.');end
G=Z(1:n,1:n)/Z(n+1:end,1:n);
if max(abs(imag(G(:))))>1e-7,error('IranMIU:ComplexSolution','Complex policy.');end
G=real(G);V=zeros(5,7);
for j=1:7,V(:,j)=(A*G-B+F(j,j)*A)\D(:,j);end
res=max(abs(reshape(A*G*G-B*G-C,[],1)));
res=max(res,max(abs(reshape((A*G-B)*V+A*V*F-D,[],1))));
if res>1e-8,error('IranMIU:Residual','Policy residual %.3g.',res);end
K.G=cell(maxWindow+1,1);K.V=K.G;K.G{1}=G;K.V{1}=V;
[~,BL,CL,DL]=macro_matrices(P,true);
for l=1:maxWindow
 left=A*K.G{l}-BL;
 if rcond(left)<1e-12,error('IranMIU:LTCondition','Ill-conditioned announced LT system at window %d.',l);end
 K.G{l+1}=left\CL;K.V{l+1}=left\(DL-A*K.V{l}*F);
 if any(~isfinite(K.G{l+1}(:))) || any(~isfinite(K.V{l+1}(:))),error('IranMIU:LTFinite','Nonfinite LT policy.');end
 res=max(res,max(abs(reshape(left*K.G{l+1}-CL,[],1))));
 res=max(res,max(abs(reshape(left*K.V{l+1}-(DL-A*K.V{l}*F),[],1))));
end
K.roots=roots;K.residual=res;K.n_stable=n;K.F=F;
end

function sim=simulate_lookthrough(P,S,K)
% Same sequential-news experiment as the student, solved by exact linear recursion.
% Finite announced LT is credible; early exit is an unanticipated policy revision.
P=complete_params(P);H=S.HORIZON;W=S.LT_WINDOW;if nargin<3,K=policy_matrices(P,W);end
switch S.SHOCK_TYPE
 case 1,initial=[P.sigP;0];
 case 2,initial=[0;P.sigT];
 otherwise,initial=[P.sigP;P.sigT];
end
if S.NORM_UNIT_SHOCK,initial=.01*initial/sum(initial);end
initial=initial*S.SHOCK_SCALE;
truth=zeros(H,2);belief=truth;innov=zeros(H,1);shares=innov;
old=zeros(2,1);F=diag([P.rhoP P.rhoT]);L=[P.L11;P.L21];
for t=1:H
 if t==1,truth(t,:)=initial';else,truth(t,:)=(F*truth(t-1,:)')';end
 innov(t)=sum(truth(t,:))-sum(F*old);old=F*old+L*innov(t);belief(t,:)=old';
 shares(t)=abs(old(1))/max(1e-14,sum(abs(old)));
end
reg={'FullInfo_NoLT','FullInfo_LT','IncInfo_NoLT','IncInfo_EarlyLT','IncInfo_FixedLT'};
for k=1:5
 X=zeros(H,5);states=zeros(H,7);on=zeros(H,1);rem=zeros(H,1);xp=zeros(5,1);still=true;
 for t=1:H
  if k<=2,states(t,1:2)=truth(t,:);else,states(t,1:2)=belief(t,:);end
  if k==2 || k==5
   r=max(0,W-t+1);
  elseif k==4
   if t>W || (t>1 && innov(t)*sign(sum(initial))>0 && shares(t)>=S.LT_THRESHOLD),still=false;end
   r=still*max(0,W-t+1);
  else,r=0;
  end
  X(t,:)=(K.G{r+1}*xp+K.V{r+1}*states(t,:)')';xp=X(t,:)';on(t)=r>0;rem(t)=r;
 end
 [e,names]=assemble_endo(X,states,zeros(5,1),P);
 e(:,strcmp(names,'a'))=sum(truth,2);e(:,strcmp(names,'aP'))=truth(:,1);e(:,strcmp(names,'aT'))=truth(:,2);
 sim.Results.(reg{k})=struct('endo',e,'lt_active',on,'shareP',shares,'remaining',rem);
end
if isfield(S,'LT_MODE') && S.LT_MODE==2,sim.Results.IncInfo_LT=sim.Results.IncInfo_FixedLT;
else,sim.Results.IncInfo_LT=sim.Results.IncInfo_EarlyLT;end
sim.endo_names=names;sim.HORIZON=H;sim.PLOT_HORIZON=S.PLOT_HORIZON;
sim.L11=P.L11;sim.L21=P.L21;sim.true_state=truth';sim.signal_a=sum(truth,2)';
sim.max_eq_residual=K.residual;sim.eigval=K.roots;sim.n_unstable=sum(isfinite(K.roots) & abs(K.roots)>1+1e-8);
sim.n_fwrd=3;sim.n_inf=sum(~isfinite(K.roots));sim.bk_passed=true;
sim.P=P;sim.S=S;sim.backend='exact_linear_shared_core';
sim=add_policy_metrics(sim);
end

function [out,names]=assemble_endo(X,S,X0,P)
% Student-compatible variable names; all output values remain NATURAL LOG deviations.
P=complete_params(P);y=X(:,1);pinf=X(:,2);w=X(:,3);h=X(:,4);mu=X(:,5);
z=S(:,4);n=y-z;m=h+S(:,6);ir=P.ibar*(P.sigma*y-P.nu*m);
piw=pinf+w-[X0(3);w(1:end-1)];mrs=P.sigma*y+P.eta*n;mc=w-z;
names={'c','y','n','w','mc','mrs','pi','piw','ir','m','h','mu','a','aP','aT','ahat','aPhat','aThat','d','z','uw','mpol','v','switchshock','ygap'};
out=[y y n w mc mrs pinf piw ir m h mu sum(S(:,1:2),2) S(:,1:2) sum(S(:,1:2),2) S(:,1:2) S(:,3) z S(:,5) S(:,7) S(:,6) ones(size(y)) y-(1+P.eta)/(P.sigma+P.eta)*z];
end

function sim=add_policy_metrics(sim)
% Policy loss, not a second-order household welfare or consumption equivalent.
reg={'FullInfo_NoLT','FullInfo_LT','IncInfo_NoLT','IncInfo_EarlyLT','IncInfo_FixedLT'};
idx=@(nm)find(strcmp(sim.endo_names,nm),1);disc=sim.P.beta.^(0:sim.HORIZON-1)';
sq=zeros(5,5);loss=zeros(5,4);weights=[.5 .25 .125 .0625];
for k=1:5
 x=sim.Results.(reg{k}).endo;
 sq(k,:)=sum(x(:,[idx('pi') idx('y') idx('piw') idx('mu') idx('m')]).^2,1);
 for j=1:4,loss(k,j)=.5*sum(disc.*(x(:,idx('pi')).^2+weights(j)*x(:,idx('ygap')).^2));end
end
if loss(3,2)>1e-24,ratio=loss(:,2)/loss(3,2);else,ratio=nan(5,1);end
sim.VolMetrics=table(string(reg'),sq(:,1),sq(:,2),sq(:,3),sq(:,4),sq(:,5),loss(:,2),ratio,...
 'VariableNames',{'Regime','SumSq_Pi','SumSq_Y','SumSq_PiW','SumSq_Mu','SumSq_M','Policy_Loss','Rel_Policy_Loss'});
sim.WP85Table3=table(string(reg'),loss(:,1),loss(:,2),loss(:,3),loss(:,4),ratio,...
 'VariableNames',{'Regime','Loss_lam_1_2','Loss_lam_1_4','Loss_lam_1_8','Loss_lam_1_16','Ratio_WP85_vs_NoLT'});
end

function result=kalman_empirical(P,data)
% Independent one-step forecasts: an exact smoothed fit without measurement error
% is NOT used as evidence of predictive fit.
K=policy_matrices(P,0);G=K.G{1};V=K.V{1};F=K.F;P=complete_params(P);
J=zeros(7,6);J(1:2,1)=[P.L11;P.L21]*P.sd_signal;
J(3,2)=P.sd_d;J(4,3)=P.sd_z;J(5,4)=P.sd_w;J(6,6)=P.sd_v;J(7,5)=P.sd_mu;
T=[G V*F;zeros(7,5) F];R=[V*J;J];n=12;
T=[T zeros(n);eye(n) zeros(n)];R=[R;zeros(n,6)];H=zeros(4,2*n);
H(1,2)=1;H(2,5)=1;H(3,1)=1;H(3,n+1)=-1;
H(4,[4 11 n+4 n+11])=[1 1 -1 -1];
Q=R*R';Pcov=Q;power=T;
for k=1:100
 next=Pcov+power*Pcov*power';power=power*power;
 if norm(next-Pcov,'fro')<1e-13*max(1,norm(Pcov,'fro')),Pcov=next;break;end
 Pcov=(next+next')/2;
end
initialP=Pcov;
a=zeros(24,1);N=size(data,1);pred=zeros(N,4);err=pred;white=pred;loglik=0;mineig=Inf;
for t=1:N
 pred(t,:)=(H*a)';e=data(t,:)'-H*a;S=H*Pcov*H';S=(S+S')/2;
 [cholS,flag]=chol(S,'lower');if flag,error('IranMIU:Covariance','Non-positive forecast covariance.');end
 mineig=min(mineig,min(eig(S)));err(t,:)=e';white(t,:)=(cholS\e)';
 loglik=loglik-.5*(4*log(2*pi)+2*sum(log(diag(cholS)))+sum((cholS\e).^2));
 gain=Pcov*H'/S;a=a+gain*e;Pcov=Pcov-gain*H*Pcov;
 a=T*a;Pcov=T*Pcov*T'+Q;Pcov=(Pcov+Pcov')/2;
end
result=struct('prediction',pred,'innovation',err,'whitened_innovation',white,...
 'log_likelihood',loglik,'minimum_forecast_eigenvalue',mineig,'T',T,'R',R,'H',H,...
 'stationary_covariance',initialP);
end

function y=prior_pdf(x,row)
% Same declared prior distributions as iran_miu.mod. inv_gamma_pdf is Dynare IG1.
m=row.Mean;s=row.SD;a=row.LowerSupport;b=row.UpperSupport;y=zeros(size(x));
switch char(row.Distribution)
 case 'beta_pdf'
  u=(x-a)/(b-a);mu=(m-a)/(b-a);v=(s/(b-a))^2;k=mu*(1-mu)/v-1;
  al=mu*k;be=(1-mu)*k;ok=u>0 & u<1;
  y(ok)=exp((al-1)*log(u(ok))+(be-1)*log1p(-u(ok))-betaln(al,be))/(b-a);
 case 'gamma_pdf'
  u=x-a;al=((m-a)/s)^2;scale=s^2/(m-a);ok=u>0;
  y(ok)=exp((al-1)*log(u(ok))-u(ok)/scale-gammaln(al)-al*log(scale));
 case 'inv_gamma_pdf'
  target=m^2/(m^2+s^2);
  fun=@(al)log(al-1)+2*(gammaln(al-.5)-gammaln(al))-log(target);
  al=fzero(fun,[1+1e-9 1e6]);be=(m^2+s^2)*(al-1);ok=x>0;
  y(ok)=exp(log(2)+al*log(be)-gammaln(al)-(2*al+1)*log(x(ok))-be./x(ok).^2);
 otherwise,error('IranMIU:PriorType','Unsupported prior type.');
end
end

function [value,detail]=posterior_objective(x,names,base,data,priors)
% Independent stationary Kalman likelihood plus the exact declared Dynare priors.
% No penalty, covariance regularization, or normal approximation is added.
P=base;logprior=0;
for k=1:numel(names)
 P.(names{k})=x(k);row=priors(strcmp(priors.Name,names{k}),:);
 if height(row)~=1,error('IranMIU:PriorMetadata','No unique prior for %s.',names{k});end
 density=prior_pdf(x(k),row);
 if ~(isscalar(density) && isfinite(density) && density>0),value=Inf;detail=struct();return;end
 logprior=logprior+log(density);
end
r=kalman_empirical(P,data);value=-r.log_likelihood-logprior;
detail=struct('log_likelihood',r.log_likelihood,'log_prior',logprior,...
 'minimum_forecast_eigenvalue',r.minimum_forecast_eigenvalue);
end

function audit=audit_mode_point(x,names,base,data,priors,cfg)
% Numerical derivatives in prior-SD units at two step sizes. True curvature only.
sd=zeros(numel(names),1);
for k=1:numel(names)
 row=priors(strcmp(priors.Name,names{k}),:);
 if height(row)~=1,error('IranMIU:PriorMetadata','No unique prior for %s.',names{k});end
 sd(k)=row.SD;
end
if any(~isfinite(sd) | sd<=0),error('IranMIU:PriorScale','Invalid prior SD.');end
z=x(:)./sd;target=@(v)posterior_objective(v.*sd,names,base,data,priors);
[f,detail]=posterior_objective(x,names,base,data,priors);
[g,H]=derivatives(target,z,cfg.ModeHessianStep);
[g2,H2]=derivatives(target,z,2*cfg.ModeHessianStep);
if any(~isfinite([f;g;g2;H(:);H2(:)]))
 error('IranMIU:ModeDerivative','Nonfinite objective/derivative near the proposed mode.');
end
e=eig(H);e2=eig(H2);relative=norm(H-H2,'fro')/max(norm(H,'fro'),eps);
audit=struct('objective',f,'likelihood',detail,'prior_sd_scale',sd,...
 'gradient',g,'gradient_double_step',g2,'max_gradient',max(abs([g;g2])),...
 'hessian',H,'hessian_double_step',H2,'hessian_eigenvalues',e,...
 'minimum_hessian_eigenvalue',min([e;e2]),'hessian_relative_step_difference',relative,...
 'stationary',max(abs([g;g2]))<=cfg.ModeGradientTolerance,...
 'positive_curvature',min([e;e2])>0,...
 'step_stable',relative<=cfg.ModeHessianRelativeTolerance);
audit.settings=struct('step_prior_sd',cfg.ModeHessianStep,'gradient_tolerance',cfg.ModeGradientTolerance,...
 'hessian_relative_tolerance',cfg.ModeHessianRelativeTolerance,'native_objective_tolerance',cfg.ModeObjectiveTolerance);
audit.passed=audit.stationary && audit.positive_curvature && audit.step_stable;
end

function [g,H]=derivatives(f,z,h)
n=numel(z);g=zeros(n,1);H=zeros(n);f0=f(z);steps=eye(n)*h;
for i=1:n
 plus=f(z+steps(:,i));minus=f(z-steps(:,i));g(i)=(plus-minus)/(2*h);
 H(i,i)=(plus-2*f0+minus)/h^2;
 for j=1:i-1
  H(i,j)=(f(z+steps(:,i)+steps(:,j))-f(z+steps(:,i)-steps(:,j))...
   -f(z-steps(:,i)+steps(:,j))+f(z-steps(:,i)-steps(:,j)))/(4*h^2);
  H(j,i)=H(i,j);
 end
end
end

function oo_=restore_verified_mode(oo_,certificate)
% Native mode_compute=0 can label the best sampled draw as posterior_mode.
% The green line and point smoother use the previously certified joint MAP.
if ~certificate.passed,error('IranMIU:UncertifiedMode','Mode certificate failed.');end
if isfield(oo_,'posterior_mode'),oo_.native_stage2_posterior_mode=oo_.posterior_mode;end
for k=1:numel(certificate.names)
 name=certificate.names{k};oo_.posterior_mode.parameters.(name)=certificate.values(k);
 oo_.posterior_std_at_mode.parameters.(name)=sqrt(certificate.native_variance(k,k));
end
oo_.posterior.optimization.mode=certificate.values;
oo_.posterior.optimization.Variance=certificate.native_variance;
oo_.posterior.optimization.log_density=-certificate.native_negative_log_posterior;
oo_.certified_mode_source=certificate.mode_run_dir;
end

function [draws,info,chains]=read_mh_draws(nativeDir,names,drop)
% Burn-in is removed once PER CHAIN after numerically ordering its file chunks.
files=dir(fullfile(nativeDir,'**','*_mh*_blck*.mat'));records=[];
for k=1:numel(files)
 tok=regexp(files(k).name,'_mh(\d+)_blck(\d+)\.mat$','tokens','once');
 if ~isempty(tok),records=[records;str2double(tok{2}),str2double(tok{1}),k];end %#ok<AGROW>
end
if isempty(records),error('IranMIU:NoDraws','No native Dynare MCMC files found. Posterior curves are not generated from a mode-only run.');end
records=sortrows(records,[1 2]);ids=unique(records(:,1));chains=cell(numel(ids),1);rawN=zeros(size(ids));
acceptance=nan(size(ids));logChains=cell(size(chains));
for j=1:numel(ids)
 rr=records(records(:,1)==ids(j),:);x=[];logpost=[];
 if numel(unique(rr(:,2)))~=size(rr,1),error('IranMIU:DuplicateChainFile','Duplicate chunk number for chain %d.',ids(j));end
 for k=1:size(rr,1)
  f=files(rr(k,3));s=load(fullfile(f.folder,f.name));
  if ~isfield(s,'x2') || size(s.x2,2)~=numel(names),error('IranMIU:DrawSchema','Unexpected x2 parameter ordering or dimensions.');end
  x=[x;s.x2]; %#ok<AGROW>
  if isfield(s,'logpo2') && numel(s.logpo2)==size(s.x2,1),logpost=[logpost;s.logpo2(:)];end %#ok<AGROW>
 end
 rawN(j)=size(x,1);burn=floor(drop*rawN(j));chains{j}=x(burn+1:end,:);
 if isempty(chains{j}),error('IranMIU:BurnIn','No retained samples.');end
 % For a continuous RW-MH, changed consecutive states estimate accepted moves.
 % This omits the first transition and is labelled separately from native acceptance.
 if size(x,1)>1,acceptance(j)=mean(any(diff(x,1,1)~=0,2));end
 if numel(logpost)==size(x,1),logChains{j}=logpost(burn+1:end);end
end
draws=vertcat(chains{:});
if ~all(isfinite(draws(:))),error('IranMIU:NonfiniteDraw','Nonfinite posterior sample.');end
diagnostics=iran_miu_mcmc_diagnostics(chains);
info=struct('chain_ids',ids,'raw_count',rawN,'retained_count',cellfun(@(x)size(x,1),chains),...
 'drop_fraction',drop,'names',{names},'source','actual_native_Dynare_x2_files',...
 'acceptance_from_state_changes',acceptance,'acceptance_definition','changed adjacent raw states; first transition unavailable');
keys=fieldnames(diagnostics);for k=1:numel(keys),info.(keys{k})=diagnostics.(keys{k});end
if all(~cellfun(@isempty,logChains)),info.log_posterior=iran_miu_mcmc_diagnostics(logChains);end
end

function d=iran_miu_mcmc_diagnostics(chains)
% Project-specific name: Dynare has its own four-argument mcmc_diagnostics.
% Rank-normalized/folded split R-hat and Geyer bulk/tail ESS.
% Vehtari et al. (2021). Base MATLAB only. No thinning for diagnostics.
counts=cellfun(@(x)size(x,1),chains);n=min(counts);half=floor(n/2);
p=size(chains{1},2);m=numel(chains);X=zeros(2*half,p,m);
for j=1:m,X(:,:,j)=chains{j}(end-2*half+1:end,:);end
split=cat(3,X(1:half,:,:),X(half+1:end,:,:));
fields={'split_rhat','rank_rhat','ess_bulk','ess_tail','ess_mean','mcse_mean'};
for key=fields,d.(key{1})=nan(1,p);end
if half<10 || m<2,return;end
for k=1:p
 S=reshape(split(:,k,:),half,2*m);flat=S(:);
 if any(~isfinite(flat)) || any(var(S,0,1)<=0),continue;end
 Z=rank_normalize(S);F=rank_normalize(abs(S-median(flat)));
 d.split_rhat(k)=basic_rhat(S);d.rank_rhat(k)=max(basic_rhat(Z),basic_rhat(F));
 d.ess_bulk(k)=effective_size(Z);d.ess_mean(k)=effective_size(S);
 q=posterior_quantile(flat,[.05 .95],1);
 d.ess_tail(k)=min(effective_size(double(S<=q(1))),effective_size(double(S<=q(2))));
 d.mcse_mean(k)=std(flat)/sqrt(d.ess_mean(k));
end
d.diagnostic_draws_per_chain=2*half;
end

function z=rank_normalize(x)
[sorted,order]=sort(x(:));N=numel(sorted);
first=[1;find(diff(sorted)~=0)+1];last=[first(2:end)-1;N];
ranks=zeros(N,1);ranks(order)=repelem((first+last)/2,last-first+1);
% Blom normal scores, denominator N+1/4 (Vehtari et al.).
z=reshape(-sqrt(2)*erfcinv(2*(ranks-3/8)/(N+1/4)),size(x));
end

function r=basic_rhat(x)
n=size(x,1);W=mean(var(x,0,1));B=n*var(mean(x,1),0,2);
if W<=0,r=NaN;else,r=sqrt(((n-1)*W+B)/(n*W));end
end

function ess=effective_size(x)
[n,m]=size(x);center=x-mean(x,1);nf=2^nextpow2(2*n);
freq=fft(center,nf,1);ac=real(ifft(freq.*conj(freq),[],1));ac=ac(1:n,:)/n;
W=mean(var(x,0,1));vp=(n-1)/n*W+var(mean(x,1),0,2);
if ~isfinite(vp) || vp<=0,ess=NaN;return;end
estimate=1-(W-mean(ac,2))/vp;rho=zeros(n,1);even=1;odd=estimate(2);
rho(1)=even;rho(2)=odd;lag=1;
while lag<n-3 && even+odd>0
 even=estimate(lag+2);odd=estimate(lag+3);
 if even+odd>=0,rho(lag+2)=even;rho(lag+3)=odd;end
 lag=lag+2;
end
last=lag-2;
if even>0,rho(last+2)=even;end
lag=1;
while lag<=last-2
 previous=rho(lag)+rho(lag+1);
 if rho(lag+2)+rho(lag+3)>previous,rho(lag+2)=previous/2;rho(lag+3)=previous/2;end
 lag=lag+2;
end
tau=max(-1+2*sum(rho(1:last+1))+rho(last+2),1/log10(n*m));ess=n*m/tau;
end

function q=chain_quality(info,cfg)
finite=all(isfinite([info.rank_rhat info.ess_bulk info.ess_tail info.ess_mean]));
q=struct('maximum_rank_rhat',max(info.rank_rhat),'minimum_bulk_ess',min(info.ess_bulk),...
 'minimum_tail_ess',min(info.ess_tail),'maximum_split_rhat',max(info.split_rhat),...
 'threshold_rhat',cfg.MaxRhat,'threshold_ess',cfg.MinESS);
q.preliminary=~finite || q.maximum_rank_rhat>cfg.MaxRhat || q.minimum_bulk_ess<cfg.MinESS || q.minimum_tail_ess<cfg.MinESS;
if isfield(info,'log_posterior')
 d=info.log_posterior;
 q.preliminary=q.preliminary || any(~isfinite([d.rank_rhat d.ess_bulk d.ess_tail])) || max(d.rank_rhat)>cfg.MaxRhat || min([d.ess_bulk d.ess_tail])<cfg.MinESS;
end
end

function audit=audit_sampler_bounds(options_,names,priors,folder)
% In 7.1 iteration uses current_options.bounds, not only reset bounds at entry.
audit=struct('available',false,'matches_prior_support',false);
if ~isfield(options_,'posterior_sampler_options') || ~isfield(options_.posterior_sampler_options,'current_options'),return;end
current=options_.posterior_sampler_options.current_options;
if ~isfield(current,'bounds'),return;end
b=current.bounds;n=numel(names);lo=zeros(n,1);hi=lo;
for k=1:n,row=priors(strcmp(priors.Name,names{k}),:);lo(k)=row.LowerSupport;hi(k)=row.UpperSupport;end
if numel(b.lb)~=n || numel(b.ub)~=n,error('IranMIU:BoundsSchema','Sampler bounds have unexpected dimensions.');end
sameLo=(b.lb(:)==lo) | abs(b.lb(:)-lo)<1e-12;
sameHi=(b.ub(:)==hi) | abs(b.ub(:)-hi)<1e-12;
audit=struct('available',true,'matches_prior_support',all(sameLo & sameHi),...
 'lower',b.lb(:),'upper',b.ub(:),'expected_lower',lo,'expected_upper',hi,'names',{names});
if nargin>=4 && ~isempty(folder)
 if ~exist(folder,'dir'),mkdir(folder);end
 T=table(string(names),lo,hi,b.lb(:),b.ub(:),sameLo & sameHi,...
  'VariableNames',{'Parameter','PriorLower','PriorUpper','SamplerLower','SamplerUpper','SupportMatches'});
 writetable(T,fullfile(folder,'sampler_support_audit.csv'));
end
end

function q=posterior_quantile(x,p,dim)
% Linear interpolation of empirical quantiles; no Statistics Toolbox.
if nargin<3,dim=1;end
x=sort(x,dim);n=size(x,dim);shape=size(x);shape(dim)=numel(p);q=zeros(shape);
for j=1:numel(p)
 pos=1+(n-1)*p(j);lo=floor(pos);hi=ceil(pos);idx=repmat({':'},1,ndims(x));out=idx;
 idx{dim}=lo;a=x(idx{:});idx{dim}=hi;b=x(idx{:});out{dim}=j;q(out{:})=a+(pos-lo)*(b-a);
end
end

function y=posterior_kde(grid,draws,lo,hi)
% Transformation KDE keeps density inside the declared prior support.
x=draws(:);x=x(isfinite(x) & x>lo & x<hi);
if numel(x)<20,error('IranMIU:KDE','Insufficient actual posterior samples.');end
if isfinite(hi)
 z=log((x-lo)./(hi-x));zg=log((grid-lo)./(hi-grid));jac=(hi-lo)./((grid-lo).*(hi-grid));
else,z=log(x-lo);zg=log(grid-lo);jac=1./(grid-lo);
end
q=posterior_quantile(z,[.25 .75],1);scale=min(std(z),(q(2)-q(1))/1.349);
if ~(scale>0),scale=max(std(z),1e-4);end
h=max(1e-4,1.06*scale*numel(z)^(-.2));
% Deterministic thinning for density evaluation only; summaries use ALL retained draws.
z=z(round(linspace(1,numel(z),min(5000,numel(z)))));y=zeros(size(grid));
for k=1:200:numel(z)
 zz=z(k:min(k+199,numel(z)));u=(zg(:)-zz')/h;y=y+reshape(sum(exp(-.5*u.^2),2),size(grid));
end
y=y/(numel(z)*h*sqrt(2*pi)).*jac;y(~isfinite(y))=0;
end

function label=parameter_label(name,language)
keys={'xip','iotap','nu','rho_mu','phi_pi','phi_y','sigP','ratioT','sd_d','sd_mu','sd_v','rho_v','rhoP','rhoT'};
fa={'چسبندگی قیمت','شاخص بندی قیمت','انحنای مطلوبیت پول','هموارسازی رشد پایه پولی','واکنش به تورم','واکنش به تولید','اندازه شوک پایدار هزینه','نسبت اندازه شوک گذرا به پایدار','اندازه شوک تقاضا','اندازه شوک سیاست پولی','اندازه شوک ضریب فزاینده','پایداری ضریب فزاینده','پایداری جزء پایدار','پایداری جزء گذرا'};
k=find(strcmp(keys,name),1);
if strcmp(language,'fa') && ~isempty(k),label=fa{k};else,label=name;end
end

function font=figure_style(cfg)
fonts=listfonts;
if isfield(cfg,'Font') && ~isempty(cfg.Font) && any(strcmpi(fonts,cfg.Font)),font=cfg.Font;return;end
preferred={'Dana','Vazirmatn','Noto Naskh Arabic','Tahoma','Arial'};font='Arial';
for k=1:numel(preferred),if any(strcmpi(fonts,preferred{k})),font=preferred{k};break;end,end
end

function plot_posterior_axis(ax,bundle,name)
assert_valid_bundle(bundle);
r=bundle.priors(strcmp(bundle.priors.Name,name),:);k=find(strcmp(bundle.names,name),1);
lo=max(r.LowerSupport,r.Mean-4*r.SD);hi=min(r.UpperSupport,r.Mean+6*r.SD);
if ~isempty(bundle.draws)
 q=posterior_quantile(bundle.draws(:,k),[.001 .999],1);lo=max(r.LowerSupport,min(lo,q(1)));hi=min(r.UpperSupport,max(hi,q(2)));
end
epsx=(hi-lo)*1e-5;xx=linspace(lo+epsx,hi-epsx,400);cla(ax);hold(ax,'on');
plot(ax,xx,prior_pdf(xx,r),'Color',[.65 .65 .65],'LineWidth',1.5);labels={'پیشین'};
if ~isempty(bundle.draws),plot(ax,xx,posterior_kde(xx,bundle.draws(:,k),r.LowerSupport,r.UpperSupport),'k','LineWidth',2);labels{end+1}='پسین';end
xline(ax,bundle.points.mode.(name),'Color',[0 .55 .25],'LineWidth',1.5);labels{end+1}='مد مشترک پسین';
legend(ax,labels,'Location','best');title(ax,parameter_label(name,'fa'));ylabel(ax,'چگالی');grid(ax,'on');set(ax,'FontName',figure_style(bundle.config));
end

function summary=plot_posterior_report(bundle,folder)
assert_valid_bundle(bundle);
if ~exist(folder,'dir'),mkdir(folder);end
cfg=bundle.config;font=figure_style(cfg);N=numel(bundle.names);summary=table();
for page=1:ceil(N/6)
 f=figure('Visible','off','Color','w','Position',[100 100 1200 740]);tl=tiledlayout(f,2,3,'TileSpacing','compact');
 if ~isempty(bundle.draws) && bundle.quality.preliminary
  title(tl,'دامنه و کیفیت نمونه‌گیری باید بررسی شود','FontName',font);
 end
 for j=1:6
  k=(page-1)*6+j;if k>N,break;end
  name=bundle.names{k};r=bundle.priors(strcmp(bundle.priors.Name,name),:);
  if height(r)~=1,error('IranMIU:PriorMetadata','Prior metadata missing for %s.',name);end
  mode=bundle.points.mode.(name);a=r.LowerSupport;b=r.UpperSupport;
  if isempty(bundle.draws)
   low=max(a,r.Mean-4*r.SD);high=min(b,r.Mean+6*r.SD);
  else
   qq=posterior_quantile(bundle.draws(:,k),[.001 .999],1);
   low=max(a,min(r.Mean-4*r.SD,qq(1)));high=min(b,max(r.Mean+6*r.SD,qq(2)));
  end
  low=max(a,min(low,mode));high=min(b,max(high,mode));
  margin=max(1e-10,(high-low)*1e-5);xgrid=linspace(low+margin,high-margin,400);pr=prior_pdf(xgrid,r);
  ax=nexttile(tl);hold(ax,'on');plot(ax,xgrid,pr,'Color',[.65 .65 .65],'LineWidth',1.5);
  if ~isempty(bundle.draws),post=posterior_kde(xgrid,bundle.draws(:,k),a,b);plot(ax,xgrid,post,'k','LineWidth',2);end
  xline(ax,mode,'Color',[.1 .55 .25],'LineWidth',1.6);grid(ax,'on');
  title(ax,{parameter_label(name,cfg.Language),['(' name ')']},'Interpreter','none');
  if strcmp(cfg.Language,'fa')
   ylabel(ax,'چگالی');labels={'پیشین','پسین','مد مشترک پسین'};
  else,ylabel(ax,'Density');labels={'Prior','Posterior','Joint posterior mode'};end
  if isempty(bundle.draws),labels=labels([1 3]);end
  legend(ax,labels,'Location','best','FontSize',9);set(ax,'FontName',font,'FontSize',11);
  if ~isempty(bundle.draws)
   x=bundle.draws(:,k);xs=sort(x);n=numel(x);span=max(1,floor(.90*n));
   [~,first]=min(xs(1+span:end)-xs(1:end-span));hpd=[xs(first) xs(first+span)];
   q=posterior_quantile(x,.5,1);
   row=table(string(name),r.Mean,r.SD,mean(x),std(x),q,mode,hpd(1),hpd(2),bundle.chain_info.split_rhat(k),...
    'VariableNames',{'Parameter','PriorMean','PriorSD','PosteriorMean','PosteriorSD','PosteriorMedian','JointMode','HPD90Lower','HPD90Upper','SplitRhat'});
   if isfield(bundle.chain_info,'rank_rhat')
    row.RankRhat=bundle.chain_info.rank_rhat(k);row.BulkESS=bundle.chain_info.ess_bulk(k);row.TailESS=bundle.chain_info.ess_tail(k);row.MeanMCSE=bundle.chain_info.mcse_mean(k);
   end
   summary=[summary;row]; %#ok<AGROW>
  end
 end
 exportgraphics(f,fullfile(folder,sprintf('prior_posterior_mode_%02d.png',page)),'Resolution',300);
 exportgraphics(f,fullfile(folder,sprintf('prior_posterior_mode_%02d.pdf',page)),'ContentType','vector');
 savefig(f,fullfile(folder,sprintf('prior_posterior_mode_%02d.fig',page)));close(f);
end
if ~isempty(summary),writetable(summary,fullfile(folder,'posterior_summary.csv'),'Encoding','UTF-8');end
end

function sampling_report(bundle,chains,folder)
% Diagnostics describe actual ordered draws, not normal draws from a Hessian.
if ~exist(folder,'dir'),mkdir(folder);end
info=bundle.chain_info;names=bundle.names;cfg=bundle.config;font=figure_style(cfg);
T=table(string(names),info.rank_rhat(:),info.split_rhat(:),info.ess_bulk(:),info.ess_tail(:),info.ess_mean(:),info.mcse_mean(:),...
 'VariableNames',{'Parameter','RankFoldedSplitRhat','RawSplitRhat','BulkESS','TailESS','MeanESS','MeanMCSE'});
writetable(T,fullfile(folder,'mcmc_quality.csv'),'Encoding','UTF-8');
C=table(info.chain_ids,info.raw_count,info.retained_count,info.acceptance_from_state_changes,...
 'VariableNames',{'Chain','RawDraws','RetainedDraws','AcceptanceFromChangedStates'});
writetable(C,fullfile(folder,'chain_acceptance.csv'));
fid=fopen(fullfile(folder,'sampling_quality.json'),'w');
if fid<0,error('IranMIU:DiagnosticsWrite','Cannot write sampling report.');end
fprintf(fid,'%s',jsonencode(bundle.quality));fclose(fid);
for page=1:ceil(numel(names)/6)
 f=figure('Visible','off','Color','w','Position',[100 100 1200 800]);tl=tiledlayout(f,3,2,'TileSpacing','compact');
 for j=1:6
  k=(page-1)*6+j;if k>numel(names),break;end
  ax=nexttile(tl);hold(ax,'on');
  for c=1:numel(chains)
   x=chains{c}(:,k);ix=unique(round(linspace(1,numel(x),min(numel(x),4000))));plot(ax,ix,x(ix),'LineWidth',.5);
  end
  title(ax,sprintf('%s | Rhat %.4f | ESS %.0f / %.0f',names{k},info.rank_rhat(k),info.ess_bulk(k),info.ess_tail(k)),'Interpreter','none');
  if strcmp(cfg.Language,'fa'),xlabel(ax,'شماره برداشت پس از حذف دوره آغازین');else,xlabel(ax,'Retained iteration');end
  grid(ax,'on');set(ax,'FontName',font);
 end
 exportgraphics(f,fullfile(folder,sprintf('chain_traces_%02d.png',page)),'Resolution',200);close(f);
end
% Correlation is calculated from ALL retained draws. Display sampling diagnostics
% alongside these correlations; a plausible ellipse does not establish identification.
R=corrcoef(bundle.draws);writematrix(R,fullfile(folder,'posterior_correlation.csv'));
end

function x=smoothed_series(s,name,N)
if isfield(s,name),x=s.(name);
elseif isfield(s,'Mean') && isfield(s.Mean,name),x=s.Mean.(name);
else,error('IranMIU:SmoothedState','Missing point-smoothed state %s.',name);end
x=x(:);
if numel(x)==N+1,x=x(2:end); % explicit initial state convention
elseif numel(x)~=N,error('IranMIU:SmootherLength','Unexpected smoother length for %s.',name);end
end

function hist=historical_counterfactuals(bundle,folder)
P=bundle.points.(bundle.config.Point);cfg=bundle.config;N=height(bundle.data);
if ~strcmp(bundle.smoother_parameter_set,cfg.Point),error('IranMIU:PointMismatch','Smoother and scenario parameter sets differ.');end
quarter=string(bundle.data{:,1});first=find(quarter==string(cfg.HistoricalStartQuarter),1);
if isempty(first) || first<2,error('IranMIU:Episode','Historical start quarter missing or is first sample observation.');end
xn={'y','pi','w','h','mu'};sn={'aPhat','aThat','d','z','uw','v','mpol'};X=zeros(N,5);S=zeros(N,7);
for j=1:5,X(:,j)=smoothed_series(bundle.smooth,xn{j},N);end
for j=1:7,S(:,j)=smoothed_series(bundle.smooth,sn{j},N);end
K=policy_matrices(P,cfg.LTWindow);replay=X;
for t=2:N,replay(t,:)=(K.G{1}*replay(t-1,:)'+K.V{1}*S(t,:)')';end
baselineError=max(abs(reshape(replay(2:end,:)-X(2:end,:),[],1)));
if baselineError>1e-6,error('IranMIU:HistoricalReplay','Point-smoothed baseline replay differs by %.3g; counterfactuals stopped.',baselineError);end
reg={'Active','Fixed_LT','Early_LT','Hawkish'};hist=struct();
Pa=P;Pa.phi_pi=P.phi_pi*cfg.HistoricalHawkishMultiplier;Kh=policy_matrices(Pa,0);
for k=1:4
 Y=X;on=zeros(N,1);still=true;
 for t=first:N
  elapsed=t-first+1;
  if k==2,r=max(0,cfg.LTWindow-elapsed+1);
  elseif k==3
   share=abs(S(t,1))/max(1e-14,sum(abs(S(t,1:2))));
   % Absolute-innovation condition avoids using a single initial sign for mixed historical shocks.
   if elapsed>cfg.LTWindow || (elapsed>1 && share>=cfg.LTThreshold),still=false;end
   r=still*max(0,cfg.LTWindow-elapsed+1);
  else,r=0;end
  if k==4,Y(t,:)=(Kh.G{1}*Y(t-1,:)'+Kh.V{1}*S(t,:)')';
  else,Y(t,:)=(K.G{r+1}*Y(t-1,:)'+K.V{r+1}*S(t,:)')';end
  on(t)=r>0;
 end
 hist.(reg{k})=Y;
 tab=array2table(Y,'VariableNames',xn);tab.Quarter=quarter;tab=movevars(tab,'Quarter','Before',1);tab.LT=on;
 writetable(tab,fullfile(folder,['historical_' reg{k} '.csv']),'Encoding','UTF-8');
end
hist.baseline_replay_error=baselineError;hist.start_index=first;hist.signal_states=S;
save(fullfile(folder,'historical_counterfactuals.mat'),'hist','P','cfg','-v7');
end

function empirical_report(bundle,folder)
assert_valid_bundle(bundle);
if ~exist(folder,'dir'),mkdir(folder);end
cfg=bundle.config;font=figure_style(cfg);P=bundle.points.(cfg.Point);
cols={'obs_pi','obs_mu','obs_dy','obs_dm'};data=bundle.data{:,cols};result=kalman_empirical(P,data);
cc=bundle.data_constants;offset=[cc.mean_pi cc.mean_mu cc.mean_dy cc.mean_dm];
namesFA={'تورم فصلی','رشد اسمی پایه پولی','رشد تولید حقیقی','رشد پول حقیقی'};
labels=string(bundle.data{:,1});ticks=unique(round(linspace(1,height(bundle.data),8)));
f=figure('Visible','off','Color','w','Position',[100 50 1100 900]);tl=tiledlayout(f,4,1,'TileSpacing','compact');
for j=1:4
 ax=nexttile(tl);plot(ax,100*(data(:,j)+offset(j)),'Color',[.1 .3 .5],'LineWidth',1);hold(ax,'on');
 plot(ax,100*(result.prediction(:,j)+offset(j)),'Color',[.75 .25 .15],'LineWidth',1);
 if strcmp(cfg.Language,'fa'),title(ax,namesFA{j});legend(ax,{'مشاهده','پیش بینی یک فصل جلوتر'},'Location','best');ylabel(ax,'واحد لگاریتمی درصدی');
 else,title(ax,cols{j},'Interpreter','none');legend(ax,{'Observed','One-step prediction'});ylabel(ax,'100 log points');end
 set(ax,'FontName',font,'XTick',ticks,'XTickLabel',labels(ticks));grid(ax,'on');
end
exportgraphics(f,fullfile(folder,'one_step_predictions.png'),'Resolution',300);
exportgraphics(f,fullfile(folder,'one_step_predictions.pdf'),'ContentType','vector');savefig(f,fullfile(folder,'one_step_predictions.fig'));close(f);
out=bundle.data;
for j=1:4,out.([cols{j} '_predicted'])=result.prediction(:,j);out.([cols{j} '_innovation'])=result.innovation(:,j);end
writetable(out,fullfile(folder,'one_step_predictions.csv'),'Encoding','UTF-8');
hist=historical_counterfactuals(bundle,folder);
f=figure('Visible','off','Color','w','Position',[100 100 1100 650]);tl=tiledlayout(f,2,2,'TileSpacing','compact');
reg={'Active','Fixed_LT','Early_LT','Hawkish'};labsFA={'قاعده فعال','نگاه گذرای ثابت','خروج زودهنگام','واکنش قوی تر به تورم'};
for j=1:4
 ax=nexttile(tl);hold(ax,'on');c=[2 1 5 4];
 for k=1:4,plot(ax,100*hist.(reg{k})(:,c(j)),'LineWidth',1.3);end
 xline(ax,hist.start_index,'k:');grid(ax,'on');set(ax,'FontName',font,'XTick',ticks,'XTickLabel',labels(ticks));
 if strcmp(cfg.Language,'fa'),tt={'انحراف تورم','انحراف تولید','رشد پایه پولی','مانده حقیقی پایه پولی'};title(ax,tt{j});if j==1,legend(ax,labsFA,'Location','best');end
 else,title(ax,['Historical scenario ' num2str(j)]);if j==1,legend(ax,reg,'Interpreter','none');end,end
end
exportgraphics(f,fullfile(folder,'historical_scenarios.png'),'Resolution',300);
exportgraphics(f,fullfile(folder,'historical_scenarios.pdf'),'ContentType','vector');close(f);
save(fullfile(folder,'empirical_validation.mat'),'result','-v7');
end

function [values,labels]=observable_statistics(Y)
% Identical statistics of observed and replicated demeaned log-rate data.
names={'obs_pi','obs_mu','obs_dy','obs_dm'};values=std(Y,0,1);labels=strcat('SD_',names);
for lag=[1 4]
 for j=1:4
  C=corrcoef(Y(1:end-lag,j),Y(lag+1:end,j));values(end+1)=C(1,2); %#ok<AGROW>
  labels{end+1}=sprintf('ACF%d_%s',lag,names{j}); %#ok<AGROW>
 end
end
C=corrcoef(Y);
for i=1:4
 for j=i+1:4
  values(end+1)=C(i,j);labels{end+1}=['CORR_' names{i} '_' names{j}]; %#ok<AGROW>
 end
end
end

function posterior_predictive_report(bundle,folder)
% Whole-sample posterior predictive checks; not an out-of-sample forecast.
assert_valid_bundle(bundle);
if bundle.quality.preliminary || ~bundle.quality.intended_posterior_target
 warning('IranMIU:PreliminaryPPC','Posterior predictive checks require accepted sampling diagnostics.');return;
end
if ~exist(folder,'dir'),mkdir(folder);end
cfg=bundle.config;font=figure_style(cfg);Y=bundle.data{:,{'obs_pi','obs_mu','obs_dy','obs_dm'}};
[observed,labels]=observable_statistics(Y);N=size(Y,1);n=min(cfg.PPCDraws,size(bundle.draws,1));
ids=unique(round(linspace(1,size(bundle.draws,1),n)));replicated=nan(numel(ids),numel(observed));failure=cell(numel(ids),1);
old=rng;guard=onCleanup(@()rng(old));rng(cfg.Seed+104729,'twister'); %#ok<NASGU>
for k=1:numel(ids)
 P=bundle.points.mode;
 for j=1:numel(bundle.names),P.(bundle.names{j})=bundle.draws(ids(k),j);end
 try
  ss=kalman_empirical(P,zeros(0,4));S=(ss.stationary_covariance+ss.stationary_covariance')/2;
  [V,D]=eig(S);e=diag(D);
  if min(e)<-1e-10*max(1,max(abs(e))),error('IranMIU:StateCovariance','Stationary state covariance is not positive semidefinite.');end
  % Only roundoff-negative eigenvalues of a semidefinite STATE covariance are
  % zeroed. No Hessian or proposal covariance is regularized.
  x=V*(sqrt(max(e,0)).*randn(size(e)));sim=zeros(size(Y));
  for t=1:N,sim(t,:)=(ss.H*x)';x=ss.T*x+ss.R*randn(size(ss.R,2),1);end
  replicated(k,:)=observable_statistics(sim);
 catch ME,failure{k}=[ME.identifier ': ' ME.message];end
end
ok=all(isfinite(replicated),2);
% Convert empty successful-draw cells to empty strings before building the audit table.
% string({[]}) is not supported by MATLAB and otherwise aborts report generation.
failureText=strings(numel(failure),1);
for ii=1:numel(failure)
 if isempty(failure{ii}),failureText(ii)="";else,failureText(ii)=string(failure{ii});end
end
audit=table(ids(:),ok,failureText,'VariableNames',{'PosteriorDraw','Solved','Failure'});
writetable(audit,fullfile(folder,'predictive_draw_audit.csv'));
if sum(ok)<max(20,ceil(.9*numel(ids))),error('IranMIU:PPCDrawFailures','Too few valid posterior predictive replications. See predictive_draw_audit.csv.');end
replicated=replicated(ok,:);q=posterior_quantile(replicated,[.05 .5 .95],1);
tail=mean(replicated>=observed,1);
T=table(string(labels(:)),observed(:),q(2,:)',q(1,:)',q(3,:)',tail(:),...
 'VariableNames',{'Statistic','Observed','PredictiveMedian','PredictiveQ05','PredictiveQ95','ProbReplicatedGEObserved'});
writetable(T,fullfile(folder,'posterior_predictive_checks.csv'),'Encoding','UTF-8');
save(fullfile(folder,'posterior_predictive_replications.mat'),'replicated','observed','labels','ids','ok','-v7');
for page=1:ceil(numel(labels)/6)
 f=figure('Visible','off','Color','w','Position',[100 100 1200 740]);tl=tiledlayout(f,2,3,'TileSpacing','compact');
 for j=1:6
  k=(page-1)*6+j;if k>numel(labels),break;end
  ax=nexttile(tl);histogram(ax,replicated(:,k),'Normalization','pdf','FaceColor',[.4 .55 .7]);hold(ax,'on');xline(ax,observed(k),'r','LineWidth',1.8);
  title(ax,labels{k},'Interpreter','none');grid(ax,'on');set(ax,'FontName',font);
  if strcmp(cfg.Language,'fa'),legend(ax,{'تکرارهای پیش‌بینی پسین','آماره مشاهده‌شده'},'Location','best');else,legend(ax,{'Posterior predictive','Observed'});end
 end
 exportgraphics(f,fullfile(folder,sprintf('predictive_checks_%02d.png',page)),'Resolution',250);close(f);
end
end

function posterior_scenario_report(bundle,folder)
assert_valid_bundle(bundle);
if ~isfield(bundle.quality,'intended_posterior_target') || ~bundle.quality.intended_posterior_target
 error('IranMIU:PosteriorTarget','Posterior scenario reporting requires a verified sampler support.');
end
if bundle.quality.preliminary && ~bundle.config.AllowPreliminaryScenarios
 error('IranMIU:PosteriorQuality','Posterior scenario reporting stopped: sampling diagnostics require review.');
end
if isempty(bundle.draws),error('IranMIU:NoPosterior','Actual MCMC draws required.');end
if ~exist(folder,'dir'),mkdir(folder);end
cfg=bundle.config;P=bundle.points.(cfg.Point);font=figure_style(cfg);
S=struct('HORIZON',cfg.Horizon,'PLOT_HORIZON',cfg.PlotHorizon,'LT_WINDOW',cfg.LTWindow,...
 'LT_THRESHOLD',cfg.LTThreshold,'SHOCK_SCALE',cfg.ShockScale,'NORM_UNIT_SHOCK',false,'SHOCK_TYPE',1);
reg={'FullInfo_NoLT','FullInfo_LT','IncInfo_NoLT','IncInfo_EarlyLT','IncInfo_FixedLT'};
vars={'pi','y','mu','m','ir','piw'};kind={'Persistent','Transitory','Joint'};
fa={'تورم','تولید','رشد پایه پولی','مانده حقیقی پول','بازده اسمی','تورم دستمزد'};
legFA={'اطلاعات کامل و قاعده فعال','اطلاعات کامل و نگاه گذرا','اطلاعات ناقص و قاعده فعال','اطلاعات ناقص و خروج زودهنگام','اطلاعات ناقص و پنجره ثابت'};
rng(cfg.Seed,'twister');take=randperm(size(bundle.draws,1),min(cfg.BandDraws,size(bundle.draws,1)));
alpha=(1-cfg.BandMass)/2;colors=lines(5);Kpoint=policy_matrices(P,cfg.LTWindow);
for normFlag=0:1
 for shock=1:3
  S.SHOCK_TYPE=shock;S.NORM_UNIT_SHOCK=logical(normFlag);
  point=simulate_lookthrough(P,S,Kpoint);slug=sprintf('%s_norm%d',kind{shock},normFlag);
  save(fullfile(folder,['point_' slug '.mat']),'point','-v7');
  draws=zeros(cfg.Horizon,6,5,numel(take));loss=zeros(5,numel(take));valid=false(size(take));failures=cell(size(take));
  for j=1:numel(take)
   try
    Pd=P;for n=1:numel(bundle.names),Pd.(bundle.names{n})=bundle.draws(take(j),n);end
    Pd=complete_params(Pd);sim=simulate_lookthrough(Pd,S);
    indices=cellfun(@(x)find(strcmp(sim.endo_names,x),1),vars);
    for k=1:5,draws(:,:,k,j)=sim.Results.(reg{k}).endo(:,indices);end
    loss(:,j)=sim.VolMetrics.Policy_Loss;valid(j)=true;
   catch ME,failures{j}=[ME.identifier ': ' ME.message];end
  end
  if nnz(valid)<min(20,numel(take)),error('IranMIU:ScenarioDraws','Insufficient admissible draws for %s.',slug);end
  bands=posterior_quantile(draws(:,:,:,valid),[alpha .5 1-alpha],4);
  audit=struct('requested',numel(take),'accepted',nnz(valid),'draw_indices',take,'valid',valid,...
   'failures',{failures},'mass',cfg.BandMass,'meaning','pointwise equal-tail posterior intervals conditional on scenario rule');
  save(fullfile(folder,['bands_' slug '.mat']),'bands','vars','reg','audit','-v7');
  f=figure('Visible','off','Color','w','Position',[100 80 1250 760]);tl=tiledlayout(f,2,3,'TileSpacing','compact');
  if bundle.quality.preliminary,title(tl,'بررسی همگرایی لازم است','FontName',font);end
  tt=(1:cfg.PlotHorizon)';ix=cellfun(@(x)find(strcmp(point.endo_names,x),1),vars);
  for v=1:6
   ax=nexttile(tl);hold(ax,'on');handles=gobjects(5,1);
   for k=1:5
    lo=100*bands(tt,v,k,1);hi=100*bands(tt,v,k,3);
    fill(ax,[tt;flipud(tt)],[lo;flipud(hi)],colors(k,:),'FaceAlpha',.10,'EdgeColor','none','HandleVisibility','off');
    handles(k)=plot(ax,tt,100*point.Results.(reg{k}).endo(tt,ix(v)),'Color',colors(k,:),'LineWidth',1.5);
    tab=table(tt,point.Results.(reg{k}).endo(tt,ix(v)),bands(tt,v,k,1),bands(tt,v,k,2),bands(tt,v,k,3),...
     'VariableNames',{'Quarter','PointEstimateIRF','Lower','PosteriorMedian','Upper'});
    writetable(tab,fullfile(folder,sprintf('irf_%s_%s_%s.csv',slug,reg{k},vars{v})));
   end
   grid(ax,'on');yline(ax,0,'k:');set(ax,'FontName',font,'FontSize',11);
   if strcmp(cfg.Language,'fa'),title(ax,fa{v});xlabel(ax,'فصل');ylabel(ax,'صد برابر انحراف لگاریتمی');if v==1,legend(ax,handles,legFA,'Location','best','FontSize',8);end
   else,title(ax,vars{v},'Interpreter','none');xlabel(ax,'Quarter');ylabel(ax,'100 log points');if v==1,legend(ax,handles,reg,'Interpreter','none');end,end
  end
  exportgraphics(f,fullfile(folder,['scenarios_' slug '.png']),'Resolution',300);
  exportgraphics(f,fullfile(folder,['scenarios_' slug '.pdf']),'ContentType','vector');savefig(f,fullfile(folder,['scenarios_' slug '.fig']));close(f);
  q=posterior_quantile(loss(:,valid),[alpha .5 1-alpha],2);metrics=point.VolMetrics;
  metrics.PosteriorLower=q(:,1);metrics.PosteriorMedian=q(:,2);metrics.PosteriorUpper=q(:,3);
  writetable(metrics,fullfile(folder,['policy_losses_' slug '.csv']));
 end
end
end

function audit=export_native_png(nativeDir,outputDir)
% PNG is exported by MATLAB from saved native figures, never a graph_format token.
if ~exist(outputDir,'dir'),mkdir(outputDir);end
figures=dir(fullfile(nativeDir,'**','*.fig'));files=strings(numel(figures),1);
success=false(numel(figures),1);messages=strings(numel(figures),1);
for k=1:numel(figures)
 source=fullfile(figures(k).folder,figures(k).name);
 relative=source(numel(nativeDir)+2:end);[parent,stem]=fileparts(relative);
 targetFolder=fullfile(outputDir,parent);if ~exist(targetFolder,'dir'),mkdir(targetFolder);end
 target=fullfile(targetFolder,[stem '.png']);files(k)=string(relative);fig=[];
 try
  fig=openfig(source,'new','invisible');
  exportgraphics(fig,target,'Resolution',300);success(k)=true;
 catch ME,messages(k)=string([ME.identifier ': ' ME.message]);end
 if ~isempty(fig),close(fig);end
end
audit=table(files,success,messages,'VariableNames',{'NativeFigure','PNGExported','Message'});
writetable(audit,fullfile(outputDir,'png_export_audit.csv'),'Encoding','UTF-8');
if any(~success)
 warning('IranMIU:NativePNG','Some PNG conversions failed; native FIG/PDF and png_export_audit.csv are retained.');
end
end

function assert_valid_bundle(bundle)
if ~isfield(bundle,'mode_validation') || ~bundle.mode_validation.passed || ~isfield(bundle,'is_actual_estimation') || ~bundle.is_actual_estimation
 error('IranMIU:InvalidBundle','A completed native estimation with a validated joint MAP is required.');
end
end

function P=default_student_params()
c=data_constants();
P=struct('beta',.99,'barPi',c.barPi,'growthY',c.growthY,'sigma',1.5,'nu',1.25,'eta',1.5,...
 'xip',.75,'xiw',.75,'iotap',.5,'thetap',.2,'thetaw',.2,'rho_mu',.65,'phi_pi',1.5,'phi_y',.15,...
 'rho_d',.8,'rho_z',.8,'rho_w',.8,'rho_m',0,'rho_v',.8,'rhoP',.98,'rhoT',.1,...
 'sigP',.002,'sigT',.012,'sd_d',.01,'sd_z',.003,'sd_w',.003,'sd_mu',.02,'sd_v',.02);
P=complete_params(P);
end

function result=numerical_selftest()
% Optional, no estimation or external fixtures. Does not change any input.
P=default_student_params();
assert(abs(P.L11+P.L21-1)<1e-12);
K=policy_matrices(P,8);assert(K.residual<1e-8);
S=struct('HORIZON',60,'PLOT_HORIZON',40,'LT_WINDOW',8,'LT_THRESHOLD',.5,...
 'SHOCK_SCALE',1,'NORM_UNIT_SHOCK',false,'SHOCK_TYPE',1);
r=simulate_lookthrough(P,S);assert(all(isfinite(r.Results.IncInfo_NoLT.endo(:))));
T=read_input(fullfile(fileparts(mfilename('fullpath')),'iran_data.csv'));
f=kalman_empirical(P,T{:,2:5});assert(isfinite(f.log_likelihood));
result=struct('equation_residual',K.residual,'log_likelihood',f.log_likelihood,...
 'observations',height(T),'first_quarter',T.Quarter(1),'last_quarter',T.Quarter(end));
disp(result);
end
