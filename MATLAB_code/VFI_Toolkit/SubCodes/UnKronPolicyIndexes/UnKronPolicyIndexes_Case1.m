function Policy=UnKronPolicyIndexes_Case1(Policy, n_d, n_a, n_z,vfoptions)

%Input: Policy=zeros(2,N_a,N_z); %first dim indexes the optimal choice for d and aprime rest of dimensions a,z 
%                       (N_a,N_z) if there is no d
%Output: Policy (l_d+l_a,n_a,n_z);

N_a=prod(n_a);
N_z=prod(n_z);

l_a=length(n_a);

if n_d(1)==0
    
    if vfoptions.parallel~=2
        PolicyTemp=zeros(l_a,N_a,N_z);
        for i=1:N_a
            for j=1:N_z
                optaindexKron=Policy(i,j);
                optA=ind2sub_homemade([n_a'],optaindexKron);
                PolicyTemp(:,i,j)=[optA'];
            end
        end
        Policy=reshape(PolicyTemp,[l_a,n_a,n_z]);
    else
        PolicyTemp=zeros(l_a,N_a,N_z,'gpuArray');
        
        PolicyTemp(1,:,:)=shiftdim(rem(Policy-1,n_a(1))+1,-1);
        if l_a>1
            if l_a>2
                for ii=2:l_a-1
                    PolicyTemp(ii,:,:)=shiftdim(rem(ceil(Policy/prod(n_a(1:ii-1)))-1,n_a(ii))+1,-1);
                end                
            end
            PolicyTemp(l_a,:,:)=shiftdim(ceil(Policy/prod(n_a(1:l_a-1))),-1);
        end            
        
        Policy=reshape(PolicyTemp,[l_a,n_a,n_z]);
    end
    
else
    l_d=length(n_d);
    
    if vfoptions.parallel~=2
        PolicyTemp=zeros(l_d+l_a,N_a,N_z);
        for i=1:N_a
            for j=1:N_z
                optdindexKron=Policy(1,i,j);
                optaindexKron=Policy(2,i,j);
                optD=ind2sub_homemade(n_d',optdindexKron);
                optA=ind2sub_homemade(n_a',optaindexKron);
                PolicyTemp(:,i,j)=[optD';optA'];
            end
        end
        Policy=reshape(PolicyTemp,[l_d+l_a,n_a,n_z]);
    else
        l_da=length(n_d)+length(n_a);
        n_da=[n_d,n_a];
        PolicyTemp=zeros(l_da,N_a,N_z,'gpuArray');

        PolicyTemp(1,:,:)=rem(Policy(1,:,:)-1,n_da(1))+1;
        if l_d>1
            if l_d>2
                for ii=2:l_d-1
                    PolicyTemp(ii,:,:)=rem(ceil(Policy(1,:,:)/prod(n_d(1:ii-1)))-1,n_d(ii))+1;
                end                
            end
            PolicyTemp(l_d,:,:)=ceil(Policy(1,:,:)/prod(n_d(1:l_d-1)));
        end
        
        PolicyTemp(l_d+1,:,:)=rem(Policy(2,:,:)-1,n_a(1))+1;
        if l_a>1
            if l_a>2
                for ii=2:l_a-1
                    PolicyTemp(l_d+ii,:,:)=rem(ceil(Policy(2,:,:)/prod(n_a(1:ii-1)))-1,n_a(ii))+1;
                end                
            end
            PolicyTemp(l_da,:,:)=ceil(Policy(2,:,:)/prod(n_a(1:l_a-1)));
        end
        
        Policy=reshape(PolicyTemp,[l_da,n_a,n_z]);
    end
    
end

% % Sometimes numerical rounding errors (of the order of 10^(-16) can mean
% % that Policy is not integer valued. The following corrects this by converting to int64 and then
% % makes the output back into double as Matlab otherwise cannot use it in
% % any arithmetical expressions.
% if vfoptions.policy_forceintegertype==1
%     Policy=uint64(Policy);
%     Policy=double(Policy);
% end

end