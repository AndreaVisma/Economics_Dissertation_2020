function [SSvalues_QuantileCutOffs, SSvalues_QuantileMeans]=SSvalues_Quantiles_Case1(StationaryDist, PolicyIndexes, SSvaluesFn, Parameters, SSvalueParamNames, NumQuantiles, n_d, n_a, n_z, d_grid, a_grid, z_grid,Parallel)
%Returns the cut-off values and the within percentile means from dividing
%the StationaryDist into NumPercentiles percentiles.

Tolerance=10^(-12); % Numerical tolerance used when calculating min and max values.

%Note that to unnormalize the Lorenz Curve you can just multiply it be the
%SSvalues_AggVars for the same variable. This will give you the inverse
%cdf.

if n_d(1)==0
    l_d=0;
else
    l_d=length(n_d);
end
l_a=length(n_a);
l_z=length(n_z);

N_a=prod(n_a);
N_z=prod(n_z);

StationaryDistVec=reshape(StationaryDist,[N_a*N_z,1]);

if Parallel==2    
    SSvalues_QuantileCutOffs=zeros(length(SSvaluesFn),NumQuantiles+1,'gpuArray'); %Includes min and max
    SSvalues_QuantileMeans=zeros(length(SSvaluesFn),NumQuantiles,'gpuArray');
    
    PolicyValues=PolicyInd2Val_Case1(PolicyIndexes,n_d,n_a,n_z,d_grid,a_grid, Parallel);
    permuteindexes=[1+(1:1:(l_a+l_z)),1];
    PolicyValuesPermute=permute(PolicyValues,permuteindexes); %[n_a,n_s,l_d+l_a]
    
    for i=1:length(SSvaluesFn)
        % Includes check for cases in which no parameters are actually required
        if isempty(SSvalueParamNames)% || strcmp(SSvalueParamNames(1),'')) % check for 'SSvalueParamNames={}'
            SSvalueParamsVec=[];
        else
            SSvalueParamsVec=CreateVectorFromParams(Parameters,SSvalueParamNames(i).Names);
        end
        
        Values=ValuesOnSSGrid_Case1(SSvaluesFn{i}, SSvalueParamsVec,PolicyValuesPermute,n_d,n_a,n_z,a_grid,z_grid,Parallel);
        Values=reshape(Values,[N_a*N_z,1]);
        
        [SortedValues,SortedValues_index] = sort(Values);
        SortedWeights = StationaryDistVec(SortedValues_index);
        
        CumSumSortedWeights=cumsum(SortedWeights);
        
        WeightedValues=Values.*StationaryDistVec;
        SortedWeightedValues=WeightedValues(SortedValues_index);
        
        QuantileIndexes=zeros(1,NumQuantiles-1,'gpuArray');
        QuantileCutoffs=zeros(1,NumQuantiles-1,'gpuArray');
        QuantileMeans=zeros(1,NumQuantiles,'gpuArray');
        for ii=1:NumQuantiles-1
            [~,tempindex]=find(CumSumSortedWeights>=ii/NumQuantiles,1,'first');
            QuantileIndexes(ii)=tempindex;
            QuantileCutoffs(ii)=SortedValues(tempindex);
            if ii==1
                QuantileMeans(ii)=sum(SortedWeightedValues(1:tempindex))./CumSumSortedWeights(tempindex); %Could equally use sum(SortedWeights(1:tempindex)) in denominator
            elseif (1<ii) && (ii<(NumQuantiles-1))
                QuantileMeans(ii)=sum(SortedWeightedValues(QuantileIndexes(ii-1)+1:tempindex))./(CumSumSortedWeights(tempindex)-CumSumSortedWeights(QuantileIndexes(ii-1)));
            elseif ii==(NumQuantiles-1)
                QuantileMeans(ii)=sum(SortedWeightedValues(QuantileIndexes(ii-1)+1:tempindex))./(CumSumSortedWeights(tempindex)-CumSumSortedWeights(QuantileIndexes(ii-1)));
                QuantileMeans(ii+1)=sum(SortedWeightedValues(tempindex+1:end))./(CumSumSortedWeights(end)-CumSumSortedWeights(tempindex));
            end
        end
        
        % Min value
        [~,tempindex]=find(CumSumSortedWeights>=Tolerance,1,'first');
        minvalue=SortedValues(tempindex);
        % Max value
        [~,tempindex]=find(CumSumSortedWeights>=(1-Tolerance),1,'first');
        maxvalue=SortedValues(tempindex);
        
        SSvalues_QuantileCutOffs(i,:)=[minvalue, QuantileCutoffs, maxvalue];
        SSvalues_QuantileMeans(i,:)=QuantileMeans;
    end
    
else
    SSvalues_QuantileCutOffs=zeros(length(SSvaluesFn),NumQuantiles+1); %Includes min and max
    SSvalues_QuantileMeans=zeros(length(SSvaluesFn),NumQuantiles);
    d_val=zeros(l_d,1);
    aprime_val=zeros(l_a,1);
    a_val=zeros(l_a,1);
    s_val=zeros(l_z,1);
    
    PolicyIndexesKron=reshape(PolicyIndexes,[l_d+l_a,N_a,N_z]);
    
    for i=1:length(SSvaluesFn)
        Values=zeros(N_a,N_z);
        % Includes check for cases in which no parameters are actually required
        if isempty(SSvalueParamNames) % check for 'SSvalueParamNames={}'
            if l_d==0
                for j1=1:N_a
                    a_ind=ind2sub_homemade([n_a],j1);
                    for jj1=1:l_a
                        if jj1==1
                            a_val(jj1)=a_grid(a_ind(jj1));
                        else
                            a_val(jj1)=a_grid(a_ind(jj1)+sum(n_a(1:jj1-1)));
                        end
                    end
                    for j2=1:N_z
                        s_ind=ind2sub_homemade([n_z],j2);
                        for jj2=1:l_z
                            if jj2==1
                                s_val(jj2)=z_grid(s_ind(jj2));
                            else
                                s_val(jj2)=z_grid(s_ind(jj2)+sum(n_z(1:jj2-1)));
                            end
                        end
                        d_val=0;
                        aprime_ind=PolicyIndexesKron(l_d+1:l_d+l_a,j1,j2);
                        for kk=1:l_a
                            if kk==1
                                aprime_val(kk)=a_grid(aprime_ind(kk));
                            else
                                aprime_val(kk)=a_grid(aprime_ind(kk)+sum(n_a(1:kk-1)));
                            end
                        end
                        Values(j1,j2)=SSvaluesFn{i}(aprime_val,a_val,s_val);
                    end
                end
            else
                for j1=1:N_a
                    a_ind=ind2sub_homemade([n_a],j1);
                    for jj1=1:l_a
                        if jj1==1
                            a_val(jj1)=a_grid(a_ind(jj1));
                        else
                            a_val(jj1)=a_grid(a_ind(jj1)+sum(n_a(1:jj1-1)));
                        end
                    end
                    for j2=1:N_z
                        s_ind=ind2sub_homemade([n_z],j2);
                        for jj2=1:l_z
                            if jj2==1
                                s_val(jj2)=z_grid(s_ind(jj2));
                            else
                                s_val(jj2)=z_grid(s_ind(jj2)+sum(n_z(1:jj2-1)));
                            end
                        end
                        d_ind=PolicyIndexesKron(1:l_d,j1,j2);
                        for kk=1:l_d
                            if kk==1
                                d_val(kk)=d_grid(d_ind(kk));
                            else
                                d_val(kk)=d_grid(d_ind(kk)+sum(n_d(1:kk-1)));
                            end
                        end
                        aprime_ind=PolicyIndexesKron(l_d+1:l_d+l_a,j1,j2);
                        for kk=1:l_a
                            if kk==1
                                aprime_val(kk)=a_grid(aprime_ind(kk));
                            else
                                aprime_val(kk)=a_grid(aprime_ind(kk)+sum(n_a(1:kk-1)));
                            end
                        end
                        Values(j1,j2)=SSvaluesFn{i}(d_val,aprime_val,a_val,s_val);
                    end
                end
            end
        else
            SSvalueParamsVec=CreateVectorFromParams(Parameters,SSvalueParamNames(i).Names);
            if l_d==0
                for j1=1:N_a
                    a_ind=ind2sub_homemade([n_a],j1);
                    for jj1=1:l_a
                        if jj1==1
                            a_val(jj1)=a_grid(a_ind(jj1));
                        else
                            a_val(jj1)=a_grid(a_ind(jj1)+sum(n_a(1:jj1-1)));
                        end
                    end
                    for j2=1:N_z
                        s_ind=ind2sub_homemade([n_z],j2);
                        for jj2=1:l_z
                            if jj2==1
                                s_val(jj2)=z_grid(s_ind(jj2));
                            else
                                s_val(jj2)=z_grid(s_ind(jj2)+sum(n_z(1:jj2-1)));
                            end
                        end
                        d_val=0;
                        aprime_ind=PolicyIndexesKron(l_d+1:l_d+l_a,j1,j2);
                        for kk=1:l_a
                            if kk==1
                                aprime_val(kk)=a_grid(aprime_ind(kk));
                            else
                                aprime_val(kk)=a_grid(aprime_ind(kk)+sum(n_a(1:kk-1)));
                            end
                        end
                        Values(j1,j2)=SSvaluesFn{i}(aprime_val,a_val,s_val,SSvalueParamsVec);
                    end
                end
            else
                for j1=1:N_a
                    a_ind=ind2sub_homemade([n_a],j1);
                    for jj1=1:l_a
                        if jj1==1
                            a_val(jj1)=a_grid(a_ind(jj1));
                        else
                            a_val(jj1)=a_grid(a_ind(jj1)+sum(n_a(1:jj1-1)));
                        end
                    end
                    for j2=1:N_z
                        s_ind=ind2sub_homemade([n_z],j2);
                        for jj2=1:l_z
                            if jj2==1
                                s_val(jj2)=z_grid(s_ind(jj2));
                            else
                                s_val(jj2)=z_grid(s_ind(jj2)+sum(n_z(1:jj2-1)));
                            end
                        end
                        d_ind=PolicyIndexesKron(1:l_d,j1,j2);
                        for kk=1:l_d
                            if kk==1
                                d_val(kk)=d_grid(d_ind(kk));
                            else
                                d_val(kk)=d_grid(d_ind(kk)+sum(n_d(1:kk-1)));
                            end
                        end
                        aprime_ind=PolicyIndexesKron(l_d+1:l_d+l_a,j1,j2);
                        for kk=1:l_a
                            if kk==1
                                aprime_val(kk)=a_grid(aprime_ind(kk));
                            else
                                aprime_val(kk)=a_grid(aprime_ind(kk)+sum(n_a(1:kk-1)));
                            end
                        end
                        Values(j1,j2)=SSvaluesFn{i}(d_val,aprime_val,a_val,s_val,SSvalueParamsVec);
                    end
                end
            end
        end
        
        Values=reshape(Values,[N_a*N_z,1]);
        
        [SortedValues,SortedValues_index] = sort(Values);
        SortedWeights = StationaryDistVec(SortedValues_index);
        
        CumSumSortedWeights=cumsum(SortedWeights);
        
        WeightedValues=Values.*StationaryDistVec;
        SortedWeightedValues=WeightedValues(SortedValues_index);
        
        QuantileIndexes=zeros(1,NumQuantiles-1);
        QuantileCutoffs=zeros(1,NumQuantiles-1);
        QuantileMeans=zeros(1,NumQuantiles);
        for ii=1:NumQuantiles-1
            [~,tempindex]=find(CumSumSortedWeights>=ii/NumQuantiles,1,'first');
            QuantileIndexes(ii)=tempindex;
            QuantileCutoffs(ii)=SortedValues(tempindex);
            if ii==1
                QuantileMeans(ii)=sum(SortedWeightedValues(1:tempindex))./CumSumSortedWeights(tempindex); %Could equally use sum(SortedWeights(1:tempindex)) in denominator
            elseif (1<ii) && (ii<(NumQuantiles-1))
                QuantileMeans(ii)=sum(SortedWeightedValues(QuantileIndexes(ii-1)+1:tempindex))./(CumSumSortedWeights(tempindex)-CumSumSortedWeights(QuantileIndexes(ii-1)));
            elseif ii==(NumQuantiles-1)
                QuantileMeans(ii)=sum(SortedWeightedValues(QuantileIndexes(ii-1)+1:tempindex))./(CumSumSortedWeights(tempindex)-CumSumSortedWeights(QuantileIndexes(ii-1)));
                QuantileMeans(ii+1)=sum(SortedWeightedValues(tempindex+1:end))./(CumSumSortedWeights(end)-CumSumSortedWeights(tempindex));
            end
        end
        
        % Min value
        [~,tempindex]=find(CumSumSortedWeights>=Tolerance,1,'first');
        minvalue=SortedValues(tempindex);
        % Max value
        [~,tempindex]=find(CumSumSortedWeights>=(1-Tolerance),1,'first');
        maxvalue=SortedValues(tempindex);
        
        SSvalues_QuantileCutOffs(i,:)=[minvalue, QuantileCutoffs, maxvalue];
        SSvalues_QuantileMeans(i,:)=QuantileMeans;
    end
    
end


end

