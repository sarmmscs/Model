// Iran MIU — four-file edition, 3.0. Start from MATLAB with: Iran_MIU
// All equations, priors and data transformations match the previous 2.4 package.
// MATLAB manager must be on the path. No prior run or helper folder is needed.
// mu is NOMINAL BASE-MONEY GROWTH; ir is endogenous, NOT a policy rate rule.
// Linear deviations around positive trend inflation with full trend indexation.
// One PUBLIC signal innovation drives BOTH posterior cost components.
@#ifndef STAGE
 @#define STAGE = 2
@#endif
@#ifndef MHDRAWS
 @#define MHDRAWS = 100000
@#endif
@#ifndef MHBLOCKS
 @#define MHBLOCKS = 2
@#endif
@#ifndef POINT
 @#define POINT = 1
@#endif
var c y n w mc mrs pi piw ir m h mu ahat aPhat aThat d z uw mpol v
 obs_pi obs_mu obs_dy obs_dm;
varexo eps_a epsd epstech epswagepush epsmpol epsv;
parameters beta barPi growthY sigma nu eta xip xiw iotap thetap thetaw
 rho_mu phi_pi phi_y rho_d rho_z rho_w rho_m rho_v
 rhoP rhoT sigP ratioT sigT L11 L21 sd_signal sd_d sd_z sd_w sd_mu sd_v;
beta=.99;
sigma=1.5;
nu=1.25;
eta=1.5;
xip=.75;
xiw=.75;
iotap=.5;
thetap=.2; // Fixed markup: absent from this first-order Phillips coefficient.
thetaw=.2;
rho_mu=.65;
phi_pi=1.5;
phi_y=.15;
rho_d=.8;
rho_z=.8;
rho_w=.8;
rho_m=0;
rho_v=.8;
rhoP=.98;
rhoT=.1;
sigP=.002;
ratioT=6;
sigT=.012;
L11=.1380010788;
L21=1-L11;
sd_signal=.012838782;
sd_d=.01;
sd_z=.003;
sd_w=.003;
sd_mu=.02;
sd_v=.02;

// Calibrated sample trends; do not replace these by zero inflation.
barPi = 1.0558084997938053;
growthY = 1.0084833384586476;

model(linear);
// Economic equations shared by estimation and the student's scenario model.
// Exact trend indexation is an explicit maintained assumption.
 #ibar=barPi*growthY^sigma/beta-1;
 #be=beta*growthY^(1-sigma);
 #eps_lab=(1+thetaw)/thetaw;
 #kap_p=(1-be*xip)*(1-xip)/xip;
 #kap_w=(1-be*xiw)*(1-xiw)/(xiw*(1+eta*eps_lab));
 [name='Aggregate resource constraint'] y=c;
 [name='Linear production'] y=z+n;
 [name='Real marginal cost'] mc=w-z;
 [name='Marginal rate of substitution'] mrs=sigma*c+eta*n;
 [name='Consumption Euler'] c=c(+1)-(ir-pi(+1))/sigma+d;
 [name='MIU transaction-money demand'] m=(sigma/nu)*c-ir/(nu*ibar);
 [name='Transaction money versus base'] m=h+v;
 [name='Real BASE-money identity'] h=h(-1)+mu-pi;
  [name='Active base-growth rule']
  mu=rho_mu*mu(-1)-(1-rho_mu)*(phi_pi*pi+phi_y*y)+mpol;
 [name='Price Phillips curve with trend indexation']
 pi-iotap*pi(-1)=be*(pi(+1)-iotap*pi)+kap_p*mc+ahat;
 [name='Real and nominal wage identity'] piw=pi+w-w(-1);
 [name='Wage Phillips curve with trend wage indexation']
 piw=be*piw(+1)+kap_w*(mrs-w)+uw;
 [name='Demand state'] d=rho_d*d(-1)+sd_d*epsd;
 [name='Technology state'] z=rho_z*z(-1)+sd_z*epstech;
 [name='Wage-push state'] uw=rho_w*uw(-1)+sd_w*epswagepush;
 [name='Monetary policy state'] mpol=rho_m*mpol(-1)+sd_mu*epsmpol;
 [name='Detrended money multiplier'] v=rho_v*v(-1)+sd_v*epsv;

 [name='Observed aggregate signal'] ahat=aPhat+aThat;
 [name='Posterior persistent component'] aPhat=rhoP*aPhat(-1)+L11*sd_signal*eps_a;
 [name='Posterior transitory component'] aThat=rhoT*aThat(-1)+L21*sd_signal*eps_a;
 obs_pi=pi; obs_mu=mu; obs_dy=y-y(-1); obs_dm=m-m(-1);
end;

// The Riccati gains MUST be recomputed whenever their parameters change.
// This inline block replaces the former external steadystate.m file.
steady_state_model;
 [sigT,L11,L21,sd_signal]=Iran_MIU(rhoP,rhoT,sigP,ratioT);
 c=0;
 y=0;
 n=0;
 w=0;
 mc=0;
 mrs=0;
 pi=0;
 piw=0;
 ir=0;
 m=0;
 h=0;
 mu=0;
 ahat=0;
 aPhat=0;
 aThat=0;
 d=0;
 z=0;
 uw=0;
 mpol=0;
 v=0;
 obs_pi=0;
 obs_mu=0;
 obs_dy=0;
 obs_dm=0;
end;
shocks;
 var eps_a; stderr 1;
 var epsd; stderr 1;
 var epstech; stderr 1;
 var epswagepush; stderr 1;
 var epsmpol; stderr 1;
 var epsv; stderr 1;
end;
varobs obs_pi obs_mu obs_dy obs_dm;
steady;
check;
model_diagnostics;

estimated_params;
 // Initial, optimizer lower/upper, prior, mean, SD, optional prior support.
 // Optimizer bounds alone do not constrain Bayesian MCMC support.
 xip,.75,.1,.95,beta_pdf,.75,.10;
 iotap,.5,.01,.95,beta_pdf,.5,.20;
 nu,1.25,.1,6,gamma_pdf,1.25,.5;
 rho_mu,.65,.01,.95,beta_pdf,.65,.15;
 phi_pi,1.5,.01,6,gamma_pdf,1.5,.6;
 phi_y,.15,.001,2,gamma_pdf,.15,.10;
 sigP,.002,.0001,.05,inv_gamma_pdf,.002,.001;
 ratioT,6,1.1,20,gamma_pdf,6,2,1.1;
 sd_d,.01,.0001,.15,inv_gamma_pdf,.01,.007;
 sd_mu,.02,.0001,.20,inv_gamma_pdf,.02,.01;
 sd_v,.02,.0001,.20,inv_gamma_pdf,.02,.01;
 rho_v,.8,.01,.97,beta_pdf,.8,.10;
   // Disjoint supports impose rhoP > rhoT, preventing component label switching.
   rhoP,.98,.60,.995,beta_pdf,.95,.03,.60,.995;
   rhoT,.10,.001,.50,beta_pdf,.15,.08,.001,.50;
end;


// Generated only in the current results folder by Iran_MIU, not a user input.
load('run_settings.mat','cfg');
options_.mh_drop=cfg.MHDrop;
set_dynare_seed(cfg.Seed);
@#if STAGE == 0
 identification(advanced=1,ar=8,parameter_set=calibration,analytic_derivation_mode=-2);
 stoch_simul(order=1,irf=40,noprint,nograph) y pi mu m h w;
 save('../preflight_workspace.mat','M_','oo_','options_','-v7');
@#else
 // Numerical starts only; native Dynare reoptimizes and validates the MAP.
 estimated_params_init;
 xip,0.83325067946656906;
 iotap,0.17656864096045355;
 nu,0.93299162794152224;
 rho_mu,0.09545614886648357;
 phi_pi,0.30131307911409155;
 phi_y,0.12849618101774593;
 sigP,0.0031291446170543242;
 ratioT,7.1818774970745327;
 sd_d,0.011477511611415248;
 sd_mu,0.051113780357459448;
 sd_v,0.05220536987036984;
 rho_v,0.96292633763422808;
 rhoP,0.96932629987478447;
 rhoT,0.10798149562717164;
 end;
 estimation(datafile='iran_data.csv',mode_compute=5,mode_check,
  optim=('Hessian',1,'robust',1,'MaxIter',1000,'TolFun',1e-7),
  mh_replic=0,lik_init=1,prior_trunc=0,plot_priors=1,graph_format=(fig,pdf)) y pi mu m h w aPhat aThat v;
 certificate=Iran_MIU('mode',M_,oo_,options_,estim_params_,bayestopt_,cfg);
 // Save a usable mode-only checkpoint BEFORE starting the longer MCMC step.
 bundle=Iran_MIU('export',M_,oo_,options_,estim_params_,bayestopt_,cfg,1,certificate);
 @#if STAGE == 2
  // Use true prior supports in the sampler, not the optimizer's narrow bounds.
  // This avoids the cached-bounds problem in Dynare 6.3 / 7.1.
  estimated_params_bounds;
 xip,0.0,1.0;
 iotap,0.0,1.0;
 nu,0.0,Inf;
 rho_mu,0.0,1.0;
 phi_pi,0.0,Inf;
 phi_y,0.0,Inf;
 sigP,0.0,Inf;
 ratioT,1.1,Inf;
 sd_d,0.0,Inf;
 sd_mu,0.0,Inf;
 sd_v,0.0,Inf;
 rho_v,0.0,1.0;
 rhoP,0.6,0.995;
 rhoT,0.001,0.5;
  end;
  options_.mode_check.status=false;
  options_.mh_tune_jscale.status=true;
  options_.mh_tune_jscale.target=cfg.MHTargetAcceptance;
  options_.mh_tune_jscale.guess=cfg.MHTuneGuess;
  estimation(datafile='iran_data.csv',mode_compute=0,mode_file='accepted_mode.mat',
   mh_replic=@{MHDRAWS},mh_nblocks=@{MHBLOCKS},lik_init=1,prior_trunc=0,
   plot_priors=1,graph_format=(fig,pdf),bayesian_irf,smoother) y pi mu m h w aPhat aThat v;
  save('../native_estimation_snapshot.mat','M_','oo_','options_','estim_params_','bayestopt_','-v7');
  // Preserve the validated joint MAP, rather than relabeling a sampled draw.
  oo_=Iran_MIU('restore',oo_,certificate);
  @#if POINT == 1
   calib_smoother(datafile='iran_data.csv',parameter_set=posterior_mode) y pi mu m h w aPhat aThat v d z uw mpol;
  @#elseif POINT == 2
   calib_smoother(datafile='iran_data.csv',parameter_set=posterior_mean) y pi mu m h w aPhat aThat v d z uw mpol;
  @#else
   calib_smoother(datafile='iran_data.csv',parameter_set=posterior_median) y pi mu m h w aPhat aThat v d z uw mpol;
  @#endif
  save('../reporting_checkpoint.mat','M_','oo_','options_','estim_params_','bayestopt_','cfg','certificate','-v7');
  bundle=Iran_MIU('export',M_,oo_,options_,estim_params_,bayestopt_,cfg,2,certificate);
 @#endif
@#endif
