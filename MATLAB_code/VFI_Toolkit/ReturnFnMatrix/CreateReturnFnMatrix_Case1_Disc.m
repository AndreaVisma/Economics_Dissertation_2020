function Fmatrix=CreateReturnFnMatrix_Case1_Disc(ReturnFn, n_d, n_a, n_z, d_grid, a_grid, z_grid,Parallel,ReturnFnParamsVec)
%If there is no d variable, just input n_d=0 and d_grid=0

ParamCell=cell(length(ReturnFnParamsVec),1);
for ii=1:length(ReturnFnParamsVec)
    ParamCell(ii,1)={ReturnFnParamsVec(ii)};
end


N_d=prod(n_d);
N_a=prod(n_a);
N_z=prod(n_z);

l_a=length(n_a);
l_z=length(n_z);

a_gridvals=CreateGridvals(n_a,a_grid,1);
z_gridvals=CreateGridvals(n_z,z_grid,1);
if N_d~=0
    d_gridvals=CreateGridvals(n_d,d_grid,1);
end

if Parallel==0
        
    if N_d==0
        Fmatrix=zeros(N_a,N_a,N_z);
        for i1=1:N_a
            for i2=1:N_a
                for i3=1:N_z
                    tempcell=num2cell([a_gridvals(i1,:),a_gridvals(i2,:),z_gridvals(i3,:)]);
                    Fmatrix(i1,i2,i3)=ReturnFn(tempcell{:},ParamCell{:});
%                     Fmatrix(i1,i2,i3)=ReturnFn(a_gridvals(i1,:),a_gridvals(i2,:),z_gridvals(i3,:),ParamCell{:});
                end
            end
        end
            
    else
        Fmatrix=zeros(N_d*N_a,N_a,N_z);
                   
        for i1=1:N_d
            for i2=1:N_a
                i1i2=i1+(i2-1)*N_d;
                for i3=1:N_a
                    for i4=1:N_z
                        tempcell=num2cell([d_gridvals(i1,:),a_gridvals(i2,:),a_gridvals(i3,:),z_gridvals(i4,:)]);
                        Fmatrix(i1i2,i3,i4)=ReturnFn(tempcell{:},ParamCell{:});
%                         Fmatrix(i1i2,i3,i4)=ReturnFn(d_gridvals(i1,:),a_gridvals(i2,:),a_gridvals(i3,:),z_gridvals(i4,:),ParamCell{:});
                    end
                end
            end
        end
    end
    
elseif Parallel==1
    
    if N_d==0
        Fmatrix=zeros(N_a,N_a,N_z);
        parfor i3=1:N_z
            z_gridvals_c=z_gridvals(i3,:);
            
            Fmatrix_z=zeros(N_a,N_a);
            for i1=1:N_a
                for i2=1:N_a
                    tempcell=num2cell([a_gridvals(i1,:),a_gridvals(i2,:),z_gridvals_c]);
                    Fmatrix_z(i1,i2)=ReturnFn(tempcell{:},ParamCell{:});
                end
            end
            Fmatrix(:,:,i3)=Fmatrix_z;
        end
    else        
        Fmatrix=zeros(N_d*N_a,N_a,N_z);
        parfor i4=1:N_z
            z_gridvals_c=z_gridvals(i4,:);
            
            Fmatrix_z=zeros(N_d*N_a,N_a);
            for i1=1:N_d
                for i2=1:N_a
                    for i3=1:N_a
                        tempcell=num2cell([d_gridvals(i1,:),a_gridvals(i2,:),a_gridvals(i3,:),z_gridvals_c]);
                        Fmatrix_z(i1+(i2-1)*N_d,i3)=ReturnFn(tempcell{:},ParamCell{:});
%                         Fmatrix_z(i1+(i2-1)*N_d,i3)=ReturnFn(d_gridvals(i1,:),a_gridvals(i2,:),a_gridvals(i3,:),z_gridvals,ParamCell{:});
                    end
                end
            end
            Fmatrix(:,:,i4)=Fmatrix_z;
        end
    end
end


end


