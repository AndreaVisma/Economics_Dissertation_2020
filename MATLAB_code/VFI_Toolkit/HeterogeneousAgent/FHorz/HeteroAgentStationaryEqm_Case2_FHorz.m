function [p_eqm,p_eqm_index,GeneralEqmConditions]=HeteroAgentStationaryEqm_Case2_FHorz(jequaloneDist,AgeWeights,n_d, n_a, n_z, N_j, n_p, pi_z, d_grid, a_grid, z_grid,Phi_aprimeKron, Case2_Type, ReturnFn, SSvaluesFn, GeneralEqmEqns, Parameters, DiscountFactorParamNames, ReturnFnParamNames, PhiaprimeParamNames, SSvalueParamNames, GeneralEqmEqnParamNames, GEPriceParamNames,heteroagentoptions, simoptions, vfoptions)
% If n_p=0 then will use fminsearch to find the general equilibrium (find
% price vector that corresponds to MarketClearance=0). By setting n_p to
% nonzero it is assumend you want to use a grid on prices, which must then
% be passed in heteroagentoptions.p_grid

N_d=prod(n_d);
N_a=prod(n_a);
N_z=prod(n_z);
N_p=prod(n_p);

l_p=length(n_p);

%% Check which simoptions and vfoptions have been used, set all others to defaults 
if exist('vfoptions','var')==0
    %If vfoptions is not given, just use all the defaults
    vfoptions.parallel=2;
    vfoptions.phiaprimematrix=2; % 1 is matrix, 2 if function
    %Note that the defaults will be set when we call 'ValueFnIter...'
    %commands and the like, so no need to set them here except for a few.
else
    %Check vfoptions for missing fields, if there are some fill them with the defaults
    if isfield(vfoptions,'parallel')==0
        vfoptions.parallel=2;
    end
    if isfield(vfoptions,'phiaprimematrix')==0
        vfoptions.phiaprimematrix=2; % 1 is matrix, 2 is function
    end
end

if exist('simoptions','var')==0
    %Create a 'fakeoption' that can be passed and ignored (just so that simoptions does exist)
    simoptions.fakeoptions=1;
    %Note that the defaults will be set when we call 'StationaryDist...'
    %commands and the like, so no need to set them here except for a few.
end

if exist('heteroagentoptions','var')==0
    heteroagentoptions.multiGEcritereon=1;
    heteroagentoptions.verbose=0;
else
    if isfield(heteroagentoptions,'multiGEcriterion')==0
        heteroagentoptions.multiGEcriterion=1;
    end
    if N_p~=0
        if isfield(heteroagentoptions,'p_grid')==0
            disp('VFI Toolkit ERROR: you have set n_p to a non-zero value, but not declared heteroagentoptions.pgrid')
        end
    end
    if isfield(heteroagentoptions,'verbose')==0
        heteroagentoptions.verbose=0;
    end
    if isfield(heteroagentoptions,'fminalgo')==0
        heteroagentoptions.fminalgo=1; % use fminsearch
    end
end

%%

if vfoptions.phiaprimematrix==1
    zerosinphi_aprimekron=sum(sum(sum(sum(Phi_aprimeKron==0))));
    fprintf('If this number is not zero there is an problem with Phi_aprime Matrix: %.0f', zerosinphi_aprimekron)
end

%%
if N_p~=0
    [p_eqm,p_eqm_index,GeneralEqmConditions]=HeteroAgentStationaryEqm_Case2_FHorz_pgrid(jequaloneDist,AgeWeights,n_d, n_a, n_z, N_j, n_p, pi_z, d_grid, a_grid, z_grid, Phi_aprimeKron, Case2_Type, ReturnFn, SSvaluesFn, GeneralEqmEqns, Parameters, DiscountFactorParamNames, ReturnFnParamNames, PhiaprimeParamNames, SSvalueParamNames, GeneralEqmEqnParamNames, GEPriceParamNames,heteroagentoptions, simoptions, vfoptions);
    return
end

%%  Otherwise, use fminsearch to find the general equilibrium
GeneralEqmConditionsFn=@(p) HeteroAgentStationaryEqm_Case2_FHorz_subfn(p,jequaloneDist,AgeWeights, n_d, n_a, n_z, N_j, pi_z, d_grid, a_grid, z_grid, Phi_aprimeKron, Case2_Type, ReturnFn, SSvaluesFn, GeneralEqmEqns, Parameters, DiscountFactorParamNames, ReturnFnParamNames, PhiaprimeParamNames, SSvalueParamNames, GeneralEqmEqnParamNames, GEPriceParamNames,heteroagentoptions, simoptions, vfoptions)

p0=nan(length(GEPriceParamNames),1);
for ii=1:length(GEPriceParamNames)
    p0(ii)=Parameters.(GEPriceParamNames{ii});
end

if heteroagentoptions.fminalgo==0 % fzero doesn't appear to be a good choice in practice, at least not with it's default settings.
    heteroagentoptions.multimarketcriterion=0;
    [p_eqm,GeneralEqmConditions]=fzero(GeneralEqmConditionsFn,p0);    
elseif heteroagentoptions.fminalgo==1
    [p_eqm,GeneralEqmConditions]=fminsearch(GeneralEqmConditionsFn,p0);
else
    [p_eqm,GeneralEqmConditions]=fminsearch(GeneralEqmConditionsFn,p0);
end

p_eqm_index=nan; % If not using p_grid then this is irrelevant/useless


end