function StationaryDistKron=StationaryDist_FHorz_Case2_AgeDepGrids_Iteration_raw(jequaloneDistKron,AgeWeightParamNames,PolicyKron,daz_gridstructure,N_j,Phi_aprime,Case2_Type,Parameters,PhiaprimeParamNames,simoptions)
%Will treat the agents as being on a continuum of mass 1.

% Options needed
%  simoptions.maxit
%  simoptions.tolerance
%  simoptions.parallel

if simoptions.parallel<2
    
    StationaryDistKron=struct();
    StationaryDistKron.j001=jequaloneDistKron;

    if vfoptions.phiaprimedependsonage==0
        fprintf('ERROR: state dependent grids and Case2 mean that you must have vfoptions.phiaprimedependsonage==1')
    end

    if simoptions.phiaprimedependsonage==0
        PhiaprimeParamsVec=CreateVectorFromParams(Parameters, PhiaprimeParamNames);
        if simoptions.lowmemory==0
            Phi_aprimeMatrix=CreatePhiaprimeMatrix_Case2_Disc_Par2(Phi_aprime, Case2_Type, n_d, n_a, n_z, d_grid, a_grid, z_grid,PhiaprimeParamsVec);
        end
    end    
    
    for jj=1:(N_j-1)
        
        % Make a three digit number out of jj
        jstr=daz_gridstructure.jstr{jj};
        jjplus1=jj+1;
        % Make a three digit number out of jjplus1
        jplus1str=daz_gridstructure.jstr{jjplus1};
        % Get the relevant grid and transition matrix
        if simoptions.agedependentgrids(1)==1
            N_d=daz_gridstructure.N_d.(jstr(:));
            n_d=daz_gridstructure.n_d.(jstr(:));
        end
        if simoptions.agedependentgrids(2)==1
            N_a=daz_gridstructure.N_a.(jstr(:));
            n_a=daz_gridstructure.n_a.(jstr(:));
            N_aprime=daz_gridstructure.N_aprime.(jstr(:));
        end
        if simoptions.agedependentgrids(3)==1
            N_z=daz_gridstructure.N_z.(jstr(:));
            n_z=daz_gridstructure.n_z.(jstr(:));
            pi_z=daz_gridstructure.pi_z.(jstr(:));
            N_zprime=daz_gridstructure.N_z.(jstr(:));
        end
                
        if simoptions.phiaprimedependsonage==1
            PhiaprimeParamsVec=CreateVectorFromParams(Parameters, PhiaprimeParamNames,jj);
            Phi_aprimeMatrix=CreatePhiaprimeMatrix_Case2_Disc_Par2(Phi_aprime, Case2_Type, n_d, n_a, n_z, d_grid, a_grid, z_grid,PhiaprimeParamsVec);
        end
        
        PolicyKron_j=PolicyKron.(jstr);
        %First, generate the transition matrix P=g of Q (the convolution of the optimal policy function and the transition fn for exogenous shocks)
        P=zeros(N_a,N_z,N_aprime,N_zprime); %P(a,z,aprime,zprime)=proby of going to (a',z') given in (a,z)
        for a_c=1:N_a
            for z_c=1:N_z
                optd=PolicyKron_j(a_c,z_c);
                if Case2_Type==1 % a'(d,a,z,z')
                    for zprime_c=1:N_zprime
                        optaprime=Phi_aprimeMatrix(optd,a_c,z_c,zprime_c);
                    end
                elseif Case2_Type==11 % a'(d,a,z')
                    for zprime_c=1:N_zprime
                        optaprime=Phi_aprimeMatrix(optd,a_c,zprime_c);
                    end
                elseif Case2_Type==12 % a'(d,a,z)
                    optaprime=Phi_aprimeMatrix(optd,a_c,z_c);
                elseif Case2_Type==2 % a'(d,z,z')
                    for zprime_c=1:N_zprime
                        optaprime=Phi_aprimeMatrix(optd,z_c,zprime_c);
                    end
                end
                for zprime_c=1:N_zprime
                    P(a_c,z_c,optaprime,zprime_c)=pi_z(z_c,zprime_c)/sum(pi_z(z_c,:));
                end
            end
        end
        P=reshape(P,[N_a*N_z,N_aprime*N_zprime]);
        P=P';
        
        StationaryDistKron.(jplus1str)=P*StationaryDistKron.(jstr);
    end
    
elseif simoptions.parallel==2 % GPU
    
    StationaryDistKron=struct();
    StationaryDistKron.j001=jequaloneDistKron;
    
    if simoptions.phiaprimedependsonage==0
        PhiaprimeParamsVec=CreateVectorFromParams(Parameters, PhiaprimeParamNames);
        if simoptions.lowmemory==0
            Phi_aprimeMatrix=CreatePhiaprimeMatrix_Case2_Disc_Par2(Phi_aprime, Case2_Type, n_d, n_a, n_z, d_grid, a_grid, z_grid,PhiaprimeParamsVec);
        end
    end
    
    % First, generate the transition matrix P=g of Q (the convolution of the 
    % optimal policy function and the transition fn for exogenous shocks)
    for jj=1:(N_j-1)
        
        % Make a three digit number out of jj
        jstr=daz_gridstructure.jstr{jj};
        jjplus1=jj+1;
        % Make a three digit number out of jjplus1
        jplus1str=daz_gridstructure.jstr{jjplus1};
        % Get the relevant grid and transition matrix
        if simoptions.agedependentgrids(1)==1
            N_d=daz_gridstructure.N_d.(jstr(:));
            n_d=daz_gridstructure.n_d.(jstr(:));
            d_grid=daz_gridstructure.d_grid.(jstr(:));
        end
        if simoptions.agedependentgrids(2)==1
            N_a=daz_gridstructure.N_a.(jstr(:));
            n_a=daz_gridstructure.n_a.(jstr(:));
            N_aprime=daz_gridstructure.N_aprime.(jstr(:));
            a_grid=daz_gridstructure.a_grid.(jstr(:));
        end
        if simoptions.agedependentgrids(3)==1
            N_z=daz_gridstructure.N_z.(jstr(:));
            n_z=daz_gridstructure.n_z.(jstr(:));
            pi_z=daz_gridstructure.pi_z.(jstr(:));
            z_grid=daz_gridstructure.z_grid.(jstr(:));
            N_zprime=daz_gridstructure.N_zprime.(jstr(:));
        end

        if simoptions.phiaprimedependsonage==1
            PhiaprimeParamsVec=CreateVectorFromParams(Parameters, PhiaprimeParamNames,jj);
            Phi_aprimeMatrix=CreatePhiaprimeMatrix_Case2_Disc_Par2(Phi_aprime, Case2_Type, n_d, n_a, n_z, d_grid, a_grid, z_grid,PhiaprimeParamsVec);
        end
        
        PolicyKron_j=PolicyKron.(jstr);
        
        % Phi_of_Policy combines Phi_aprimeMatrix together with PolicyKron.
        % It gives the index for aprime as a function of (whatever
        % Phi_aprime depends on) together with (a,z).
        if Case2_Type==1 % phi(d,a,z,z')
            disp('ERROR: StationaryDist_FHorz_Case2_Iteration_raw() not yet implemented for Case2_Type==1')
            % Phi_of_policy: a'(a,z,z')
            Phi_of_Policy=zeros(N_a,N_zprime,N_z,'gpuArray'); %a'(d,z',z)
%             for z_c=1:N_z
%                 Phi_of_Policy(:,:,z_c)=Phi_aprimeMatrix(PolicyKron_j(:,z_c),:,:,z_c);
%             end
            % Create P matrix
            Ptemp=zeros(N_a,N_aprime*N_z*N_zprime,'gpuArray');
            Ptemp(reshape(permute(Phi_of_Policy,[2,1,3]),[1,N_a*N_z*N_zprime])+N_aprime*(gpuArray(0:1:N_a*N_z*N_zprime-1)))=1;
            Ptran=kron(pi_z',ones(N_aprime,N_a,'gpuArray')).*reshape(Ptemp,[N_aprime*N_zprime,N_a*N_z]);
        elseif Case2_Type==11 % phi(d,a,z')
            disp('WARNING: StationaryDist_FHorz_Case2_Iteration_raw() is implemented but not been tested for Case2_Type==11')
            % Phi_of_policy: a'(a,z,z')
            Phi_of_Policy=zeros(N_a*N_zprime,N_z,'gpuArray'); %a'(d,z',z)
            for z_c=1:N_z
                Phi_of_Policy(:,z_c)=Phi_aprimeMatrix(PolicyKron_j(:,z_c),:,z_c);
            end
            % Create P matrix
            Ptemp=zeros(N_a,N_aprime*N_z*N_zprime,'gpuArray');
            Ptemp(reshape(permute(Phi_of_Policy,[2,1,3]),[1,N_a*N_z*N_zprime])+N_aprime*(gpuArray(0:1:N_a*N_z*N_zprime-1)))=1;
            Ptran=kron(pi_z',ones(N_aprime,N_a,'gpuArray')).*reshape(Ptemp,[N_aprime*N_zprime,N_a*N_z]);
        elseif Case2_Type==12 % phi(d,a,z)
            % Phi_of_policy: a'(a,z)
            Phi_of_Policy=zeros(N_a*N_z,1,'gpuArray'); %a'(a,z)
            aindexes=kron((1:1:N_a)',ones(N_z,1));
            zindexes=kron(ones(N_a,1),(1:1:N_z)');
            Phi_of_Policy=Phi_aprimeMatrix(PolicyKron_j(:)+N_d*(aindexes-1)+N_d*N_a*(zindexes-1));
%             if simoptions.verbose==1 && jj<5 % Phi_of_Policy seems
%             exactly as expected. Namely an aprime index (a strictly positive integer) for each (a,z)
%                 fprintf('Info on Phi_of_Policy \n')
%                 size(Phi_of_Policy)
%                 [N_a,N_z]
%                 [min(Phi_of_Policy), max(Phi_of_Policy)]
%                 sum(isfinite(Phi_of_Policy))
%                 sum(abs(Phi_of_Policy-round(Phi_of_Policy))>10^(-10))
%             end
            Ptemp=zeros(N_a,N_aprime*N_z*N_zprime,'gpuArray');
            Ptemp(kron(reshape(Phi_of_Policy,[1,N_a*N_z]),ones(1,N_zprime))+N_aprime*(gpuArray(0:1:N_a*N_z*N_zprime-1)))=1;
%             Ptemp(reshape(Phi_of_Policy,[1,N_a*N_z])+N_aprime*N_zprime*(gpuArray(0:1:N_a*N_z-1)))=1;
%             if simoptions.verbose==1 && jj<5
%                 fprintf('Info on Ptemp \n')
%                 size(reshape(Phi_of_Policy,[1,N_a*N_z])+N_aprime*N_zprime*(gpuArray(0:1:N_a*N_z-1)))
%                 size(Ptemp)
%                 % There should be one aprime value for each (a,z,zprime)
%                 temp=sum(Ptemp,1); 
%                 [min(temp), max(temp)] % These should both be equal to one
%                 % Appears that the problem is that for some (a,z,zprime) it does not tell you to go anywhere
%                 [sum(sum(Ptemp)), N_a*N_z*N_zprime]
%             end
            Ptran=kron(pi_z',ones(N_aprime,N_a,'gpuArray')).*reshape(Ptemp,[N_aprime*N_zprime,N_a*N_z]);
%             if simoptions.verbose==1 && jj<5
%                 fprintf('Following should both be equal to one \n')
%                 [min(sum(Ptran)), max(sum(Ptran))] % Tranposed, so it is the column that should sum to one (take sum across the row dimension).
%                 temp=kron(pi_z',ones(N_aprime,N_a,'gpuArray'));
%                 [min(sum(pi_z')), max(sum(pi_z'))]
%                 [min(sum(temp)), max(sum(temp))]
%                 temp2=reshape(Ptemp,[N_aprime*N_zprime,N_a*N_z]); % There should be one aprime value for each (a,z,zprime).
%                 % So for each (a,z) there should be zprime values.
%                 [min(sum(Ptemp,1)), max(sum(Ptemp,1))]
%                 
%                 
%             end
        elseif Case2_Type==2  % phi(d,z',z)
            % Phi_of_policy: a'(a,z',z)
            Phi_of_Policy=zeros(N_a,N_zprime,N_z,'gpuArray'); %a'(d,z',z)
            for z_c=1:N_z
                Phi_of_Policy(:,:,z_c)=Phi_aprimeMatrix(PolicyKron_j(:,z_c),:,z_c);
            end
            Ptemp=zeros(N_a,N_aprime*N_z*N_zprime,'gpuArray');
            Ptemp(reshape(permute(Phi_of_Policy,[2,1,3]),[1,N_a*N_z*N_zprime])+N_aprime*(gpuArray(0:1:N_a*N_z*N_zprime-1)))=1;
            Ptran=kron(pi_z',ones(N_aprime,N_a,'gpuArray')).*reshape(Ptemp,[N_aprime*N_zprime,N_a*N_z]);
        end
        
        StationaryDistKron.(jplus1str)=Ptran*StationaryDistKron.(jstr);
    end
    
elseif simoptions.parallel>2 % Same as <2, but using sparse matrices. To make it faster I do some vectorization.
    
    StationaryDistKron=struct();
    StationaryDistKron.j001=jequaloneDistKron;

    if simoptions.phiaprimedependsonage==0
        fprintf('ERROR: state dependent grids and Case2 mean that you must have simoptions.phiaprimedependsonage==1')
    end

    if simoptions.phiaprimedependsonage==0
        PhiaprimeParamsVec=CreateVectorFromParams(Parameters, PhiaprimeParamNames);
        if simoptions.lowmemory==0
            Phi_aprimeMatrix=CreatePhiaprimeMatrix_Case2_Disc_Par2(Phi_aprime, Case2_Type, n_d, n_a, n_z, d_grid, a_grid, z_grid,PhiaprimeParamsVec);
        end
    end    
    
    for jj=1:(N_j-1)
        
        % Make a three digit number out of jj
        jstr=daz_gridstructure.jstr{jj};
        jjplus1=jj+1;
        % Make a three digit number out of jjplus1
        jplus1str=daz_gridstructure.jstr{jjplus1};
        % Get the relevant grid and transition matrix
        if simoptions.agedependentgrids(1)==1
            N_d=daz_gridstructure.N_d.(jstr(:));
            n_d=daz_gridstructure.n_d.(jstr(:));
            d_grid=daz_gridstructure.d_grid.(jstr(:));
        end
        if simoptions.agedependentgrids(2)==1
            N_a=daz_gridstructure.N_a.(jstr(:));
            n_a=daz_gridstructure.n_a.(jstr(:));
            N_aprime=daz_gridstructure.N_aprime.(jstr(:));
            a_grid=daz_gridstructure.a_grid.(jstr(:));
        end
        if simoptions.agedependentgrids(3)==1
            N_z=daz_gridstructure.N_z.(jstr(:));
            n_z=daz_gridstructure.n_z.(jstr(:));
            z_grid=daz_gridstructure.z_grid.(jstr(:));
            pi_z=daz_gridstructure.pi_z.(jstr(:));
            pi_z_cpu=daz_gridstructure.pi_z_cpu.(jstr(:));
            N_zprime=daz_gridstructure.N_zprime.(jstr(:));
        end
                
        if simoptions.phiaprimedependsonage==1
            PhiaprimeParamsVec=CreateVectorFromParams(Parameters, PhiaprimeParamNames,jj);
            Phi_aprimeMatrix=gather(CreatePhiaprimeMatrix_Case2_Disc_Par2(Phi_aprime, Case2_Type, n_d, n_a, n_z, d_grid, a_grid, z_grid,PhiaprimeParamsVec));
        end
        
        PolicyKron_j=PolicyKron.(jstr);
        %First, generate the transition matrix P=g of Q (the convolution of the optimal policy function and the transition fn for exogenous shocks)
        if Case2_Type==1 %phi(d,a,z,z')
            
        elseif Case2_Type==11 % phi(d,a,z')
            
        elseif Case2_Type==12 % phi(d,a,z)
            Phi_of_Policy=zeros(N_a*N_z,1); %a'(a,z) % Contains the aprime indexes
            aindexesvec=kron((1:1:N_a)',ones(N_z,1)); % Size az-by-1
            zindexesvec=kron(ones(N_a,1),(1:1:N_z)'); % Size az-by-1
            Phi_of_Policy=Phi_aprimeMatrix(PolicyKron_j(:)+N_d*(aindexesvec-1)+N_d*N_a*(zindexesvec-1)); % Size az-by-1
            % The following lines of code are just about creating the sparse matrix in a fast way: https://au.mathworks.com/matlabcentral/answers/203734-most-efficient-way-to-add-multiple-sparse-matrices-in-a-loop-in-matlab            
            % Calculate number of non-zero entries in P. It will be
            % N_a*(number of non-zero entries in pi_z)
            % Notice that the roles of both z and zprime are captured by pi_z
            
            binary_pi_z=pi_z_cpu;
            binary_pi_z(binary_pi_z>0)=1;
            
            % Create a version of Phi_of_Policy which has a'(a,z,z'), but only for the z' which are non-zero transition probabilities.
%             tic;
            PaprimeIndex=Phi_of_Policy.*kron(binary_pi_z,ones(N_a,1)); % There should be a better way to do this and the next step
            PaprimeIndex=PaprimeIndex(PaprimeIndex>0);
%             time1=toc
            
            % SLOWER LOWER MEMORY VERSION THAT TAKES GREATER ADVANTAGE OF SPARSENESS
%             tic;
%             nonzerotransitions=sum(binary_pi_z,2);
%             PaprimeIndex2=repelem(reshape(Phi_of_Policy,[N_a,N_z]),1,nonzerotransitions');
%             PaprimeIndex2=reshape(PaprimeIndex2,[N_a*sum(nonzerotransitions),1]);
%             time2=toc
                        
            % The non-zero-elements-only version of PaprimezprimeIndex is
            % roughly one-fifthtieth the size. Can I skip straight to it in
            % a memory efficient way?
            
            % Really should work on the gpu till here and only go to cpu when switching to sparse.
            
            % The transition probabilities themselves can be gotten from kron(ones(N_a,1),pi_z)
%             Pvalues=kron(ones(N_a,1),pi_z_cpu); % THIS WAS INCORRECT
            Pvalues=kron(pi_z_cpu,ones(N_a,1));
            Pvalues=Pvalues(Pvalues>0);
            
            PzprimeIndex=kron(ones(N_a,1),(binary_pi_z.*(ones(N_z,1)*1:1:N_zprime)));
            PzprimeIndex=PzprimeIndex(PzprimeIndex>0);
            
            PaprimezprimeIndex=PaprimeIndex+N_aprime*(PzprimeIndex-1);
            PaprimezprimeIndex=PaprimezprimeIndex(PaprimezprimeIndex>0); %Is this line actually of any purpose? PaprimeIndex is already just the non-zeros, so won't PaprimeIndex also be by construction (on previous line)?
                        
            % Phi_of_Policy gives me the aprime indexes
            % kron(ones(N_a,1),binary_pi_z) gives me the zprime indexes (once I remove the zeros)
            % And kron(ones(N_a,1),pi_z) gives me the transition probabilities (once I remove the zeros)
            Paz1=(kron(ones(N_z,1),(1:1:N_a)')+N_a*kron(((1:1:N_z)'-1),ones(N_a,1)));
            PazIndex=Paz1.*kron(binary_pi_z,ones(N_a,1));
            PazIndex=PazIndex(PazIndex>0);
            
            % So now it is just a matter of putting them together as a sparse matrix
            Ptranspose=sparse(PaprimezprimeIndex,PazIndex,Pvalues,N_aprime*N_zprime,N_a*N_z); % I is the (aprime-by-zprime)-index, J is the (a-by-z)-index.

            % FOLLOWING LINES ARE LEFTOVERS FROM A DEBUG. TO BE DELETED.
%             if jj==37 || jj==38 || jj==39
%                 jj
%                 [N_a, N_z]
%                 fprintf('Phi_of_Policy stuff')
%                 size(Phi_of_Policy)
%                 [min(Phi_of_Policy),max(Phi_of_Policy)]
%                 fprintf('Pvalues stuff')
%                 size(Pvalues)
%                 [N_a, sum(sum(pi_z_cpu>0))]
%                 sum(Pvalues)
%                 fprintf('pi_z_cpu stuff that should both evaluate to one \n')
%                 [min(sum(pi_z_cpu,2)), max(sum(pi_z_cpu,2))]
%                 fprintf('Ptranspose stuff that should both evaluate to one \n')
%                 [min(sum(Ptranspose)), max(sum(Ptranspose))]
%                 [min(sum(Ptranspose,2)), max(sum(Ptranspose,2))]
%                 size(Ptranspose)
%             end
            
        elseif Case2_Type==2 % phi(d,z',z)
            
        end
        
        StationaryDistKron.(jplus1str)=Ptranspose*(StationaryDistKron.(jstr));
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
% I assume AgeWeights is a row vector
for jj=1:N_j
    jstr=daz_gridstructure.jstr{jj};    
    StationaryDistKron.(jstr)=StationaryDistKron.(jstr)*AgeWeights(jj);
end
StationaryDistKron.AgeWeights=AgeWeights; % Save recalculating this later whenever I need to draw randomly from the stationary distribution.


end