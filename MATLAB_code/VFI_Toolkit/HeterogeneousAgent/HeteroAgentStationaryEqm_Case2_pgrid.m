function [p_eqm,p_eqm_index,GeneralEqmConditions]=HeteroAgentStationaryEqm_Case2_pgrid(V0Kron, n_d, n_a, n_s, n_p, pi_s, d_grid, a_grid, s_grid, Phi_aprimeKron, Case2_Type, ReturnFn, FnsToEvaluate, GeneralEqmEqns, Parameters, DiscountFactorParamNames, ReturnFnParamNames, PhiaprimeParamNames, FnsToEvaluateParamNames, GeneralEqmEqnParamNames, GEPriceParamNames,heteroagentoptions, simoptions, vfoptions)

N_d=prod(n_d);
N_a=prod(n_a);
N_s=prod(n_s);
N_p=prod(n_p);

l_p=length(n_p);

p_grid=heteroagentoptions.pgrid;

%%

if simoptions.parallel==2
    GeneralEqmConditionsKron=ones(N_p,l_p,'gpuArray');
else
    GeneralEqmConditionsKron=ones(N_p,l_p);
end
%V0Kron=reshape(V0,[N_a,N_s]);

for p_c=1:N_p
    if heteroagentoptions.verbose==1
        p_c
    end
    
    V0Kron(~isfinite(V0Kron))=0; %Since we loop through with V0Kron from previous p_c this is necessary to avoid contamination by -Inf's

    %Step 1: Solve the value fn iteration problem (given this price, indexed by p_c)
    %Calculate the price vector associated with p_c
    p_index=ind2sub_homemade(n_p,p_c);
    p=nan(l_p,1);
    for ii=1:l_p
        if ii==1
            p(ii)=p_grid(p_index(1));
        else
            p(ii)=p_grid(sum(n_p(1:ii-1))+p_index(ii));
        end
        Parameters.(GEPriceParamNames{ii})=gather(p(ii));
    end
    
    [~, Policy]=ValueFnIter_Case2(V0Kron, n_d, n_a, n_s, d_grid, a_grid, s_grid, pi_s, Phi_aprimeKron, Case2_Type, ReturnFn, Parameters, DiscountFactorParamNames, ReturnFnParamNames, PhiaprimeParamNames, vfoptions);
    
    %Step 2: Calculate the Steady-state distn (given this price) and use it to assess market clearance
    StationaryDistKron=StationaryDist_Case2(Policy,Phi_aprimeKron,Case2_Type,n_d,n_a,n_s, pi_s, simoptions);
    AggVars=EvalFnOnAgentDist_AggVars_Case2(StationaryDistKron, Policy, FnsToEvaluate, Parameters, FnsToEvaluateParamNames, n_d, n_a, n_s, d_grid, a_grid, s_grid, simoptions.parallel);
    
    % The following line is often a useful double-check if something is going wrong.
  AggVars
    
    % use of real() is a hack that could disguise errors, but I couldn't
    % find why matlab was treating output as complex
    GeneralEqmConditionsKron(p_c,:)=real(GeneralEqmConditions_Case2(AggVars,p, GeneralEqmEqns, Parameters,GeneralEqmEqnParamNames, simoptions.parallel));
end

if heteroagentoptions.multiGEcriterion==0 
    [~,p_eqm_indexKron]=min(sum(abs(GeneralEqmConditionsKron),2));
elseif heteroagentoptions.multiGEcriterion==1 % general eqm is to take the sum of squares for each of the general eqm conditions holding 
    [~,p_eqm_indexKron]=min(sum(GeneralEqmConditionsKron.^2,2));                                                                                                         
end

%p_eqm_index=zeros(num_p,1);
p_eqm_index=ind2sub_homemade_gpu(n_p,p_eqm_indexKron);
if l_p>1
    if simoptions==2
        GeneralEqmConditions=nan(N_p,1+l_p,'gpuArray');
    else
        GeneralEqmConditions=nan(N_p,1+l_p);
    end
    if heteroagentoptions.multiGEcriterion==0
        GeneralEqmConditions(:,1)=sum(abs(GeneralEqmConditionsKron),2);
    elseif heteroagentoptions.multiGEcriterion==1 % general eqm is to take the sum of squares for each of the general eqm conditions holding 
        GeneralEqmConditions(:,1)=sum(GeneralEqmConditionsKron.^2,2);
    end
    GeneralEqmConditions(:,2:end)=GeneralEqmConditionsKron;
    GeneralEqmConditions=reshape(GeneralEqmConditions,[n_p,1+l_p]);
else
    GeneralEqmConditions=reshape(GeneralEqmConditionsKron,[n_p,1]);
end


%Calculate the price associated with p_eqm_index
p_eqm=zeros(l_p,1);
for i=1:l_p
    if i==1
        p_eqm(i)=p_grid(p_eqm_index(1));
    else
        p_eqm(i)=p_grid(sum(n_p(1:i-1))+p_eqm_index(i));
    end
end

% Move results from gpu to cpu before returning them
p_eqm=gather(p_eqm);
p_eqm_index=gather(p_eqm_index);
GeneralEqmConditions=gather(GeneralEqmConditions);

end
