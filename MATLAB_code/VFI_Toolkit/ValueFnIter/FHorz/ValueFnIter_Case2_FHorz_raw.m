function [V,Policy]=ValueFnIter_Case2_FHorz_raw(n_d,n_a,n_z,N_j, d_grid, a_grid, z_grid, pi_z,Phi_aprime, Case2_Type, ReturnFn, Parameters, DiscountFactorParamNames, ReturnFnParamNames, vfoptions)

N_d=prod(n_d);
N_a=prod(n_a);
N_z=prod(n_z);

V=zeros(N_a,N_z,N_j,'gpuArray');
Policy=zeros(N_a,N_z,N_j,'gpuArray'); %indexes the optimal choice for d given rest of dimensions a,z

%%
if vfoptions.lowmemory>0
    special_n_z=ones(1,length(n_z));
    
    z_gridvals=zeros(N_z,length(n_z),'gpuArray');
    for i1=1:N_z
        sub=zeros(1,length(n_z));
        sub(1)=rem(i1-1,n_z(1))+1;
        for ii=2:length(n_z)-1
            sub(ii)=rem(ceil(i1/prod(n_z(1:ii-1)))-1,n_z(ii))+1;
        end
        sub(length(n_z))=ceil(i1/prod(n_z(1:length(n_z)-1)));
        
        if length(n_z)>1
            sub=sub+[0,cumsum(n_z(1:end-1))];
        end
        z_gridvals(i1,:)=z_grid(sub);
    end
end
if vfoptions.lowmemory>1
    special_n_a=ones(1,length(n_a));
    
    a_gridvals=zeros(N_a,length(n_a),'gpuArray');
    for i2=1:N_a
        sub=zeros(1,length(n_a));
        sub(1)=rem(i2-1,n_a(1)+1);
        for ii=2:length(n_a)-1
            sub(ii)=rem(ceil(i2/prod(n_a(1:ii-1)))-1,n_a(ii))+1;
        end
        sub(length(n_a))=ceil(i2/prod(n_a(1:length(n_a)-1)));
        
        if length(n_a)>1
            sub=sub+[0,cumsum(n_a(1:end-1))];
        end
        a_gridvals(i2,:)=a_grid(sub);
    end
end

%%

%% j=N_j

% Create a vector containing all the return function parameters (in order)
ReturnFnParamsVec=CreateVectorFromParams(Parameters, ReturnFnParamNames,N_j);

if vfoptions.lowmemory==0
    
    %if vfoptions.returnmatrix==2 % GPU
    ReturnMatrix=CreateReturnFnMatrix_Case1_Disc_Par2(ReturnFn, n_d, n_a, n_z, d_grid, a_grid, z_grid, ReturnFnParamsVec);
    %Calc the max and it's index
    [Vtemp,maxindex]=max(ReturnMatrix,[],3);
    V(:,:,N_j)=Vtemp;
    Policy(:,:,N_j)=maxindex;

elseif vfoptions.lowmemory==1
    
    %if vfoptions.returnmatrix==2 % GPU
    for z_c=1:N_z
        z_val=z_gridvals(z_c,:);
        ReturnMatrix_z=CreateReturnFnMatrix_Case1_Disc_Par2(ReturnFn, n_d, n_a, special_n_z, d_grid, a_grid, z_val, ReturnFnParamsVec);
        %Calc the max and it's index
        [Vtemp,maxindex]=max(ReturnMatrix_z,[],1);
        V(:,z_c,N_j)=Vtemp;
        Policy(:,z_c,N_j)=maxindex;
    end
    
elseif vfoptions.lowmemory==2

    %if vfoptions.returnmatrix==2 % GPU
    for z_c=1:N_z
        z_val=z_gridvals(z_c,:);
        for a_c=1:N_a
            a_val=a_gridvals(z_c,:);
            ReturnMatrix_az=CreateReturnFnMatrix_Case1_Disc_Par2(ReturnFn, n_d, special_n_a, special_n_z, d_grid, a_val, z_val, ReturnFnParamsVec);
            %Calc the max and it's index
            [Vtemp,maxindex]=max(ReturnMatrix_az);
            V(a_c,z_c,N_j)=Vtemp;
            Policy(a_c,z_c,N_j)=maxindex;

        end
    end   
    
end

%%

% if Case2_Type==5 % Was a custom version for Imai & Keane (2004)
%     FmatrixKron_j=reshape(FmatrixFn_j(N_j+19),[N_d,N_a,N_z]);
%     for z_c=1:N_z
%         for a_c=1:N_a
%             [V(a_c,z_c,N_j),Policy(a_c,z_c,N_j)]=max(FmatrixKron_j(:,a_c,z_c),[],1);
%         end
%     end    
% else
%     FmatrixKron_j=reshape(FmatrixFn_j(N_j),[N_d,N_a,N_z]);
%     for z_c=1:N_z
%         for a_c=1:N_a
%             [V(a_c,z_c,N_j),Policy(a_c,z_c,N_j)]=max(FmatrixKron_j(:,a_c,z_c),[],1);
%         end
%     end
% end

if Case2_Type==1 % phi_a'(d,a,z,z')
    PhiaprimeParamsVec=CreateVectorFromParams(Parameters, PhiaprimeParamNames);
    Phi_aprimeMatrix=CreatePhiaprimeMatrix_Case2_Disc_Par2(Phi_aprime, Case2_Type, n_d, n_a, n_z, d_grid, a_grid, z_grid,PhiaprimeParamsVec);
    
    for reverse_j=1:N_j-1
        j=N_j-reverse_j;
        
        % Create a vector containing all the return function parameters (in order)
        ReturnFnParamsVec=CreateVectorFromParams(Parameters, ReturnFnParamNames,j);
        DiscountFactorParamsVec=CreateVectorFromParams(Parameters, DiscountFactorParamNames,j);
        
        VKronNext_j=V(:,:,j+1);
    
        if vfoptions.lowmemory==0
            
            %if vfoptions.returnmatrix==2 % GPU
            ReturnMatrix=CreateReturnFnMatrix_Case1_Disc_Par2(ReturnFn, n_d, n_a, n_z, d_grid, a_grid, z_grid, ReturnFnParamsVec);
            %        FmatrixKron_j=reshape(FmatrixFn_j(j),[N_d,N_a,N_z]);
            %        Phi_aprimeKron=Phi_aprimeKronFn_j(j);
            for z_c=1:N_z
                for a_c=1:N_a
                    RHSpart2=zeros(N_d,1);
                    for zprime_c=1:N_z
                        if pi_z(z_c,zprime_c)~=0 %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
                            for d_c=1:N_d
                                RHSpart2(d_c)=RHSpart2(d_c)+VKronNext_j(Phi_aprimeMatrix(d_c,a_c,z_c,zprime_c),zprime_c)*pi_z(z_c,zprime_c);
                            end
                        end
                    end
                    entireRHS=ReturnMatrix(:,a_c,z_c)+beta_j(j)*RHSpart2; %aprime by 1
                    
                    %calculate in order, the maximizing aprime indexes
                    [V(a_c,z_c,j),Policy(a_c,z_c,j)]=max(entireRHS,[],1);
                end
            end
        end
    end
end

if Case2_Type==2  % phi_a'(d,z,z')
    for reverse_j=1:N_j-1
        j=N_j-reverse_j;
        VKronNext_j=V(:,:,j+1);
        FmatrixKron_j=reshape(FmatrixFn_j(j),[N_d,N_a,N_z]);
        Phi_aprimeKron=Phi_aprimeKronFn_j(j);
        for z_c=1:N_z
            RHSpart2=zeros(N_d,1);
            for zprime_c=1:N_z
                if pi_z(z_c,zprime_c)~=0 %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
                    for d_c=1:N_d
                        RHSpart2(d_c)=RHSpart2(d_c)+VKronNext_j(Phi_aprimeKron(d_c,z_c,zprime_c),zprime_c)*pi_z(z_c,zprime_c);
                    end
                end
            end
            for a_c=1:N_a
                entireRHS=FmatrixKron_j(:,a_c,z_c)+beta_j(j)*RHSpart2; %aprime by 1
                
                %calculate in order, the maximizing aprime indexes
                [V(a_c,z_c,j),Policy(a_c,z_c,j)]=max(entireRHS,[],1);
            end
        end
    end
end


if Case2_Type==3  % phi_a'(d,z')
    if vfoptions.phiaprimedependsonage==0
        PhiaprimeParamsVec=CreateVectorFromParams(Parameters, PhiaprimeParamNames);
        Phi_aprimeMatrix=CreatePhiaprimeMatrix_Case2_Disc_Par2(Phi_aprime, Case2_Type, n_d, n_a, n_z, d_grid, a_grid, z_grid,PhiaprimeParamsVec);
        for reverse_j=1:N_j-1
            j=N_j-reverse_j;
            VKronNext_j=V(:,:,j+1);
            FmatrixKron_j=reshape(FmatrixFn_j(j),[N_d,N_a,N_z]);
            Phi_aprimeKron=Phi_aprimeKronFn_j(j);
            for z_c=1:N_z
                RHSpart2=zeros(N_d,1);
                for zprime_c=1:N_z
                    if pi_z(z_c,zprime_c)~=0 %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
                        for d_c=1:N_d
                            RHSpart2(d_c)=RHSpart2(d_c)+VKronNext_j(Phi_aprimeKron(d_c),zprime_c)*pi_z(z_c,zprime_c);
                        end
                    end
                end
                for a_c=1:N_a
                    entireRHS=FmatrixKron_j(:,a_c,z_c)+beta_j(j)*RHSpart2; %aprime by 1
                    
                    %calculate in order, the maximizing aprime indexes
                    [V(a_c,z_c,j),Policy(a_c,z_c,j)]=max(entireRHS,[],1);
                end
            end
        end
    elseif vfoptions.phiaprimedependsonage==1
        for reverse_j=1:N_j-1
            j=N_j-reverse_j;
            
            PhiaprimeParamsVec=CreateVectorFromParams(Parameters, PhiaprimeParamNames,j);
            Phi_aprimeMatrix=CreatePhiaprimeMatrix_Case2_Disc_Par2(Phi_aprime, Case2_Type, n_d, n_a, n_z, d_grid, a_grid, z_grid,PhiaprimeParamsVec);
        
            VKronNext_j=V(:,:,j+1);
            FmatrixKron_j=reshape(FmatrixFn_j(j),[N_d,N_a,N_z]);
            Phi_aprimeKron=Phi_aprimeKronFn_j(j);
            for z_c=1:N_z
                RHSpart2=zeros(N_d,1);
                for zprime_c=1:N_z
                    if pi_z(z_c,zprime_c)~=0 %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
                        for d_c=1:N_d
                            RHSpart2(d_c)=RHSpart2(d_c)+VKronNext_j(Phi_aprimeKron(d_c),zprime_c)*pi_z(z_c,zprime_c);
                        end
                    end
                end
                for a_c=1:N_a
                    entireRHS=FmatrixKron_j(:,a_c,z_c)+beta_j(j)*RHSpart2; %aprime by 1
                    
                    %calculate in order, the maximizing aprime indexes
                    [V(a_c,z_c,j),Policy(a_c,z_c,j)]=max(entireRHS,[],1);
                end
            end
        end
    end
%     for reverse_j=1:N_j-1
%         j=N_j-reverse_j;
%         VKronNext_j=V(:,:,j+1);
%         FmatrixKron_j=reshape(FmatrixFn_j(j),[N_d,N_a,N_z]);
%         Phi_aprimeKron=Phi_aprimeKronFn_j(j);
%         for z_c=1:N_z
%             RHSpart2=zeros(N_d,1);
%             for zprime_c=1:N_z
%                 if pi_z(z_c,zprime_c)~=0 %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
%                     for d_c=1:N_d
%                         RHSpart2(d_c)=RHSpart2(d_c)+VKronNext_j(Phi_aprimeKron(d_c),zprime_c)*pi_z(z_c,zprime_c);
%                     end
%                 end
%             end
%             for a_c=1:N_a
%                 entireRHS=FmatrixKron_j(:,a_c,z_c)+beta_j(j)*RHSpart2; %aprime by 1
%                 
%                 %calculate in order, the maximizing aprime indexes
%                 [V(a_c,z_c,j),Policy(a_c,z_c,j)]=max(entireRHS,[],1);
%             end
%         end
%     end
end

if Case2_Type==4  % phi_a'(d,a)
    PhiaprimeParamsVec=CreateVectorFromParams(Parameters, PhiaprimeParamNames);
    Phi_aprimeMatrix=CreatePhiaprimeMatrix_Case2_Disc_Par2(Phi_aprime, Case2_Type, n_d, n_a, n_z, d_grid, a_grid, z_grid,PhiaprimeParamsVec);
    aaa=kron(pi_z,ones(N_d,1,'gpuArray'));
    
    for reverse_j=1:N_j-1
        j=N_j-reverse_j;
        VKronNext_j=V(:,:,j+1);
        
        ReturnMatrix=CreateReturnFnMatrix_Case2_Disc_Par2(ReturnFn, n_d, n_a, n_z, d_grid, a_grid, z_grid,ReturnFnParamsVec);
        EV=zeros(N_d*N_z,N_z,'gpuArray');
        for zprime_c=1:N_z
            EV(:,zprime_c)=VKronNext_j(Phi_aprimeMatrix(:,zprime_c)*ones(1,N_z),zprime_c); %(d,z')
        end
        EV=EV.*aaa;
        EV(isnan(EV))=0; %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
        EV=reshape(sum(EV,2),[N_d,1,N_z]);
        
        for z_c=1:N_z % Can probably eliminate this loop and replace with a matrix multiplication operation thereby making it faster
            entireRHS=ReturnMatrix(:,:,z_c)+beta*EV(:,z_c)*ones(1,N_a,1,'gpuArray');
            
            %Calc the max and it's index
            [Vtemp,maxindex]=max(entireRHS,[],1);
            V(:,z_c,j)=Vtemp;
            Policy(:,z_c,j)=maxindex;
        end
    end
end

if Case2_Type==5  % phi_a'(d,e')
    % In Case2_Type==5 it is no longer the case that Phi_aprime contains
    % the index of the relevant point. Instead it now contains the
    % probability of each point.

    if vfoptions.phiaprimedependsonage==0
        if vfoptions.phiaprimematrix==1
            Phi_aprimeMatrix_e=Phi_aprime;
        elseif vfoptions.phiaprimematrix==2
            disp('ERROR: COMBINATION OF Case2_Type==5 and vfoptions.phiaprimematrix==2 HAS NOT BEEN IMPLEMENTED')
            PhiaprimeParamsVec=CreateVectorFromParams(Parameters, PhiaprimeParamNames);
            %     Phi_aprimeMatrix=CreatePhiaprimeMatrix_Case2_Disc_Par2(Phi_aprime, Case2_Type, n_d, n_a, n_z,d_grid, a_grid, z_grid,PhiaprimeParamsVec);
            Phi_aprimeMatrix_e=CreatePhiaprimeMatrix_Case2_Disc_Par2_e(Phi_aprime, Case2_Type, n_d, n_a, n_z,d_grid, a_grid,e_grid, z_grid, PhiaprimeParamsVec);
        end
    end
    
    aaa=kron(pi_z,ones(N_d,1,'gpuArray'));

    %prob_e
    for reverse_j=1:N_j-1
        j=N_j-reverse_j;
        VKronNext_j=V(:,:,j+1);
        
        if vfoptions.phiaprimedependsonage==1
            if vfoptions.phiaprimematrix==1
                Phi_aprimeMatrix_e=Phi_aprime(:,:,j);
            elseif vfoptions.phiaprimematrix==2
                disp('ERROR: COMBINATION OF Case2_Type==5 and vfoptions.phiaprimematrix==2 HAS NOT BEEN IMPLEMENTED')
                PhiaprimeParamsVec=[j,CreateVectorFromParams(Parameters, PhiaprimeParamNames)];
                %     Phi_aprimeMatrix=CreatePhiaprimeMatrix_Case2_Disc_Par2(Phi_aprime, Case2_Type, n_d, n_a, n_z,d_grid, a_grid, z_grid,PhiaprimeParamsVec);
                Phi_aprimeMatrix_e=CreatePhiaprimeMatrix_Case2_Disc_Par2_e(Phi_aprime, Case2_Type, n_d, n_a, n_z,d_grid, a_grid, z_grid,e_grid, PhiaprimeParamsVec);
            end
        end
        
        if vfoptions.lowmemory==0
            ReturnMatrix=CreateReturnFnMatrix_Case2_Disc_Par2(ReturnFn, n_d, n_a, n_z, d_grid, a_grid, z_grid,ReturnFnParamsVec);
            EV=zeros(N_d*N_z,N_z,'gpuArray');
            for zprime_c=1:N_z % This can likely be improved
                EV(:,zprime_c)=VKronNext_j(Phi_aprimeMatrix(:)*ones(1,N_z),zprime_c); %(d,z')
            end
            EV=EV.*aaa;
            EV(isnan(EV))=0; %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
            EV=reshape(sum(EV,2),[N_d,1,N_z]);
            
            for z_c=1:N_z % Can probably eliminate this loop and replace with a matrix multiplication operation thereby making it faster
                entireRHS=ReturnMatrix(:,:,z_c)+beta*EV(:,z_c)*ones(1,N_a,1,'gpuArray');
                
                %Calc the max and it's index
                [Vtemp,maxindex]=max(entireRHS,[],1);
                V(:,z_c,j)=Vtemp;
                Policy(:,z_c,j)=maxindex;
            end
        elseif vfoptions.lowmemory==1
            
            EV=zeros(N_d*N_z,N_z,'gpuArray');
            for zprime_c=1:N_z % This can likely be improved
                EV(:,zprime_c)=VKronNext_j(Phi_aprimeMatrix(:)*ones(1,N_z),zprime_c); %(d,z')
            end
            EV=EV.*aaa;
            EV(isnan(EV))=0; %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
            EV=reshape(sum(EV,2),[N_d,1,N_z]);
            
            for z_c=1:N_z % Can probably eliminate this loop and replace with a matrix multiplication operation thereby making it faster
                z_val=z_gridvals(z_c,:);
                ReturnMatrix_z=CreateReturnFnMatrix_Case1_Disc_Par2(ReturnFn, n_d, n_a, special_n_z, d_grid, a_grid, z_val, ReturnFnParamsVec);
                
                entireRHS=ReturnMatrix_z+beta*EV(:,z_c)*ones(1,N_a,1,'gpuArray');
                
                %Calc the max and it's index
                [Vtemp,maxindex]=max(entireRHS,[],1);
                V(:,z_c,j)=Vtemp;
                Policy(:,z_c,j)=maxindex;
            end
        end

    end
end

% if Case2_Type==7 %A Legacy Custom Case2_Type that was written just for Imai & Keane (2004).
%     for reverse_j=1:N_j-1
%         j=N_j-reverse_j;
%         VKronNext_j=V(:,:,j+1);
%         FmatrixKron_j=reshape(FmatrixFn_j(j+19),[N_d,N_a,N_z]);
%         Phi_aprimeKron=Phi_aprimeKronFn_j(j+19); %Size is [n_a(2),n_d(1),n_a(1)], or in notation used in codes for Imai & Keane (2004), [hprime, l,a]. Unlike all other Case2's this one does not give a specific value for hprime.
%                                               %rather it gives a probability distn over future hprimes.
%         for z_c=1:N_z
%             RHSpart2=zeros(N_d,1);
%             for zprime_c=1:N_z
%                 if pi_z(z_c,zprime_c)~=0 %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
%                     for l_c=1:n_d(1) %hours worked, l
%                         for h_c=1:n_a(2) %human capital, h
%                             for hprime_c=1:n_a(2) %hprime
%                                 if Phi_aprimeKron(hprime_c,l_c,h_c)>0 %This will help avoid -Inf*0 problems
%                                     for aprime_c=1:n_a(1)
%                                         ahprime_c=sub2ind_homemade(n_a,[aprime_c,hprime_c]);
%                                         RHSpart2(l_c)=RHSpart2(l_c)+Phi_aprimeKron(hprime_c,l_c,h_c)*VKronNext_j(ahprime_c,zprime_c)*pi_z(z_c,zprime_c);
%                                     end
%                                 end
%                             end
%                         end
%                     end
%                 end
%             end
%             for a_c=1:N_a
%                 entireRHS=FmatrixKron_j(:,a_c,z_c)+beta_j(j+19)*RHSpart2; %aprime by 1
%                 
%                 %calculate in order, the maximizing aprime indexes
%                 [V(a_c,z_c,j),Policy(a_c,z_c,j)]=max(entireRHS,[],1);
%             end
%         end
%     end
% end

end