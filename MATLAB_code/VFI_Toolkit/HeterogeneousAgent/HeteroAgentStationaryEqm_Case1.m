function [p_eqm,p_eqm_index,GeneralEqmCondition]=HeteroAgentStationaryEqm_Case1(V0, n_d, n_a, n_z, n_p, pi_z, d_grid, a_grid, z_grid, ReturnFn, FnsToEvaluate, GeneralEqmEqns, Parameters, DiscountFactorParamNames, ReturnFnParamNames, FnsToEvaluateParamNames, GeneralEqmEqnParamNames, GEPriceParamNames,heteroagentoptions, simoptions, vfoptions, EntryExitParamNames)
% If n_p=0 then will use fminsearch to find the general equilibrium (find
% price vector that corresponds to GeneralEqmCondition=0). By setting n_p to
% nonzero it is assumed you want to use a grid on prices, which must then
% be passed in using heteroagentoptions.p_grid
%
% Input heteroagentoptions and those that appear after it are all optional.
%


N_d=prod(n_d);
N_a=prod(n_a);
N_z=prod(n_z);
N_p=prod(n_p);

l_p=length(n_p);

p_eqm=nan; p_eqm_index=nan; GeneralEqmCondition=nan;

%% Check which options have been used, set all others to defaults 
if exist('vfoptions','var')==0
    %If vfoptions is not given, just use all the defaults
    vfoptions.parallel=2;
    %Note that the defaults will be set when we call 'ValueFnIter...'
    %commands and the like, so no need to set them here except for a few.
else
    %Check vfoptions for missing fields, if there are some fill them with the defaults
    if isfield(vfoptions,'parallel')==0
        vfoptions.parallel=2;
    end
end

if exist('simoptions','var')==0
    simoptions.fakeoption=0; % create a 'placeholder' simoptions that can be passed to subcodes
    %Note that the defaults will be set when we call 'StationaryDist...'
    %commands and the like, so no need to set them here except for a few.
else
    %Check simoptions for missing fields, if there are some fill them with the defaults
    if isfield(simoptions,'parallel')==0
        simoptions.parallel=2;
    end
end

if exist('heteroagentoptions','var')==0
    heteroagentoptions.multiGEcriterion=1;
    heteroagentoptions.fminalgo=1;
    heteroagentoptions.verbose=0;
    heteroagentoptions.maxiter=1000;
else
    if isfield(heteroagentoptions,'multiGEcriterion')==0
        heteroagentoptions.multiGEcriterion=1;
    end
    if N_p~=0
        if isfield(heteroagentoptions,'pgrid')==0
            disp('VFI Toolkit ERROR: you have set n_p to a non-zero value, but not declared heteroagentoptions.pgrid')
        end
    end
    if isfield(heteroagentoptions,'verbose')==0
        heteroagentoptions.verbose=0;
    end
    if isfield(heteroagentoptions,'fminalgo')==0
        heteroagentoptions.fminalgo=1; % use fminsearch
    end
    if isfield(heteroagentoptions,'maxiter')==0
        heteroagentoptions.maxiter=1000; % use fminsearch
    end
end

%%
% I should do implement this and then make the subfunctions _pgrid and
% _subfn use the 'raw' valuefniter_case1 codes, but have not yet done so.
% V0Kron=reshape(V0,[N_a,N_z]);
V0Kron=V0;

%% If there is entry and exit, then send to relevant command
if isfield(simoptions,'agententryandexit')==1
    if simoptions.agententryandexit==1
        [p_eqm,p_eqm_index, GeneralEqmCondition]=HeteroAgentStationaryEqm_Case1_EntryExit(V0, n_d, n_a, n_z, n_p, pi_z, d_grid, a_grid, z_grid, ReturnFn, FnsToEvaluate, GeneralEqmEqns, Parameters, DiscountFactorParamNames, ReturnFnParamNames, FnsToEvaluateParamNames, GeneralEqmEqnParamNames, GEPriceParamNames, EntryExitParamNames, heteroagentoptions, simoptions, vfoptions);
        return
    end
end

%% If solving on p_grid
if N_p~=0
    [p_eqm,p_eqm_index,GeneralEqmCondition]=HeteroAgentStationaryEqm_Case1_pgrid(V0Kron, n_d, n_a, n_z, n_p, pi_z, d_grid, a_grid, z_grid, ReturnFn, FnsToEvaluate, GeneralEqmEqns, Parameters, DiscountFactorParamNames, ReturnFnParamNames, FnsToEvaluateParamNames, GeneralEqmEqnParamNames, GEPriceParamNames, heteroagentoptions, simoptions, vfoptions);
    return
end

%% Otherwise, use fminsearch to find the general equilibrium

% I SHOULD IMPLEMENT A BETTER V0Kron HERE
GeneralEqmConditionsFn=@(p) HeteroAgentStationaryEqm_Case1_subfn(p, V0Kron, n_d, n_a, n_z, pi_z, d_grid, a_grid, z_grid, ReturnFn, FnsToEvaluate, GeneralEqmEqns, Parameters, DiscountFactorParamNames, ReturnFnParamNames, FnsToEvaluateParamNames, GeneralEqmEqnParamNames, GEPriceParamNames, heteroagentoptions, simoptions, vfoptions)

p0=nan(length(GEPriceParamNames),1);
for ii=1:length(GEPriceParamNames)
    p0(ii)=Parameters.(GEPriceParamNames{ii});
end

if heteroagentoptions.fminalgo==0 % fzero doesn't appear to be a good choice in practice, at least not with it's default settings.
    heteroagentoptions.multiGEcriterion=0;
    [p_eqm,GeneralEqmCondition]=fzero(GeneralEqmConditionsFn,p0);    
elseif heteroagentoptions.fminalgo==1
    [p_eqm,GeneralEqmCondition]=fminsearch(GeneralEqmConditionsFn,p0);
else
    [p_eqm,GeneralEqmCondition]=fminsearch(GeneralEqmConditionsFn,p0);
end

p_eqm_index=nan; % If not using p_grid then this is irrelevant/useless




end