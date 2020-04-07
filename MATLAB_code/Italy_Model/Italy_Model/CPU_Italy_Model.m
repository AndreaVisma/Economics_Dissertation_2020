%%Model of the Italian Economy (2010s)
clear all
clc
Parallel=1 %GPU

% A few lines needed for running on the Server
%addpath(genpath('./MatlabToolkits/'))
%addpath(genpath('../MatlabToolkits/'))
%try % Server has 20 cores, but is shared with other users, so use max of 16.
%    parpool(16)
%    gpuDevice(1)
%catch % Desktop has less than 8, so will give error, on desktop it is fine to use all available cores.
%    parpool
%end
PoolDetails=gcp;
NCores=PoolDetails.NumWorkers

% Some Toolkit options
vfoptions.tolerance=10^(-4);
vfoptions.polindorval=1;
vfoptions.howards=80;
vfoptions.parallel=1;
vfoptions.verbose=1;
vfoptions.returnmatrix=0;
vfoptions.exoticpreferences=0;
vfoptions.forceintegertype=0;
vfoptions.lowmemory=0;
vfoptions.phiaprimematrix=0;

tauchenoptions.parallel=0;

mcmomentsoptions.T=10^6;
mcmomentsoptions.Tolerance=10^(-5);
mcmomentsoptions.parallel=tauchenoptions.parallel;

simoptions.burnin=10^4;
simoptions.simperiods=10^5; % For an accurate solution you will either need simperiod=10^5 and iterate=1, or simperiod=10^6 (iterate=0).
simoptions.iterate=1;
simoptions.parallel=1; %Use CPU
simoptions.verbose=1;

transpathoptions.tolerance=10^(-5);
transpathoptions.parallel=1;
transpathoptions.exoticpreferences=0;
transpathoptions.oldpathweight=0.9;
transpathoptions.weightscheme=1;
transpathoptions.maxiterations=10000;
transpathoptions.verbose=1;

heteroagentoptions.verbose=1;

SkipGE=0 % Just a placeholder I am using to work on codes without rerunning the GE step.

%% Set some basic variables
SkipGE=1
n_l=21;
n_r=551; % Two General Eqm variables: interest rate r, tax rate a3.
n_a3=21; %parameter 'a3', only used if trying to find GE on grid
% Note: d1 is l (labour supply), d2 is a (assets)

% Some Toolkit options
simoptions.ncores=NCores; % Number of CPU cores



%% Parameters
if SkipGE==0
Params.J=5; %Number of components of the state space

% From Table 3
% Parameters
Params.beta=0.904; % Time discount factor
Params.sigma1=5.915; % Curvature of consumption
Params.sigma2=8.988; % Curvature of leisure
Params.chi=0.65; % Relative share of consumption and leisure
Params.elle=6.4; % Productive time %NOT YET DECIDED
% Age and employment process
Params.mu_r=0.028; % Common probability of retiring
Params.mu_d=0.051; % 1 - mu_d = Common probability of dying
% Technology
Params.theta=0.4757; % Capital share
Params.delta=0.0368; % Capital depreciation rate
%Productivity levels
Params.e1=1; 
Params.e2=1.273; 
Params.e3=1.818; 
Params.e4=4.061;
Params.e5=6.212;

% Government Policy
Params.G=0.326; % Government expenditures % Note: G is not really a 'parameter', it is determined residually so as to balance the government budget balance which is a 'market clearance' condition
Params.omega=0.795; % Normalized transfers to retirees
Params.a0=1.153; % Income tax function parameters 1 of 4 % DONE
Params.a1=0.215; % Income tax function parameters 2 of 4 %DONE
%YET TO DO
Params.a2=0.1; % Income tax function parameters 3 of 4 % TO DO
Params.a3=0.1; % Income tax function parameters 4 of 4 % TO DO
Params.zlowerbar=5.89; % Estate tax function parameter: tax exempt level %DOne (bit funky derivation from value average first house)
Params.tauE=0.065; % Estate tax function parameter: marginal tax rate %IMU

  save F:\Modelling\CPU_Italy_Model\Parameters_10Hours Params
else
  load F:\Modelling\CPU_Italy_Model\Parameters_Actual Params
end

  %% Transition Matrix
% WW (working to working)
tauchenoptions.parallel=0;

mu=1; %description of the autoregessive earning process
rho=0.713; %from Borella M. 'Error earnings in Italy'
sigmasq=0.040; %standard deviation

znum=5; %used to divide the earnings distribution in quintiles
q=3;
%use the method developed by Tauchen by applying the instruments developed
%by Kirby for his toolkit
[z_grid,pi_z]=TauchenMethod(mu,sigmasq,rho,znum,q,tauchenoptions);

% WR (working to retirement)
mu_r=0.028; %probability of retiring mu_r=1/35.61 (average duration of working career)
C(1,1:5)=mu_r; 
WR=diag(C); %obtain diagonal matrix
pi_z(:,6:10)=WR;

% Correcting WW 
 pi_z(1:5,1:5)=arrayfun(@(x) x/(1/(1-mu_r)),pi_z(1:5,1:5));

% RW (Retirement to Working)
tauchenoptions.parallel=0;

mu1=1; %description of the autoregessive earning process
rho1=0.444; 
sigmasq1=1;

fnum=5; %used to divide the earnings distribution in quintiles
t=3;
%again apply Tauchen's method, but this time for a function that correlates
%earning of the parents and those of the kids
[f_grid,pi_f]=TauchenMethod(mu1,sigmasq1,rho1,fnum,t,tauchenoptions);

a=dtmc(pi_f);
h=asymptotics(a)
% 
pi_f=arrayfun(@(x) x/(1/0.051), pi_f);
pi_z(6:10,1:5)=pi_f;
 
% RR (retirement to retirement) 
mu_d=0.051; %probability of dying. Average time in retirement is 19.8 years
B(1,1:5)=(1-mu_d); %this is the probability of not-dying
RR=diag(B); 
pi_z(6:10,6:10)=RR;

disp (pi_z);
%% Create the grids

%[e_grid,Gamma,gammastar,gammastarfull]=CastanedaDiazGimenezRiosRull2003_Create_Exog_Shock(Params);
e_grid=[Params.e1 Params.e2 Params.e3 Params.e4 Params.e5 0 0 0 0 0]
l_grid=linspace(0,Params.elle,n_l)';

% A rough grid I use on laptop
if NCores>4
    % Next line gives my more accurate grid
    k_grid=[0:0.02:1, 1.05:0.05:2, 2.1:0.1:50, 50.5:0.5:100, 104:4:1500]';
else
    k_grid=[0:0.03:1,1.05:0.08:2,2.1:0.2:10,10.5:0.8:100,104:6:1500]';
end    
n_k=length(k_grid);
% The next lines gives the values they used
% k_grid=[0:0.02:1,1.05:0.05:2,2.1:0.1:10,10.5:0.5:100,104:4:1500]';

% Bring model into the notational conventions used by the toolkit
d_grid=[l_grid; k_grid]; % Is a 'Case 2' value function problem
a_grid=k_grid;
z_grid=linspace(1,2*Params.J,2*Params.J)'; %(age (& determines retirement))
pi_z=pi_z;

r_grid=linspace(0,1/Params.beta-1,n_r)';
a3_grid=linspace(0.9*Params.a3,1.1*Params.a3,n_a3)';
p_grid=[r_grid; a3_grid];

n_d=[n_l,n_k];
n_a=n_k;
n_z=length(z_grid);
n_p=[n_r,n_a3];

disp('sizes')
n_d
n_a
n_z
n_p

%% Set up the model itself
GEPriceParamNames={'r','a3'};

DiscountFactorParamNames={'beta'};

ReturnFn=@(d1_val, d2_val, a_val, z_val,r,sigma1,sigma2,chi,elle,theta,delta,e1,e2,e3,e4,e5,omega,a0,a1,a2,a3) CPU_Italy_Model_ReturnFn(d1_val, d2_val, a_val, z_val,r,sigma1,sigma2,chi,elle,theta,delta,e1,e2,e3,e4,e5,omega,a0,a1,a2,a3);
ReturnFnParamNames={'r','sigma1','sigma2','chi','elle','theta','delta','e1','e2','e3','e4','e5','omega','a0','a1','a2','a3'}; %It is important that these are in same order as they appear in 'CastanedaDiazGimenezRiosRull2003_ReturnFn'

% Case 2 requires 'phiaprime' which determines next periods assets from
% this periods decisions.
Case2_Type=2;
vfoptions.phiaprimematrix=1;
PhiaprimeParamNames={};
Phi_aprimeMatrix=CPU_Italy_Model_PhiaprimeMatrix(n_d,n_z,k_grid,Params.J,Params.zlowerbar,Params.tauE);

% Create descriptions of SS values as functions of d_grid, a_grid, s_grid & pi_s (used to calculate the integral across the SS dist fn of whatever
%     functions you define here)
FnsToEvaluateParamNames(1).Names={};
FnsToEvaluateFn_1 = @(d1_val,d2_val,a_val,s_val) a_val; %K
FnsToEvaluateParamNames(2).Names={'e1','e2','e3','e4','e5'};
FnsToEvaluateFn_2 = @(d1_val,d2_val,a_val,s_val,e1,e2,e3,e4,e5) d1_val*(e1*(s_val==1)+e2*(s_val==2)+e3*(s_val==3)+e4*(s_val==4)+e5*(s_val==5)); % Efficiency hours worked: L
FnsToEvaluateParamNames(3).Names={'J','r','theta','delta','omega','e1','e2','e3','e4','e5','a0','a1','a2','a3'};
FnsToEvaluateFn_IncomeTaxRevenue = @(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,e5,a0,a1,a2,a3) CPU_Italy_Model_IncomeTaxRevenueFn(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,e5,a0,a1,a2,a3);
FnsToEvaluateParamNames(4).Names={'J','omega'};
FnsToEvaluateFn_Pensions = @(d1_val,d2_val,a_val,s_val,J,omega) omega*(s_val>J); % If you are retired you earn pension omega (otherwise it is zero).
FnsToEvaluateParamNames(5).Names={'J','mu_d','zlowerbar','tauE'};
FnsToEvaluateFn_EstateTaxRev  = @(d1_val,d2_val,a_val,s_val,J,mu_d,zlowerbar,tauE) (s_val>J)*(1-mu_d)*tauE*max(d2_val-zlowerbar,0); % If you are retired: the probability of dying times the estate tax you would pay
FnsToEvaluate={FnsToEvaluateFn_1,FnsToEvaluateFn_2,FnsToEvaluateFn_IncomeTaxRevenue,FnsToEvaluateFn_Pensions,FnsToEvaluateFn_EstateTaxRev};

% Now define the functions for the General Equilibrium conditions
%     Should be written so that closer the value given by the function is to zero, the closer the general eqm condition is to being met.
% GeneralEqmParamNames: the names of the parameters/prices that are being determined in general equilibrium
% GeneralEqmEqnParamNames: the names of parameters that are needed to evaluate the GeneralEqmEqns (these parameters themselves are not
%     determined as part of general eqm)
% GeneralEqmEqns: the general equilibrium equations. These typically include Market Clearance condtions, but often also things such as
%     Government Budget balance.
GeneralEqmEqnParamNames(1).Names={'theta','delta'};
%The requirement that the interest rate equals the marginal product of capital
GeneralEqmEqn_1 = @(AggVars,p,theta,delta) p(1)-(theta*(AggVars(1)^(theta-1))*(AggVars(2)^(1-theta))-delta); 
% Government budget balance
GeneralEqmEqnParamNames(2).Names={'G'};
GeneralEqmEqn_2 = @(AggVars,p,G) G+AggVars(4)-AggVars(3)-AggVars(5); % The roles of 'a3', which is contained in p(2), is already captured in the total revenue of income taxes (AggVars(3))

GeneralEqmEqns={GeneralEqmEqn_1,GeneralEqmEqn_2};

%% Test a few commands out before getting into the main part of General equilibrium
% Params.r=0.0233; %Params.a3
% V0=zeros(n_a,n_z);
% vfoptions.policy_forceintegertype=1
% [V, Policy]=ValueFnIter_Case2(V0, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Phi_aprimeMatrix, Case2_Type, ReturnFn, Params, DiscountFactorParamNames, ReturnFnParamNames, PhiaprimeParamNames, vfoptions);
% StationaryDist=StationaryDist_Case2(Policy,Phi_aprimeMatrix,Case2_Type,n_d,n_a,n_z,pi_z,simoptions);
% %save \\homeblue01\hmbb55\DUDE\Desktop\Modelling\Experiments\Actual_lessK V Policy StationaryDist

%% Solve the baseline model

if SkipGE==0
    % Find the competitive equilibrium
%     heteroagentoptions.pgrid=p_grid;
    Params.r=0.0233; %Params.a3
    heteroagentoptions.verbose=1;
    V0=zeros(n_a,n_z);
%     [p_eqm,p_eqm_index,MarketClearance]=HeteroAgentStationaryEqm_Case2(V0, n_d, n_a, n_z, n_p, pi_z, d_grid, a_grid, z_grid,Phi_aprimeMatrix, Case2_Type, ReturnFn, FnsToEvaluateFn, GeneralEqmEqns, Params, DiscountFactorParamNames, ReturnFnParamNames, PhiaprimeParamNames, FnsToEvaluateParamNames, GeneralEqmEqnParamNames, GEPriceParamNames,heteroagentoptions, simoptions, vfoptions);
    [p_eqm,p_eqm_index,MarketClearance]=HeteroAgentStationaryEqm_Case2(V0, n_d, n_a, n_z, 0, pi_z, d_grid, a_grid, z_grid,Phi_aprimeMatrix, Case2_Type, ReturnFn, FnsToEvaluate, GeneralEqmEqns, Params, DiscountFactorParamNames, ReturnFnParamNames, PhiaprimeParamNames, FnsToEvaluateParamNames, GeneralEqmEqnParamNames, GEPriceParamNames,heteroagentoptions, simoptions, vfoptions);
%%
    % Evaluate a few objects at the equilibrium
    Params.r=p_eqm(1);
    Params.a3=p_eqm(2);
    Params.w=(1-Params.theta)*(((Params.r+Params.delta)/(Params.theta))^(Params.theta/(Params.theta-1)));
    
    [V, Policy]=ValueFnIter_Case2(V0, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Phi_aprimeMatrix, Case2_Type, ReturnFn, Params, DiscountFactorParamNames, ReturnFnParamNames, PhiaprimeParamNames, vfoptions);
    
    StationaryDist=StationaryDist_Case2(Policy,Phi_aprimeMatrix,Case2_Type,n_d,n_a,n_z,pi_z,simoptions);
    
    save F:\Modelling\CPU_Italy_Model\Italy_Model_10Hours.mat p_eqm MarketClearance V Policy a_grid StationaryDist
else
    load F:\Modelling\CPU_Italy_Model\CPU_Italy_Model_Actual.mat p_eqm MarketClearance V Policy a_grid StationaryDist
end
Params.r=p_eqm(1);
Params.w=(1-Params.theta)*(((Params.r+Params.delta)/(Params.theta))^(Params.theta/(Params.theta-1)));
%% Reproduce Tables
% Tables 3, 4, & 5 simply report the calibrated parameters. 
% While not really part of replication I reproduce these anyway (combining Tables 4 & 5 into a single table)
Italy_Model_Tables345 %SKIP FOR THE TIME BEING

% First, calculate all of model statistics that appear in Table 6
FnsToEvaluateParamNames=struct();
FnsToEvaluateParamNames(1).Names={};
FnsToEvaluateFn_K = @(d1_val,d2_val,a_val,s_val) a_val; %K
FnsToEvaluateParamNames(2).Names={'delta'};
FnsToEvaluateFn_I = @(d1_val,d2_val,a_val,s_val,delta) d2_val-a_val*(1-delta); %I
FnsToEvaluateParamNames(3).Names={'e1','e2','e3','e4','e5'};
FnsToEvaluateFn_L = @(d1_val,d2_val,a_val,s_val,e1,e2,e3,e4,e5) d1_val*(e1*(s_val==1)+e2*(s_val==2)+e3*(s_val==3)+e4*(s_val==4)+e5*(s_val==5)); % Efficiency hours worked: L
FnsToEvaluateParamNames(4).Names={};
FnsToEvaluateFn_H = @(d1_val,d2_val,a_val,s_val) d1_val; %H
FnsToEvaluateParamNames(5).Names={'J','r','theta','delta','omega','e1','e2','e3','e4','e5','a0','a1','a2','a3'};
FnsToEvaluateFn_IncomeTaxRevenue = @(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,e5,a0,a1,a2,a3) Italy_Model_IncomeTaxRevenueFn(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,e5,a0,a1,a2,a3);
FnsToEvaluateParamNames(6).Names={'J','omega'};
FnsToEvaluateFn_Pensions = @(d1_val,d2_val,a_val,s_val,J,omega) omega*(s_val>J); % If you are retired you earn pension omega (otherwise it is zero).
FnsToEvaluateParamNames(7).Names={'J','mu_d','zlowerbar','tauE'};
FnsToEvaluateFn_EstateTaxRev  = @(d1_val,d2_val,a_val,s_val,J,mu_d,zlowerbar,tauE) (s_val>J)*(1-mu_d)*tauE*max(d2_val-zlowerbar,0); % If you are retired: the probability of dying times the estate tax you would pay
FnsToEvaluateParamNames(8).Names={'J','r','theta','delta','omega','e1','e2','e3','e4','e5','a0','a1','a2','a3'};
FnsToEvaluateFn_Consumption = @(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,e5,a0,a1,a2,a3) Italy_Model_ConsumptionFn(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,e5,a0,a1,a2,a3);
FnsToEvaluate={FnsToEvaluateFn_K,FnsToEvaluateFn_I,FnsToEvaluateFn_L,FnsToEvaluateFn_H,FnsToEvaluateFn_IncomeTaxRevenue,FnsToEvaluateFn_Pensions,FnsToEvaluateFn_EstateTaxRev,FnsToEvaluateFn_Consumption};
AggVars=EvalFnOnAgentDist_AggVars_Case2(StationaryDist, Policy, FnsToEvaluate, Params, FnsToEvaluateParamNames, n_d, n_a, n_z, d_grid, a_grid, z_grid,1); % The 2 is for Parallel (use GPU)

Y=(AggVars(1)^Params.theta)*(AggVars(3)^(1-Params.theta));
%%
Table6variables(1)=AggVars(1)/Y; % K/Y
Table6variables(2)=AggVars(2)/Y; % I/Y
Table6variables(3)=(AggVars(5)+AggVars(7)-AggVars(6))/Y; % G/Y: G=T-Tr=(Income Tax Revenue+ Estate Tax Revenue) - Pensions
Table6variables(4)=AggVars(6)/Y; % Tr/Y
Table6variables(5)=AggVars(7)/Y; % T_E/Y
Table6variables(6)=AggVars(4)/Params.elle; % h

FnsToEvaluateParamNames(1).Names={}; % FnsToEvaluateFn_H
FnsToEvaluateParamNames(2).Names={'J','r','theta','delta','omega','e1','e2','e3','e4','e5','a0','a1','a2','a3'}; % FnsToEvaluateFn_Consumption
FnsToEvaluate={FnsToEvaluateFn_H, FnsToEvaluateFn_Consumption};
MeanMedianStdDev=EvalFnOnAgentDist_MeanMedianStdDev_Case2(StationaryDist, Policy, FnsToEvaluate, Params, FnsToEvaluateParamNames, n_d, n_a, n_z, d_grid, a_grid, z_grid,1); % The 2 is for Parallel (use GPU)

Table6variables(7)=gather((MeanMedianStdDev(2,1)/MeanMedianStdDev(2,3))/(MeanMedianStdDev(1,1)/MeanMedianStdDev(1,3))); % Coefficient of Variation=std deviation divided by mean. 

NSimulations=10^6;
e=[Params.e1,Params.e2,Params.e3,Params.e4,Params.e5,0,0,0,0,0];
tic;
% Ratio of earnings of 40 year olds to 20 year olds. This is quite complicated to calculate and so required a dedicated script.
Table6variables(8)=Italy_Model_RatioEarningsOldYoung(NSimulations, StationaryDist, Policy, Phi_aprimeMatrix, n_d,n_a,n_z, d_grid, pi_z, e,Params.w,Params.J);
toc
tic;
% Intergenerational correlation coefficient. This is quite complicated to calculate and so required a dedicated script.
Table6variables(9)=Italy_Model_IntergenerationalEarnings(NSimulations,StationaryDist, Policy, Phi_aprimeMatrix, n_d,n_a,n_z,d_grid, pi_z, e,Params.w,Params.J);
toc
%%
%Table 6
FID = fopen('F:\Modelling\CPU_Italy_Model\table6.tex', 'w');
fprintf(FID, 'Values of the Targeted Ratios and Aggregates in Italy and in the Benchmark Model Economies \\\\ \n');
fprintf(FID, '\\begin{tabular*}{1.00\\textwidth}{@{\\extracolsep{\\fill}}lccccccccc} \n \\hline \\hline \n');
fprintf(FID, ' & $K/Y$ & $I/Y$ & $G/Y$ & $Tr/Y$ & $T_E/Y$ & $mean(h)$ & $CV_C/CV_H$ & $e_{40/20}$ & $\rho(f,s)$ \\\\ \n \\hline \n');
fprintf(FID, ' Target (ITA) & 6.01  & 18.159\\%%  & \\%%  & 45.712\\%%   & 2.78\\%%  & 37.98\\%%  & BHO  &  1.101 & BHO  \\\\ \n');
fprintf(FID, ' Benchmark              & %8.2f & %8.1f\\%% & %8.1f\\%% & %8.1f\\%% & %8.2f\\%% & %8.1f\\%% & %8.2f & %8.2f & %8.2f \\\\ \n', Table6variables);
fprintf(FID, '\\hline \\hline \n \\end{tabular*} \n');
fprintf(FID, '\\begin{minipage}[t]{1.00\\textwidth}{\\baselineskip=.5\\baselineskip \\vspace{.3cm} \\footnotesize{ \n');
fprintf(FID, 'Note: Variable $mean(h)$ (column 6) denotes the average share of disposable time allocated to the market. The statistic $CV_c/CV_h$ (column 7) is the ratio of the coefficients of variation of consumption and of hours worked. \\\\ \n');
fprintf(FID, '$e_{40/20}$ is the ratio of average earnings of 40 year old to 20 year old. $\rho(f,s)$ the intergenerational correlation coefficient between lifetime earnings of father and so. Note that model actually has households, while data is individuals.');
fprintf(FID, '}} \\end{minipage}');
fclose(FID);

%%
% Lorenz Curves needed for Tables 7 and 8
FnsToEvaluateParamNames(1).Names={'e1','e2','e3','e4','e5'}; % L
FnsToEvaluateParamNames(2).Names={}; % K
FnsToEvaluateParamNames(3).Names={'J','r','theta','delta','omega','e1','e2','e3','e4','e5','a0','a1','a2','a3'}; % FnsToEvaluateFn_Consumption
FnsToEvaluate={FnsToEvaluateFn_L,FnsToEvaluateFn_K ,FnsToEvaluateFn_Consumption}; % Note: Since we are looking at Lorenz curve of earnings we can ignore 'w' as a multiplicative scalar so will have no effect on Lorenz curve of earnings (beyond influence on d1)
StationaryDist_LorenzCurves=EvalFnOnAgentDist_LorenzCurve_Case2(StationaryDist, Policy, FnsToEvaluate, Params, FnsToEvaluateParamNames, n_d, n_a, n_z, d_grid, a_grid, z_grid,1); % The 2 is for Parallel (use GPU)



% Calculate Distributions of Earnings and Wealth for Table 7
Table7variables=nan(2,9);
%  Gini for Earnings
Table7variables(1,1)=Gini_from_LorenzCurve(StationaryDist_LorenzCurves(1,:));
%  Earnings Lorenz Curve: Quintiles (%) 
Table7variables(1,2:6)=100*(StationaryDist_LorenzCurves(1,[20,40,60,80,100])-StationaryDist_LorenzCurves(1,[1,21,41,61,81]));
%  Earnings Lorenz Curve: 90-95, 95-99, and 99-100 (%)
Table7variables(1,7:9)=100*(StationaryDist_LorenzCurves(1,[95,99,100])-StationaryDist_LorenzCurves(1,[90,95,99]));
%  Gini for Wealth
Table7variables(2,1)=Gini_from_LorenzCurve(StationaryDist_LorenzCurves(2,:));
%  Wealth Lorenz Curve: Quintiles (%)
Table7variables(2,2:6)=100*(StationaryDist_LorenzCurves(2,[20,40,60,80,100])-StationaryDist_LorenzCurves(2,[1,21,41,61,81]));
%  Wealth Lorenz Curve: 90-95, 95-99, and 99-100 (%)
Table7variables(2,7:9)=100*(StationaryDist_LorenzCurves(2,[95,99,100])-StationaryDist_LorenzCurves(2,[90,95,99]));

%Table 7
FID = fopen('F:\Modelling\CPU_Italy_Model\table7.tex', 'w');
fprintf(FID, 'Distributions of Earnings and of Wealth in Italy and in the Benchmark Model Economies (\\%%) \\\\ \n');
fprintf(FID, '\\begin{tabular*}{1.00\\textwidth}{@{\\extracolsep{\\fill}}lccccccccc} \n \\hline \\hline \n');
fprintf(FID, '& & & & & & & \\multicolumn{3}{c}{(TOP GROUPS} \\\\ \n');
fprintf(FID, '& & \\multicolumn{5}{c}{QUINTILE} & \\multicolumn{3}{c}{(Percentile)} \\\\ \\cline{3-7} \\cline{8-10} \n');
fprintf(FID, 'ECONOMY        & GINI  & First  & Second & Third & Fourth & Fifth & 90th-95th & 95th-99th & 99th-100th \\\\ \n \\hline \n');
fprintf(FID, '& \\multicolumn{9}{c}{A. Distribution of Earnings} \\\\ \n \\cline{2-10} \n');
fprintf(FID, ' Italy & 0.63  & -0.40  & 3.19  & 12.49 & 23.33 & 61.39 & 12.38 & 16.37 & 14.76 \\\\ \n');
fprintf(FID, ' Benchmark     & %8.2f & %8.2f  & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f \\\\ \n \\cline{2-10} \n', Table7variables(1,:));
fprintf(FID, '& \\multicolumn{9}{c}{B. Distribution of Wealth} \\\\ \n \\cline{2-10} \n');
fprintf(FID, ' Italy & 0.78  & -0.39  & 1.74  & 5.72 & 13.43  & 79.49 & 12.62 & 23.95 & 29.55 \\\\ \n');
fprintf(FID, ' Benchmark     & %8.2f & %8.2f  & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f \\\\ \n', Table7variables(2,:));
fprintf(FID, '\\hline \n \\end{tabular*} \n');
% fprintf(FID, '\\begin{minipage}[t]{1.00\\textwidth}{\\baselineskip=.5\\baselineskip \\vspace{.3cm} \\footnotesize{ \n');
% fprintf(FID, 'Note:  \\\\ \n');
% fprintf(FID, '}} \\end{minipage}');
fclose(FID);
%%
% Calculate Distributions of Consumption for Table 8
Table8variables=nan(2,9);
% Calculate cutoff for wealthiest 1%
temp=cumsum(sum(StationaryDist,2)); % cdf on wealth dimension alone
[~,cutoff_wealth1percent]=max(temp>0.99); % index
cutoff_wealth1percent=k_grid(cutoff_wealth1percent); % value
Params.cutoff_wealth1percent=cutoff_wealth1percent;
FnsToEvaluateParamNames(1).Names={'J','r','theta','delta','omega','e1','e2','e3','e4','e5','a0','a1','a2','a3','cutoff_wealth1percent'}; % FnsToEvaluateFn_Consumption_ExWealthiest1percent
FnsToEvaluateFn_Consumption_ExWealthiest1percent = @(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,e5,a0,a1,a2,a3,cutoff_wealth1percent) Italy_ConsumptionFn_ExWealthiest1percent(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,e5,a0,a1,a2,a3,cutoff_wealth1percent);
FnsToEvaluate={FnsToEvaluateFn_Consumption_ExWealthiest1percent};
StationaryDist_LorenzCurves_ExWealthiest1percent=EvalFnOnAgentDist_LorenzCurve_Case2(StationaryDist, Policy, FnsToEvaluate, Params, FnsToEvaluateParamNames, n_d, n_a, n_z, d_grid, a_grid, z_grid,1); % The 2 is for Parallel (use GPU)
%  Gini for Consumption_ExWealthiest1percent
Table8variables(1,1)=Gini_from_LorenzCurve(StationaryDist_LorenzCurves_ExWealthiest1percent(1,:));
%  Consumption_ExWealthiest1percent Lorenz Curve: Quintiles (%) 
Table8variables(1,2:6)=100*(StationaryDist_LorenzCurves_ExWealthiest1percent(1,[20,40,60,80,100])-StationaryDist_LorenzCurves_ExWealthiest1percent(1,[1,21,41,61,81]));
%  Consumption_ExWealthiest1percent Lorenz Curve: 90-95, 95-99, and 99-100 (%)
Table8variables(1,7:9)=100*(StationaryDist_LorenzCurves_ExWealthiest1percent(1,[95,99,100])-StationaryDist_LorenzCurves_ExWealthiest1percent(1,[90,95,99]));
%  Gini for Consumption
Table8variables(2,1)=Gini_from_LorenzCurve(StationaryDist_LorenzCurves(3,:));
%  Consumption Lorenz Curve: Quintiles (%) 
Table8variables(2,2:6)=100*(StationaryDist_LorenzCurves(3,[20,40,60,80,100])-StationaryDist_LorenzCurves(3,[1,21,41,61,81]));
%  Consumption Lorenz Curve: 90-95, 95-99, and 99-100 (%)
Table8variables(2,7:9)=100*(StationaryDist_LorenzCurves(3,[95,99,100])-StationaryDist_LorenzCurves(3,[90,95,99]));


%Table 8
FID = fopen('F:\Modelling\CPU_Italy_Model\table8.tex', 'w');
fprintf(FID, 'Distribution of Consumption in Italy and in the Benchmark Model Economies (\\%%) \\\\ \n');
fprintf(FID, '\\begin{tabular*}{1.00\\textwidth}{@{\\extracolsep{\\fill}}lccccccccc} \n \\hline \\hline \n');
fprintf(FID, '& & & & & & & \\multicolumn{3}{c}{(TOP GROUPS} \\\\ \n');
fprintf(FID, '& & \\multicolumn{5}{c}{QUINTILE} & \\multicolumn{3}{c}{(Percentile)} \\\\ \\cline{3-7} \\cline{8-10} \n');
fprintf(FID, 'ECONOMY        & GINI  & First  & Second & Third & Fourth & Fifth & 90th-95th & 95th-99th & 99th-100th \\\\ \n \\hline \n');
fprintf(FID, '\\multicolumn{10}{l}{United States:} \\\\ \n \\cline{2-10} \n');
fprintf(FID, '\\quad Nondurables   & 0.32  & 6.87 & 12.27 & 17.27 & 23.33 & 40.27 & 9.71 & 10.30 & 4.83 \\\\ \n');
fprintf(FID, '\\quad Nondurables+* & 0.30  & 7.19 & 12.96 & 17.80 & 23.77 & 38.28 & 9.43 &  9.69 & 3.77 \\\\ \n');
fprintf(FID, '\\multicolumn{10}{l}{Benchmark:} \\\\ \n');
fprintf(FID, '\\multicolumn{10}{l}{\\quad Wealthiest} \\\\ \n');
fprintf(FID, '\\quad 1\\%% Excluded & %8.2f & %8.2f  & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f \\\\ \n', Table8variables(1,:));
fprintf(FID, '\\quad Entire Sample & %8.2f & %8.2f  & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f \\\\ \n', Table8variables(2,:));
fprintf(FID, '\\hline \n \\end{tabular*} \n');
fprintf(FID, '\\begin{minipage}[t]{1.00\\textwidth}{\\baselineskip=.5\\baselineskip \\vspace{.3cm} \\footnotesize{ \n');
fprintf(FID, '*: Includes imputed services of consumer durables. \n');
fprintf(FID, '}} \\end{minipage}');
fclose(FID);


%%
% Calculate Mobility Statistics for Table 9
Table9variables=nan(2,5);
% Seems like ideal method for mobility would be based on cupolas, but for
% now just use simulation methods.


% Transition Probabilities needed for Table 9
FnsToEvaluateParamNames(1).Names={'e1','e2','e3','e4','e5'}; % L
FnsToEvaluateParamNames(2).Names={}; % K
FnsToEvaluate={FnsToEvaluateFn_L,FnsToEvaluateFn_K}; % Note: Since we are looking at Lorenz curve of earnings we can ignore 'w' as a multiplicative scalar so will have no effect on Lorenz curve of earnings (beyond influence on d1)
% 5 period transtion probabilities
t=5;
% Quintiles, so
npoints=5;
% Number of simulations on which to base results
NSims=10^7;
TransitionProbabilities=EvalFnOnAgentDist_RankTransitionProbabilities_Case2(t,NSims,StationaryDist, Policy,Phi_aprimeMatrix, Case2_Type, FnsToEvaluate, Params,FnsToEvaluateParamNames, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, 1, npoints); % 2 is as using parallel on GPU

%temporary
Table9variables=zeros(2,5);
for ii=1:5
    Table9variables(1,ii)=TransitionProbabilities(ii,ii,1); % Probability of staying in same quintile, hence ii-ii entry.
    Table9variables(2,ii)=TransitionProbabilities(ii,ii,2);
end

%Table 9
FID = fopen('./SavedOutput/LatexInputs/CastanedaDiazGimenezRiosRull2003_Table9.tex', 'w');
fprintf(FID, 'Earnings and Wealth Persistence in the United States and in the Benchmark Model Economies: Fraction of Households That Remain In The Same Quintile After Five Years \\\\ \n');
fprintf(FID, '\\begin{tabular*}{1.00\\textwidth}{@{\\extracolsep{\\fill}}lccccc} \n \\hline \\hline \n');
fprintf(FID, ' & \\multicolumn{5}{c}{(QUINTILE} \\\\ \n');
fprintf(FID, 'ECONOMY & First  & Second & Third & Fourth & Fifth \\\\ \n \\hline \n');
fprintf(FID, '& \\multicolumn{5}{c}{A. Earnings Persistence} \\\\ \n \\cline{2-6} \n');
fprintf(FID, 'United States  & 0.86  & 0.41  & 0.47 & 0.46 & 0.66 \\\\ \n');
fprintf(FID, 'Benchmark      & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f \\\\ \n', Table9variables(1,:));
fprintf(FID, '& \\multicolumn{5}{c}{A. Wealth Persistence} \\\\ \n \\cline{2-6} \n');
fprintf(FID, 'United States  & 0.67  & 0.47  &  0.45 & 0.50  & 0.71  \\\\ \n');
fprintf(FID, 'Benchmark      & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f \\\\ \n', Table9variables(2,:));
fprintf(FID, '\\hline \n \\end{tabular*} \n');
fprintf(FID, '\\begin{minipage}[t]{1.00\\textwidth}{\\baselineskip=.5\\baselineskip \\vspace{.3cm} \\footnotesize{ \n');
fprintf(FID, 'Note: Based on %d simulations. \\\\ \n', NSims);
fprintf(FID, '}} \\end{minipage}');
fclose(FID);

%% Reproduce Figures



%% For some other work of mine, look more closely at the very very top end of the wealth distribution and income distribution.
% % npoints=1000; %0; %Decided against going with 10000 points as trying to look at top 0.01% as we have little empirical evidence on what should happen and the model doesn't really 'exist' at that accuracy (there are not even that many grid points on assets anyway)
% % 
% % % FnsToEvaluateFn_K = @(d1_val,d2_val,a_val,s_val) a_val; %K
% % % FnsToEvaluateFn_L = @(d1_val,d2_val,a_val,s_val,e1,e2,e3,e4) d1_val*(e1*(s_val==1)+e2*(s_val==2)+e3*(s_val==3)+e4*(s_val==4)); % Efficiency hours worked: L
% % % FnsToEvaluateFn_Consumption = @(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,a0,a1,a2,a3) CDGRR2003_ConsumptionFn(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,a0,a1,a2,a3);
% % 
% % % Lorenz Curves needed for Table 
% % FnsToEvaluateParamNames(1).Names={'e1','e2','e3','e4'}; % L
% % FnsToEvaluateParamNames(2).Names={}; % K
% % FnsToEvaluateParamNames(3).Names={'J','r','theta','delta','omega','e1','e2','e3','e4','a0','a1','a2','a3'}; % FnsToEvaluateFn_Consumption
% % FnsToEvaluateFn={FnsToEvaluateFn_L,FnsToEvaluateFn_K ,FnsToEvaluateFn_Consumption}; % Note: Since we are looking at Lorenz curve of earnings we can ignore 'w' as a multiplicative scalar so will have no effect on Lorenz curve of earnings (beyond influence on d1)
% % SSvalues_LorenzCurves=SSvalues_LorenzCurve_Case2(StationaryDist, Policy, FnsToEvaluateFn, Params, FnsToEvaluateParamNames, n_d, n_a, n_z, d_grid, a_grid, z_grid,2,npoints); % The 2 is for Parallel (use GPU)
% % 
% % % Calculate Distributions of Earnings and Wealth for Table 7
% % TableExtra_variables=nan(2,5,'gpuArray');
% % %  Earnings Lorenz Curve:
% % TableExtra_variables(1,:)=100*(1-SSvalues_LorenzCurves(1,[900,950,990,995,999]));
% % % TableExtra_variables(1,:)=100*(1-SSvalues_LorenzCurves(1,[9000,9500,9900,9950,9990,9995,9999]));
% % %  Wealth Lorenz Curve:
% % TableExtra_variables(2,:)=100*(1-SSvalues_LorenzCurves(2,[900,950,990,995,999]));
% % % TableExtra_variables(2,:)=100*(1-SSvalues_LorenzCurves(2,[9000,9500,9900,9950,9990,9995,9999]));
% % 
% % %Table Extra
% % FID = fopen('./SavedOutput/LatexInputs/CastanedaDiazGimenezRiosRull2003_Table_Extra.tex', 'w');
% % fprintf(FID, 'Distributions of Top Earnings and of Wealth in the Model of Castaneda, Diaz-Gimenez and Rios-Rull (2003) (\\%%) \\\\ \n');
% % fprintf(FID, '\\begin{tabular*}{1.00\\textwidth}{@{\\extracolsep{\\fill}}lccccccccc} \n \\hline \\hline \n');
% % fprintf(FID, '& \\multicolumn{3}{c}{(Share of Top $X$th-to-100th Percentiles} \\\\ \n');
% % fprintf(FID, '& 90th & 95th & 99th & 99.5th & 99.9th  \\\\ \n \\hline \n');
% % fprintf(FID, 'Distribution of Earnings & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f \\\\ \n', TableExtra_variables(1,:));
% % fprintf(FID, 'Distribution of Wealth   & %8.2f & %8.2f & %8.2f & %8.2f & %8.2f \\\\ \n', TableExtra_variables(2,:));
% % fprintf(FID, '\\hline \n \\end{tabular*} \n');
% % fprintf(FID, '\\begin{minipage}[t]{1.00\\textwidth}{\\baselineskip=.5\\baselineskip \\vspace{.3cm} \\footnotesize{ \n');
% % fprintf(FID, 'Note: Wealth distribution is more skewed at the top than the earnings distribution in model of Castaneda, Diaz-Gimenez and Rios-Rull (2003) \\\\ \n');
% % fprintf(FID, '}} \\end{minipage}');
% % fclose(FID);


%% Comparison of Calibrations
% The following shows how to use the VFI Toolkit to implement a calibration
% of this kind. However because the original weights assigned to each
% moment in CDGRR2003 have been lost to the sands of time this will not
% actually return the parameter values in CDGRR2003, nor should it be
% expected to.

% Ordering of following is unimportant. (25 params)
ParamNamesToEstimate={'beta','sigma2','chi','G','omega','a2','zlowerbar','tauE','e2','e3','e4','e5'};
% Additionally 'r' and 'a3' are determined by the general eqm conditions, rather than the calibration.

% Ordering of following is unimportant. (27 targets)
EstimationTargetNames={'CapitalOutputRatio','GovExpenditureToOutputRatio','TransfersToOutputRatio',...
   'ShareOfDisposableTimeAllocatedToMarket','EffectiveTaxRateOnAverageHHIncome', 'zlowerbarMinus10timesAverageIncome', 'EstateTaxRevenueAsFractionOfGDP',...
   'RatioOfCoeffOfVarForConsumptionToCoeffOfVarForHoursWorked','RatioOfEarningsOldtoYoung','CrossSectionalCorrelationOfIncomeBetweenFathersAndSons',...
   'EarningsGini', 'WealthGini','EarningsQuintileSharesAsFraction', 'WealthQuintileSharesAsFraction','EarningsTopSharesAsFraction','WealthTopSharesAsFraction'};

% B.2 Macroeconomic Aggregates
EstimationTargets.CapitalOutputRatio=3.13;
EstimationTargets.CapitalIncomeShare=0.376;
Params.theta=0.376; % Follows immediately from CapitalIncomeShare
EstimationTargets.InvestmentToOutputRatio=0.186;
Params.delta=0.0594; % Follows immediately from delta=I/K in stationary general eqm; hence delta=(I/Y)/(K/Y)
EstimationTargets.GovExpenditureToOutputRatio=0.202;
EstimationTargets.TransfersToOutputRatio=0.049;

% B.3 Allocation of Time and Consumption
Params.elle=3.2;
EstimationTargets.ShareOfDisposableTimeAllocatedToMarket=0.3;
EstimationTargets.RatioOfCoeffOfVarForConsumptionToCoeffOfVarForHoursWorked=3.0;
Params.sigma1=1.5; % Based on literature on risk aversion

% B.4 The Age Structure of the Population
EstimationTargets.ExpectedDurationOfWorkingLife=45;
EstimationTargets.ExpectedDurationOfRetirement=18;
These lead us directly to
Params.p_eg=0.022; % Note: 1/p_eg=45
Params.p_gg=0.934; % Note: 1/(1-p_gg)=15 % Not the 18 that it should be.
% [Follows from theoretical results on 'survival analysis': the expected duration of process with constant-hazard-rate lambda is 1/lambda. 
% Here p_eg and (1-p_gg) are the hazard rates. See, e.g., example on middle of pg 3 of http://data.princeton.edu/wws509/notes/c7.pdf ]

% B.5 Life-Cycle Profile of Earnings
% RatioOfEarningsOldtoYoung: ratio of average earnings for households
between ages of 41 & 60 to average earnings of households between ages of 21 & 40.
EstimationTargets.RatioOfEarningsOldtoYoung=1.303;

% B.6 The Intergenerational Transmission of Earnings Ability
EstimationTargets.CrossSectionalCorrelationOfIncomeBetweenFathersAndSons=0.4;

% B.7 Income Taxation
Params.a0=0.258;
Params.a1=0.768;
EstimationTargets.EffectiveTaxRateOnAverageHHIncome=0.0762;
% The 'EffectiveTaxRateOnAverageHHIncome' is not reported in Casta�eda, Diaz-Gimenez, & Rios-Rull (2003). 
% The number used here is 
% According to the 1998 Economic Report of the President, Table B80, revenue from 'Individual Income Taxes' in 1992 was $476 billion.
% According to the 1998 Economic Report of the President, Table B1, GDP in 1992 was $6244.4 billion
% So use 0.0762=476/6224 as target.
% Alternatively,
% According to the 1998 Economic Report of the President, Table B80, total federal revenue in 1992 was $1091.3 billion.
% So use 0.1748=1091/6224 as target.
% Note that this is ratio of aggregate totals, rather than strictly being the mean 
% effective rate on average income HH which would be a cross-sectional concept.
% According to the 1992 Survey of Consumer Finances the average HH income was $58916 (pg 837 of CDGRR2003)
% EstimationTargets: government budget balance
EstimationTargets.GovernmentBudgetBalance=0; % This is a General Eqm
% Condition, so no need to repeat it here.

% B.8 Estate Taxation
Params.zlowerbar=10*AverageIncome;
EstimationTargets.zlowerbarMinus10timesAverageIncome=0;
EstimationTargets.EstateTaxRevenueAsFractionOfGDP=0.002;

% B.9 Normalization
Params.e1=1; % Based on my own experience with variants of this model you are actually
% better of normalizing Params.e2=1 than Params.e1=1, but as this is a
% replication I follow them exactly.
% Normalize the diagonal elements of Gamma_ee (ie., Gamma_ee_11,
% Gamma_ee_22, Gamma_ee_33, Gamma_ee_44). Choose these as simply setting,
% e.g., Gamma_ee_11=1-Gamma_ee_12-Gamma_ee_13-Gamma_ee_14 is unlikely to
% lead us to a negative value of Gamma_ee_11. Thus in terms of maintaining
% the constraints on Gamma_ee (all elements between zero and one, rows sum
% to one) required for it to be a transition matrix, we are less likely to
% be throwing out parameter vectors when estimating because they failed to
% meet these constraints. This is just a numerical trick that works well in
% practice as we 'know' that most of the weight of the transition matrix is
% on the diagonal.
% Note that this normalization of the diagonal elements of Gamma_ee is
% actually hard-coded into the how we have written the codes that create
% the transition matrix.
% Note also that paper does not actually specify which elements of Gamma_ee were normalized.

% B.10 The Distributions of Earnings and Wealth
EstimationTargets.EarningsGini=0.63;
EstimationTargets.WealthGini=0.78;
EstimationTargets.EarningsQuintileSharesAsFraction=[-0.004,0.0319, 0.1249, 0.2333, 0.6139]; % Quintiles: Bottom to Top
EstimationTargets.WealthQuintileSharesAsFraction=[-0.0039, 0.0174, 0.0572, 0.1343, 0.7949];
EstimationTargets.EarningsTopSharesAsFraction=[0.1238,0.1637,0.1476]; % 90-95, 95-99, 99-100.
EstimationTargets.WealthTopSharesAsFraction=[0.1262,0.2395,0.2955]; % 90-95, 95-99, 99-100.

% The Pension Function
% Casta�eda, Diaz-Gimenez, & Rio-Rull (2003) do not describe the
% calibration of omega(s). From Table 3 we have that 
Params.omega=0.8;
% suggesting the idea was to target the replacement rate.
% Actually this is covered by 'Transfers to Output Ratio' as being a target.

% By default the VFI Toolkit estimation commands set bounds on
% parameter values (lower bound of 1/10th of initial value, upper bound of
% 10 times initial value). You can set these bounds manually where you wish to do
% so in the following manner. [First number is lower bound, Second number
% is upper bound].
estimationoptions.ParamBounds.beta=[0.8,0.99]; % Reasonable range for discount rate.
estimationoptions.ParamBounds.r=[0,0.15]; % Seems reasonable range for interest rate.
% estimationoptions.ParamBounds.Gamma_ee_12=[0,0.3]; % Must be between 0 & 1 as is a probability.
% estimationoptions.ParamBounds.Gamma_ee_13=[0,0.2]; % Must be between 0 & 1 as is a probability.
% estimationoptions.ParamBounds.Gamma_ee_14=[0,0.2]; % Must be between 0 & 1 as is a probability.
% estimationoptions.ParamBounds.Gamma_ee_21=[0,0.3]; % Must be between 0 & 1 as is a probability.
% estimationoptions.ParamBounds.Gamma_ee_23=[0,0.3]; % Must be between 0 & 1 as is a probability.
% estimationoptions.ParamBounds.Gamma_ee_24=[0,0.3]; % Must be between 0 & 1 as is a probability.
% estimationoptions.ParamBounds.Gamma_ee_31=[0,0.3]; % Must be between 0 & 1 as is a probability.
% estimationoptions.ParamBounds.Gamma_ee_32=[0,0.3]; % Must be between 0 & 1 as is a probability.
% estimationoptions.ParamBounds.Gamma_ee_34=[0,0.3]; % Must be between 0 & 1 as is a probability.
% estimationoptions.ParamBounds.Gamma_ee_41=[0,0.3]; % Must be between 0 & 1 as is a probability.
% estimationoptions.ParamBounds.Gamma_ee_42=[0,0.3]; % Must be between 0 & 1 as is a probability.
% estimationoptions.ParamBounds.Gamma_ee_43=[0,0.3]; % Must be between 0 & 1 as is a probability.

% By default the VFI Toolkit estimation commands assume that you want the
% distance for each of the targets to be measured as the square difference as a percentage of the
% target value. You can overrule these as follows.
estimationoptions.TargetDistanceFns.EarningsQuintileSharesAsFraction='absolute-difference';
estimationoptions.TargetDistanceFns.WealthQuintileSharesAsFraction='absolute-difference';

% By default the VFI Toolkit weights each of the targets equally (with a
% value of 1). You can manually increase or decrease these weights as follows.
estimationoptions.TargetWeights.CapitalIncomeRatio=20;
EstimationTargets.TargetWeights.GovernmentBudgetBalance=100; % This is one of the general eqm conditions, so by 
      % default it gets a weight of 100 when we are using the (default) 'joint-fixed-pt' estimation algorithm.
% Targets include an excess of inequality stats, so decrease slightly the weights given to these.
estimationoptions.TargetWeights.EarningsQuintileSharesAsFraction=0.8;
estimationoptions.TargetWeights.EarningsTopSharesAsFraction=1; % 90-95, 95-99, 99-100.
estimationoptions.TargetWeights.WealthQuintileSharesAsFraction=0.8;
estimationoptions.TargetWeights.WealthTopSharesAsFraction=1.5; % Increased these as they are important part of the purpose of model, and were otherwise being ignored during the calibration (in earlier runs)
% The data and link to model are not strongest for the following two, so I give them lower weights.
estimationoptions.TargetWeights.RatioOfEarningsOldtoYoung=0.7;
estimationoptions.TargetWeights.CrossSectionalCorrelationOfIncomeBetweenFathersAndSons=0.7;
% An early estimation attempt ended up going off-track and making almost nobody work. Following makes the fraction of time worked estimation target important.
estimationoptions.TargetWeights.ShareOfDisposableTimeAllocatedToMarket=10;


% VFI Toolkit uses CMA-ES algorithm to perform the calibration. You can
% manually set some of its options if you want.
estimationoptions.CMAES.MaxIter=1000;

%% Before estimation we need to set some things back to what they were for underlying model
% Create descriptions of SS values as functions of d_grid, a_grid, s_grid & pi_s (used to calculate the integral across the SS dist fn of whatever
%     functions you define here)
FnsToEvaluateParamNames(1).Names={};
FnsToEvaluateFn_1 = @(d1_val,d2_val,a_val,s_val) a_val; %K
FnsToEvaluateParamNames(2).Names={'e1','e2','e3','e4'};
FnsToEvaluateFn_2 = @(d1_val,d2_val,a_val,s_val,e1,e2,e3,e4) d1_val*(e1*(s_val==1)+e2*(s_val==2)+e3*(s_val==3)+e4*(s_val==4)); % Efficiency hours worked: L
FnsToEvaluateParamNames(3).Names={'J','r','theta','delta','omega','e1','e2','e3','e4','e5','a0','a1','a2','a3'};
FnsToEvaluateFn_IncomeTaxRevenue = @(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,a0,a1,a2,a3) CDGRR2003_IncomeTaxRevenueFn(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,a0,a1,a2,a3);
FnsToEvaluateParamNames(4).Names={'J','omega'};
FnsToEvaluateFn_Pensions = @(d1_val,d2_val,a_val,s_val,J,omega) omega*(s_val>J); % If you are retired you earn pension omega (otherwise it is zero).
FnsToEvaluateParamNames(5).Names={'J','p_gg','zlowerbar','tauE'};
FnsToEvaluateFn_EstateTaxRev  = @(d1_val,d2_val,a_val,s_val,J,p_gg,zlowerbar,tauE) (s_val>J)*(1-p_gg)*tauE*max(d2_val-zlowerbar,0); % If you are retired: the probability of dying times the estate tax you would pay
FnsToEvaluate={FnsToEvaluateFn_1,FnsToEvaluateFn_2,FnsToEvaluateFn_IncomeTaxRevenue,FnsToEvaluateFn_Pensions,FnsToEvaluateFn_EstateTaxRev};

%% Now we just need to create the 'ModelTargetsFn'. This will be a Matlab function
% that takes Params as an input and creates ModelTargets as an output.
% ModelTargets must be a structure containing the model values for the EstimationTargets.
ModelTargetsFn=@(Params) CDGRR2003_ModelTargetsFn(Params, n_d,n_a,n_z,n_p,a_grid,ReturnFn,ReturnFnParamNames, DiscountFactorParamNames,Case2_Type,PhiaprimeParamNames,FnsToEvaluateParamNames,FnsToEvaluate,GeneralEqmEqnParamNames,GEPriceParamNames,GeneralEqmEqns, vfoptions,simoptions)
% ModelTargets must also contain the model values for any General Equilibrium conditions.
GeneralEqmTargetNames={'GE_InterestRate','GE_GovBudgetBalance'};

%% Do the actual calibration

[Params1,fval,counteval,exitflag]=EstimateModel(Params, ParamNamesToEstimate, EstimationTargets, ModelTargetsFn, estimationoptions, GEPriceParamNames, GeneralEqmTargetNames);

%save ./SavedOutput/Calib/CDGRR2003_Calib1.mat Params1 fval counteval exitflag
% load ./SavedOutput/Calib/CDGRR2003_Calib1.mat Params1 fval counteval exitflag

%% Get the model estimation target values based on the estimated parameters.
%ModelTargets=ModelTargetsFn(Params1);

%save ./SavedOutput/Calib/CDGRR2003_Calib2.mat ModelTargets;