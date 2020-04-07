function [VKron, Policy]=ValueFnIter_Case1_NoD_raw(VKron, N_a, N_z, pi_z, beta, ReturnMatrix, Howards,Howards2,Tolerance) % Verbose
%Does pretty much exactly the same as ValueFnIter_Case1, only without any
%decision variable (n_d=0)

% N_a=prod(n_a);
% N_z=prod(n_z);
% 
% if Verbose==1
%     disp('Starting Value Fn Iteration')
%     tempcounter=1;
% end

PolicyIndexes=zeros(N_a,N_z);
tempcounter=1;
currdist=Inf;
while currdist>Tolerance

    VKronold=VKron;

    for z_c=1:N_z
        %Calc the condl expectation term (except beta), which depends on z but
        %not on control variables
%         EV_z=zeros(N_a,1); %aprime
%         for zprime_c=1:N_z
%             if pi_z(z_c,zprime_c)~=0 %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
%                 EV_z=EV_z+VKronold(:,zprime_c)*pi_z(z_c,zprime_c);
%             end
%         end
        EV_z=VKronold.*kron(ones(N_a,1),pi_z(z_c,:));
        EV_z(isnan(EV_z))=0; %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
        EV_z=sum(EV_z,2);
        
        for a_c=1:N_a
            entireRHS=ReturnMatrix(:,a_c,z_c)+beta*EV_z; %aprime by 1
            
            %Calc the max and it's index
            [Vtemp,maxindex]=max(entireRHS);
            VKron(a_c,z_c)=Vtemp;
            PolicyIndexes(a_c,z_c)=maxindex;
        end
    end
        
    VKrondist=reshape(VKron-VKronold,[numel(VKron),1]); VKrondist(isnan(VKrondist))=0;
    currdist=max(abs(VKrondist));
    if isfinite(currdist) && tempcounter<Howards2 %Use Howards Policy Fn Iteration Improvement
        Ftemp=zeros(N_a,N_z);
        for z_c=1:N_z
            for a_c=1:N_a
                Ftemp(a_c,z_c)=ReturnMatrix(PolicyIndexes(a_c,z_c),a_c,z_c);%FmatrixKron(PolicyIndexes1(a_c,z_c),PolicyIndexes2(a_c,z_c),a_c,z_c);
            end
        end
        for Howards_counter=1:Howards
            VKrontemp=VKron;
            for z_c=1:N_z
                EVKrontemp_z=VKrontemp(PolicyIndexes(:,z_c),:).*kron(pi_z(z_c,:),ones(N_a,1)); %kron(pi_z(z_c,:),ones(nquad,1))
                EVKrontemp_z(isnan(EVKrontemp_z))=0; %Multiplying zero (transition prob) by -Inf (value fn) gives NaN
                VKron(:,z_c)=Ftemp(:,z_c)+beta*sum(EVKrontemp_z,2);
            end
        end
    end
    
%     if Verbose==1
%         if rem(tempcounter,100)==0
%             disp(tempcounter)
%             disp(currdist)
%         end
%         tempcounter=tempcounter+1;
%     end

    tempcounter=tempcounter+1;

end
  


% if PolIndOrVal==1
Policy=PolicyIndexes;
% elseif PolIndOrVal==2
%     Policy=zeros(N_a,N_z,length(n_a)); %NOTE: this is not actually in Kron form
%     for a_c=1:N_a
%         for z_c=1:N_z
%             temp_a=ind2grid_homemade(n_a,PolicyIndexes2(a_c,z_c),a_grid);
%             for ii=1:length(n_a)
%                 Policy(a_c,z_c,ii)=temp_a(ii);
%             end
%         end
%     end
% end



end