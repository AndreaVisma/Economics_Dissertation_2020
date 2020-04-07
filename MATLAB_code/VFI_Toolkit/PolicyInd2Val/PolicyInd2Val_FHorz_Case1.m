function PolicyValues=PolicyInd2Val_FHorz_Case1(PolicyIndexes,n_d,n_a,n_z,N_j,d_grid,a_grid, Parallel)

if n_d(1)==0
    l_d=0;
else
    l_d=length(n_d);
end
l_a=length(n_a);

N_a=prod(n_a);
N_z=prod(n_z);

if Parallel==2
    if l_d==0
        PolicyIndexes=reshape(PolicyIndexes,[l_a,N_a*N_z*N_j]);
        PolicyValues=zeros(l_a,N_a*N_z*N_j,'gpuArray');

        temp_a_grid=a_grid(1:n_a(1));
        PolicyValues(1,:)=temp_a_grid(PolicyIndexes(1,:));
        if l_a>1
            if l_a>2
                for ii=2:l_a
                    temp_a_grid=a_grid(1+n_a(ii-1):n_a(ii));
                    PolicyValues(ii,:)=temp_a_grid(PolicyIndexes(ii,:));
                end
            end
            temp_a_grid=a_grid(n_a(end-1)+1:end);
            PolicyValues(end,:)=temp_a_grid(PolicyIndexes(end,:));
        end
        PolicyValues=reshape(PolicyValues,[l_a,n_a,n_z,N_j]);
    else
        PolicyIndexes=reshape(PolicyIndexes,[l_d+l_a,N_a*N_z*N_j]);
        PolicyValues=zeros(l_d+l_a,N_a*N_z*N_j,'gpuArray');

        temp_d_grid=d_grid(1:n_d(1));
        PolicyValues(1,:)=temp_d_grid(PolicyIndexes(1,:));
        if l_d>1
            if l_d>2
                for ii=2:l_d
                    temp_d_grid=d_grid(1+n_d(ii-1):n_d(ii));
                    PolicyValues(ii,:)=temp_d_grid(PolicyIndexes(ii,:));
                end
            end
            temp_d_grid=d_grid(n_d(end-1)+1:end);
            PolicyValues(end,:)=temp_d_grid(PolicyIndexes(end,:));
        end
        
        temp_a_grid=a_grid(1:n_a(1));
        PolicyValues(l_d+1,:)=temp_a_grid(PolicyIndexes(l_d+1,:));
        if l_a>1
            if l_a>2
                for ii=2:l_a
                    temp_a_grid=a_grid(1+n_a(ii-1):n_a(ii));
                    PolicyValues(l_d+ii,:)=temp_a_grid(PolicyIndexes(l_d+ii,:));
                end
            end
            temp_a_grid=a_grid(n_a(end-1)+1:end);
            PolicyValues(l_d+end,:)=temp_a_grid(PolicyIndexes(l_d+end,:));
        end
        
        PolicyValues=reshape(PolicyValues,[l_d+l_a,n_a,n_z,N_j]);
    end
end

if Parallel~=2
    if n_d(1)==0
        PolicyValues=zeros(length(n_a),N_a,N_z,N_j); %NOTE: this is not actually in Kron form
        for jj=1:N_j
            for a_c=1:N_a
                for z_c=1:N_z
                    temp_a=ind2grid_homemade(PolicyIndexes(a_c,z_c,jj),n_a,a_grid);
                    for ii=1:length(n_a)
                        PolicyValues(ii,a_c,z_c,jj)=temp_a(ii);
                    end
                end
            end
        end
    else
        PolicyValues=zeros(length(n_d)+length(n_a),N_a,N_z,N_j);
        for jj=1:N_j
            for a_c=1:N_a
                for z_c=1:N_z
                    temp_d=ind2grid_homemade(n_d,PolicyIndexes(1,a_c,z_c,jj),d_grid);
                    for ii=1:length(n_d)
                        PolicyValues(ii,a_c,z_c,jj)=temp_d(ii);
                    end
                    temp_a=ind2grid_homemade(n_a,PolicyIndexes(2,a_c,z_c,jj),a_grid);
                    for ii=1:length(n_a)
                        PolicyValues(length(n_d)+ii,a_c,z_c,jj)=temp_a(ii);
                    end
                end
            end
        end
    end
end


end