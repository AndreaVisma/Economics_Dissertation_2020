function AgentDist=StationaryDist_FHorz_Case1_TPath_SingleStep_Simulation_raw(AgentDist,AgeWeightParamNames,PolicyIndexesKron,N_d,N_a,N_z,N_j,pi_z, Parameters, simoptions)

% Options needed
%    simoptions.nsims (will do nsims per age)
%    simoptions.parallel
%    simoptions.verbose
%    simoptions.ncores
% Extra options you might want
%    simoptions.ExogShockFn
%    simoptions.ExogShockFnParamNames

MoveSSDKtoGPU=0;
if simoptions.parallel==2
    % Simulation on GPU is really slow.
    % So instead, switch to CPU.
    % For anything but ridiculously short simulations it is more than worth the overhead to switch to CPU and back.
    PolicyIndexesKron=gather(PolicyIndexesKron);
    pi_z=gather(pi_z);
    % Use parallel cpu for these simulations
    simoptions.parallel=1;
    
    MoveSSDKtoGPU=1;
end

% This implementation is slightly inefficient when shocks are not age
% dependent, but speed loss is fairly trivial
eval('fieldexists_ExogShockFn=1;simoptions.ExogShockFn;','fieldexists_ExogShockFn=0;')
eval('fieldexists_ExogShockFnParamNames=1;simoptions.ExogShockFnParamNames;','fieldexists_ExogShockFnParamNames=0;')
if fieldexists_ExogShockFn==1
    pi_z_J=zeros(N_z,N_z,N_j);
    for jj=1:N_j
        if fieldexists_ExogShockFnParamNames==1
            ExogShockFnParamsVec=CreateVectorFromParams(Parameters, simoptions.ExogShockFnParamNames,jj);
            [z_grid,pi_z]=simoptions.ExogShockFn(ExogShockFnParamsVec);
        else
            [z_grid,pi_z]=simoptions.ExogShockFn(jj);
        end
        pi_z_J(:,:,jj)=gather(pi_z);
    end
else
    pi_z_J=repmat(pi_z,1,1,N_j);
end

if simoptions.parallel==1
    nsimspercore=ceil(simoptions.nsims/simoptions.ncores);
    %     disp('Create simoptions.ncores different steady state distns, then combine them')
    AgentDist=zeros(N_a,N_z,N_j,simoptions.ncores);
    cumsum_pi_z_J=cumsum(pi_z_J,2);
    jequaloneDistKroncumsum=cumsum(AgentDist);
    %Create simoptions.ncores different steady state distn's, then combine them.
    if N_d==0
        parfor ncore_c=1:simoptions.ncores
            StationaryDistKron_ncore_c=zeros(N_a,N_z,N_j);
            for ii=1:nsimspercore
                % Pull a random start point from jequaloneDistKron
                currstate=find(jequaloneDistKroncumsum>rand(1,1),1,'first'); %Pick a random start point on the (vectorized) (a,z) grid for j=1
                currstate=ind2sub_homemade([N_a,N_z],currstate);
                StationaryDistKron_ncore_c(currstate(1),currstate(2),1)=StationaryDistKron_ncore_c(currstate(1),currstate(2),1)+1;
                for jj=1:(N_j-1)
                    currstate(1)=PolicyIndexesKron(currstate(1),currstate(2),jj);
                    currstate(2)=find(cumsum_pi_z_J(currstate(2),:,jj)>rand(1,1),1,'first');
                    StationaryDistKron_ncore_c(currstate(1),currstate(2),jj+1)=StationaryDistKron_ncore_c(currstate(1),currstate(2),jj+1)+1;
                end
            end
            AgentDist(:,:,:,ncore_c)=StationaryDistKron_ncore_c;
        end
        AgentDist=sum(AgentDist,4);
        AgentDist=AgentDist./sum(sum(AgentDist,1),2);
    else
        optaprime=2;
        parfor ncore_c=1:simoptions.ncores
            StationaryDistKron_ncore_c=zeros(N_a,N_z,N_j);
            for ii=1:nsimspercore
                % Pull a random start point from jequaloneDistKron
                currstate=find(jequaloneDistKroncumsum>rand(1,1),1,'first'); %Pick a random start point on the (vectorized) (a,z) grid for j=1
                currstate=ind2sub_homemade([N_a,N_z],currstate);
                StationaryDistKron_ncore_c(currstate(1),currstate(2),1)=StationaryDistKron_ncore_c(currstate(1),currstate(2),1)+1;
                for jj=1:(N_j-1)
                    currstate(1)=PolicyIndexesKron(optaprime,currstate(1),currstate(2),jj);
                    currstate(2)=find(cumsum_pi_z_J(currstate(2),:,jj)>rand(1,1),1,'first');
                    StationaryDistKron_ncore_c(currstate(1),currstate(2),jj+1)=StationaryDistKron_ncore_c(currstate(1),currstate(2),jj+1)+1;
                end
            end
            AgentDist(:,:,:,ncore_c)=StationaryDistKron_ncore_c;
        end
        AgentDist=sum(AgentDist,4);
        AgentDist=AgentDist./sum(sum(AgentDist,1),2);
    end
elseif simoptions.parallel==0
    disp('NOW IN APPROPRIATE PART OF STATDIST') %DEBUGGING
    AgentDist=zeros(N_a,N_z,N_j);
    cumsum_pi_z_J=cumsum(pi_z_J,2);
    jequaloneDistKroncumsum=cumsum(AgentDist);
    if N_d==0
%         StationaryDistKron=zeros(N_a,N_z,N_j);
        for ii=1:simoptions.nsims
            % Pull a random start point from jequaloneDistKron
            currstate=find(jequaloneDistKroncumsum>rand(1,1),1,'first'); %Pick a random start point on the (vectorized) (a,z) grid for j=1
            currstate=ind2sub_homemade([N_a,N_z],currstate);
            AgentDist(currstate(1),currstate(2),1)=AgentDist(currstate(1),currstate(2),1)+1;
            for jj=1:(N_j-1)
                currstate(1)=PolicyIndexesKron(currstate(1),currstate(2),jj);
                currstate(2)=find(cumsum_pi_z_J(currstate(2),:,jj)>rand(1,1),1,'first');
                AgentDist(currstate(1),currstate(2),jj+1)=AgentDist(currstate(1),currstate(2),jj+1)+1;
            end
        end
        AgentDist=AgentDist./sum(sum(AgentDist,1),2);
    else
        optaprime=2;
%         StationaryDistKron=zeros(N_a,N_z,N_j);
        for ii=1:simoptions.nsims
            % Pull a random start point from jequaloneDistKron
            currstate=find(jequaloneDistKroncumsum>rand(1,1),1,'first'); %Pick a random start point on the (vectorized) (a,z) grid for j=1
            currstate=ind2sub_homemade([N_a,N_z],currstate);
            AgentDist(currstate(1),currstate(2),1)=AgentDist(currstate(1),currstate(2),1)+1;
            for jj=1:(N_j-1)
                currstate(1)=PolicyIndexesKron(optaprime,currstate(1),currstate(2),jj);
                currstate(2)=find(cumsum_pi_z_J(currstate(2),:,jj)>rand(1,1),1,'first');
                AgentDist(currstate(1),currstate(2),jj+1)=AgentDist(currstate(1),currstate(2),jj+1)+1;
            end
        end
        AgentDist=AgentDist./sum(sum(AgentDist,1),2);
    end
end


% Reweight the different ages based on 'AgeWeightParamNames'. (it is
% assumed there is only one Age Weight Parameter (name))
FullParamNames=fieldnames(Parameters);
nFields=length(FullParamNames);
found=0;
for iField=1:nFields
    if strcmp(AgeWeightParamNames{1},FullParamNames{iField})
        AgeWeights=Parameters.(FullParamNames{iField});
        found=1;
    end
end
if found==0 % Have added this check so that user can see if they are missing a parameter
    fprintf(['FAILED TO FIND PARAMETER ',AgeWeightParamNames{1}])
end
% I assume AgeWeights is a row vector, if it has been given as column then
% transpose it.
if length(AgeWeights)~=size(AgeWeights,2)
    AgeWeights=AgeWeights';
end
% AgentDist=AgentDist.*shiftdim(AgeWeights,-1);
% I assume AgeWeights is a row vector
AgentDist=AgentDist.*(ones(N_a*N_z,1)*(AgeWeights./sum(AgentDist,1))); % The sum is needed to get rid of previous period weights (implicit in the inputed AgentDist)

if MoveSSDKtoGPU==1
    AgentDist=gpuArray(AgentDist);
end

end
