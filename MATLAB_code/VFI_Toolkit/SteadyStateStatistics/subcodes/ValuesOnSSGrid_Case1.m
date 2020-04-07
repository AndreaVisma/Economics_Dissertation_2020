function Values=ValuesOnSSGrid_Case1(FnToValueOnGrid,FnToValueParams,PolicyValuesPermute,n_d,n_a,n_z,a_grid,z_grid,Parallel)

if Parallel~=2
    disp('ValuesOnSSGrid_Case1() only works for Parallel==2')
end

if n_d(1)==0
    l_d=0;
else
    l_d=length(n_d);
end
l_a=length(n_a);
l_z=length(n_z);
N_a=prod(n_a);
N_z=prod(n_z);

ParamCell=cell(length(FnToValueParams),1);
for ii=1:length(FnToValueParams)
    ParamCell(ii,1)={FnToValueParams(ii)};
end

% if l_d>4
%     disp('ERROR: Using GPU for the return fn does not allow for more than four of d variable (you have length(n_d)>4): (in ValuesOnSSGrid_Case1)')
% end
% if l_a>4
%     disp('ERROR: Using GPU for the return fn does not allow for more than four of a variable (you have length(n_a)>4): (in ValuesOnSSGrid_Case1)')
% end
% if l_z>4
%     disp('ERROR: Using GPU for the return fn does not allow for more than four of z variable (you have length(n_z)>4): (in ValuesOnSSGrid_Case1)')
% end

if l_a>=1
    a1vals=a_grid(1:n_a(1));
    if l_a>=2
        a2vals=shiftdim(a_grid(n_a(1)+1:sum(n_a(1:2))),-1);
        if l_a>=3
            a3vals=shiftdim(a_grid(sum(n_a(1:2))+1:sum(n_a(1:3))),-2);
            if l_a>=4
                a4vals=shiftdim(a_grid(sum(n_a(1:3))+1:sum(n_a(1:4))),-3);
            end
        end
    end
end
if l_z>=1
    z1vals=shiftdim(z_grid(1:n_z(1)),-l_a);
    if l_z>=2
        z2vals=shiftdim(z_grid(n_z(1)+1:sum(n_z(1:2))),-l_a-1);
        if l_z>=3
            z3vals=shiftdim(z_grid(sum(n_z(1:2))+1:sum(n_z(1:3))),-l_a-2);
            if l_z>=4
                z4vals=shiftdim(z_grid(sum(n_z(1:3))+1:sum(n_z(1:4))),-l_a-3);
            end
        end
    end
end

if l_a+l_z==2
    if l_d>=1
        d1vals=PolicyValuesPermute(:,:,1);
        if l_d>=2
            d2vals=PolicyValuesPermute(:,:,2);
            if l_d>=3
                d3vals=PolicyValuesPermute(:,:,3);
                if l_d>=4
                    d4vals=PolicyValuesPermute(:,:,4);
                end
            end
        end
    end
    if l_a>=1
        a1primevals=PolicyValuesPermute(:,:,l_d+1);
        if l_a>=2
            a2primevals=PolicyValuesPermute(:,:,l_d+2);
            if l_a>=3
                a3primevals=PolicyValuesPermute(:,:,l_d+3);
                if l_a>=4
                    a4primevals=PolicyValuesPermute(:,:,l_d+4);
                end
            end
        end
    end
end
if l_a+l_z==3
    if l_d>=1
        d1vals=PolicyValuesPermute(:,:,:,1);
        if l_d>=2
            d2vals=PolicyValuesPermute(:,:,:,2);
            if l_d>=3
                d3vals=PolicyValuesPermute(:,:,:,3);
                if l_d>=4
                    d4vals=PolicyValuesPermute(:,:,:,4);
                end
            end
        end
    end
    if l_a>=1
        a1primevals=PolicyValuesPermute(:,:,:,l_d+1);
        if l_a>=2
            a2primevals=PolicyValuesPermute(:,:,:,l_d+2);
            if l_a>=3
                a3primevals=PolicyValuesPermute(:,:,:,l_d+3);
                if l_a>=4
                    a4primevals=PolicyValuesPermute(:,:,:,l_d+4);
                end
            end
        end
    end
end
if l_a+l_z==4
    if l_d>=1
        d1vals=PolicyValuesPermute(:,:,:,:,1);
        if l_d>=2
            d2vals=PolicyValuesPermute(:,:,:,:,2);
            if l_d>=3
                d3vals=PolicyValuesPermute(:,:,:,:,3);
                if l_d>=4
                    d4vals=PolicyValuesPermute(:,:,:,:,4);
                end
            end
        end
    end
    if l_a>=1
        a1primevals=PolicyValuesPermute(:,:,:,:,l_d+1);
        if l_a>=2
            a2primevals=PolicyValuesPermute(:,:,:,:,l_d+2);
            if l_a>=3
                a3primevals=PolicyValuesPermute(:,:,:,:,l_d+3);
                if l_a>=4
                    a4primevals=PolicyValuesPermute(:,:,:,:,l_d+4);
                end
            end
        end
    end
end
if l_a+l_z==5
    if l_d>=1
        d1vals=PolicyValuesPermute(:,:,:,:,:,1);
        if l_d>=2
            d2vals=PolicyValuesPermute(:,:,:,:,:,2);
            if l_d>=3
                d3vals=PolicyValuesPermute(:,:,:,:,:,3);
                if l_d>=4
                    d4vals=PolicyValuesPermute(:,:,:,:,:,4);
                end
            end
        end
    end
    if l_a>=1
        a1primevals=PolicyValuesPermute(:,:,:,:,:,l_d+1);
        if l_a>=2
            a2primevals=PolicyValuesPermute(:,:,:,:,:,l_d+2);
            if l_a>=3
                a3primevals=PolicyValuesPermute(:,:,:,:,:,l_d+3);
                if l_a>=4
                    a4primevals=PolicyValuesPermute(:,:,:,:,:,l_d+4);
                end
            end
        end
    end
end
if l_a+l_z==6
    if l_d>=1
        d1vals=PolicyValuesPermute(:,:,:,:,:,:,1);
        if l_d>=2
            d2vals=PolicyValuesPermute(:,:,:,:,:,:,2);
            if l_d>=3
                d3vals=PolicyValuesPermute(:,:,:,:,:,:,3);
                if l_d>=4
                    d4vals=PolicyValuesPermute(:,:,:,:,:,:,4);
                end
            end
        end
    end
    if l_a>=1
        a1primevals=PolicyValuesPermute(:,:,:,:,:,:,l_d+1);
        if l_a>=2
            a2primevals=PolicyValuesPermute(:,:,:,:,:,:,l_d+2);
            if l_a>=3
                a3primevals=PolicyValuesPermute(:,:,:,:,:,:,l_d+3);
                if l_a>=4
                    a4primevals=PolicyValuesPermute(:,:,:,:,:,:,l_d+4);
                end
            end
        end
    end
end
if l_a+l_z==7
    if l_d>=1
        d1vals=PolicyValuesPermute(:,:,:,:,:,:,:,1);
        if l_d>=2
            d2vals=PolicyValuesPermute(:,:,:,:,:,:,:,2);
            if l_d>=3
                d3vals=PolicyValuesPermute(:,:,:,:,:,:,:,3);
                if l_d>=4
                    d4vals=PolicyValuesPermute(:,:,:,:,:,:,:,4);
                end
            end
        end
    end
    if l_a>=1
        a1primevals=PolicyValuesPermute(:,:,:,:,:,:,:,l_d+1);
        if l_a>=2
            a2primevals=PolicyValuesPermute(:,:,:,:,:,:,:,l_d+2);
            if l_a>=3
                a3primevals=PolicyValuesPermute(:,:,:,:,:,:,:,l_d+3);
                if l_a>=4
                    a4primevals=PolicyValuesPermute(:,:,:,:,:,:,:,l_d+4);
                end
            end
        end
    end
end
if l_a+l_z==8
    if l_d>=1
        d1vals=PolicyValuesPermute(:,:,:,:,:,:,:,:,1);
        if l_d>=2
            d2vals=PolicyValuesPermute(:,:,:,:,:,:,:,:,2);
            if l_d>=3
                d3vals=PolicyValuesPermute(:,:,:,:,:,:,:,:,3);
                if l_d>=4
                    d4vals=PolicyValuesPermute(:,:,:,:,:,:,:,:,4);
                end
            end
        end
    end
    if l_a>=1
        a1primevals=PolicyValuesPermute(:,:,:,:,:,:,:,:,l_d+1);
        if l_a>=2
            a2primevals=PolicyValuesPermute(:,:,:,:,:,:,:,:,l_d+2);
            if l_a>=3
                a3primevals=PolicyValuesPermute(:,:,:,:,:,:,:,:,l_d+3);
                if l_a>=4
                    a4primevals=PolicyValuesPermute(:,:,:,:,:,:,:,:,l_d+4);
                end
            end
        end
    end
end


if l_d==0 && l_a==1 && l_z==1
    Values=arrayfun(FnToValueOnGrid, a1primevals, a1vals, z1vals, ParamCell{:});
elseif l_d==0 && l_a==1 && l_z==2
    Values=arrayfun(FnToValueOnGrid, a1primevals, a1vals, z1vals,z2vals, ParamCell{:});    
elseif l_d==0 && l_a==1 && l_z==3
    Values=arrayfun(FnToValueOnGrid, a1primevals, a1vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==0 && l_a==1 && l_z==4
    Values=arrayfun(FnToValueOnGrid, a1primevals, a1vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==0 && l_a==2 && l_z==1
    Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals, a1vals,a2vals, z1vals, ParamCell{:});
elseif l_d==0 && l_a==2 && l_z==2
    Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals, ParamCell{:});
elseif l_d==0 && l_a==2 && l_z==3
    Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==0 && l_a==2 && l_z==4
    Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});  
elseif l_d==0 && l_a==3 && l_z==1
    Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals, ParamCell{:});
elseif l_d==0 && l_a==3 && l_z==2
    Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals, ParamCell{:});
elseif l_d==0 && l_a==3 && l_z==3
    Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==0 && l_a==3 && l_z==4
    Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==0 && l_a==4 && l_z==1
    Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals, ParamCell{:});
elseif l_d==0 && l_a==4 && l_z==2
    Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals, ParamCell{:});
elseif l_d==0 && l_a==4 && l_z==3
    Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==0 && l_a==4 && l_z==4
    Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==1 && l_a==1 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals, a1vals, z1vals, ParamCell{:});
elseif l_d==1 && l_a==1 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals, a1vals, z1vals,z2vals, ParamCell{:});
elseif l_d==1 && l_a==1 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals, a1vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==1 && l_a==1 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals, a1vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==1 && l_a==2 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals,a2primevals, a1vals,a2vals, z1vals, ParamCell{:});
elseif l_d==1 && l_a==2 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals, ParamCell{:});
elseif l_d==1 && l_a==2 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==1 && l_a==2 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==1 && l_a==3 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals, ParamCell{:});
elseif l_d==1 && l_a==3 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals, ParamCell{:});
elseif l_d==1 && l_a==3 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==1 && l_a==3 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==1 && l_a==4 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals, ParamCell{:});
elseif l_d==1 && l_a==4 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals, ParamCell{:});
elseif l_d==1 && l_a==4 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==1 && l_a==4 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==2 && l_a==1 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals, a1vals, z1vals, ParamCell{:});
elseif l_d==2 && l_a==1 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals, a1vals, z1vals,z2vals, ParamCell{:});
elseif l_d==2 && l_a==1 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals, a1vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==2 && l_a==1 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals, a1vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==2 && l_a==2 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals,a2primevals, a1vals,a2vals, z1vals, ParamCell{:});
elseif l_d==2 && l_a==2 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals, ParamCell{:});
elseif l_d==2 && l_a==2 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==2 && l_a==2 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==2 && l_a==3 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals, ParamCell{:});
elseif l_d==2 && l_a==3 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals, ParamCell{:});
elseif l_d==2 && l_a==3 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==2 && l_a==3 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==2 && l_a==4 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals, ParamCell{:});
elseif l_d==2 && l_a==4 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals, ParamCell{:});
elseif l_d==2 && l_a==4 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==2 && l_a==4 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==3 && l_a==2 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals, a1primevals,a2primevals, a1vals,a2vals, z1vals, ParamCell{:});
elseif l_d==3 && l_a==2 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals, ParamCell{:});
elseif l_d==3 && l_a==2 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==3 && l_a==2 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==3 && l_a==3 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals, ParamCell{:});
elseif l_d==3 && l_a==3 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals, ParamCell{:});
elseif l_d==3 && l_a==3 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==3 && l_a==3 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==3 && l_a==4 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals, ParamCell{:});
elseif l_d==3 && l_a==4 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals, ParamCell{:});
elseif l_d==3 && l_a==4 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==3 && l_a==4 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==4 && l_a==2 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals,d4vals, a1primevals,a2primevals, a1vals,a2vals, z1vals, ParamCell{:});
elseif l_d==4 && l_a==2 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals,d4vals, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals, ParamCell{:});
elseif l_d==4 && l_a==2 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals,d4vals, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==4 && l_a==2 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals,d4vals, a1primevals,a2primevals, a1vals,a2vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==4 && l_a==3 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals,d4vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals, ParamCell{:});
elseif l_d==4 && l_a==3 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals,d4vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals, ParamCell{:});
elseif l_d==4 && l_a==3 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals,d4vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==4 && l_a==3 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals,d4vals, a1primevals,a2primevals,a3primevals, a1vals,a2vals,a3vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
elseif l_d==4 && l_a==4 && l_z==1
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals,d4vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals, ParamCell{:});
elseif l_d==4 && l_a==4 && l_z==2
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals,d4vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals, ParamCell{:});
elseif l_d==4 && l_a==4 && l_z==3
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals,d4vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals,z3vals, ParamCell{:});
elseif l_d==4 && l_a==4 && l_z==4
    Values=arrayfun(FnToValueOnGrid, d1vals,d2vals,d3vals,d4vals, a1primevals,a2primevals,a3primevals,a4primevals, a1vals,a2vals,a3vals,a4vals, z1vals,z2vals,z3vals,z4vals, ParamCell{:});
end

% if l_d==0 && l_a==1 && l_z==1
%     aprimevals=PolicyValuesPermute(:,:,1);
%     avals=a_grid;
%     zvals=shiftdim(z_grid,-1);
%     Values=arrayfun(FnToValueOnGrid, aprimevals, avals, zvals, ParamCell{:});
% elseif l_d==0 && l_a==1 && l_z==2
%     aprimevals=PolicyValuesPermute(:,:,:,1);
%     avals=a_grid;
%     z1vals=shiftdim(z_grid(1:n_z(1)),-1);
%     z2vals=shiftdim(z_grid(n_z(1)+1:n_z(1)+n_z(2)),-2);
%     Values=arrayfun(FnToValueOnGrid, aprimevals, avals, z1vals,z2vals, ParamCell{:});
% elseif l_d==0 && l_a==2 && l_z==1
%     a1primevals=PolicyValuesPermute(:,:,:,1);
%     a2primevals=PolicyValuesPermute(:,:,:,2);
%     a1vals=a_grid(1:n_a(1));
%     a2vals=shiftdim(a_grid(n_a(1)+1:n_a(1)+n_a(2)),-1);
%     zvals=shiftdim(z_grid,-2);
%     Values=arrayfun(FnToValueOnGrid, a1primevals,a2primevals, a1vals,a2vals, zvals, ParamCell{:});
% elseif l_d==0 && l_a==2 && l_z==2
%     a1primevals=PolicyValuesPermute(:,:,:,:,1);
%     a2primevals=PolicyValuesPermute(:,:,:,:,2);
%     a1vals=a_grid(1:n_a(1));
%     a2vals=shiftdim(a_grid(n_a(1)+1:n_a(1)+n_a(2)),-1);
%     z1vals=shiftdim(z_grid(1:n_z(1)),-2);
%     z2vals=shiftdim(z_grid(n_z(1)+1:n_z(1)+n_z(2)),-3);
%     Values=arrayfun(FnToValueOnGrid, a1primevals, a2primevals, a1vals,a2vals, z1vals,z2vals, ParamCell{:});
% elseif l_d==1 && l_a==1 && l_z==1
%     dvals=PolicyValuesPermute(:,:,1);
%     aprimevals=PolicyValuesPermute(:,:,2);
%     avals=a_grid;
%     zvals=shiftdim(z_grid,-1);
%     Values=arrayfun(FnToValueOnGrid, dvals, aprimevals, avals, zvals, ParamCell{:});
% elseif l_d==1 && l_a==1 && l_z==2
%     dvals=PolicyValuesPermute(:,:,:,1);
%     aprimevals=PolicyValuesPermute(:,:,:,2);
%     avals=a_grid;
%     z1vals=shiftdim(z_grid(1:n_z(1)),-1);
%     z2vals=shiftdim(z_grid(n_z(1)+1:n_z(1)+n_z(2)),-2);
%     Values=arrayfun(FnToValueOnGrid, dvals, aprimevals, avals, z1vals,z2vals, ParamCell{:});
% elseif l_d==1 && l_a==2 && l_z==1
%     dvals=PolicyValuesPermute(:,:,:,1);
%     a1primevals=PolicyValuesPermute(:,:,:,2);
%     a2primevals=PolicyValuesPermute(:,:,:,3);
%     a1vals=a_grid(1:n_a(1));
%     a2vals=shiftdim(a_grid(n_a(1)+1:n_a(1)+n_a(2)),-1);
%     zvals=shiftdim(z_grid,-2);
%     Values=arrayfun(FnToValueOnGrid, dvals, a1primevals,a2primevals, a1vals,a2vals, zvals, ParamCell{:});
% elseif l_d==1 && l_a==2 && l_z==2
%     dvals=PolicyValuesPermute(:,:,:,:,1);
%     a1primevals=PolicyValuesPermute(:,:,:,:,2);
%     a2primevals=PolicyValuesPermute(:,:,:,:,3);
%     a1vals=a_grid(1:n_a(1));
%     a2vals=shiftdim(a_grid(n_a(1)+1:n_a(1)+n_a(2)),-1);
%     z1vals=shiftdim(z_grid(1:n_z(1)),-2);
%     z2vals=shiftdim(z_grid(n_z(1)+1:n_z(1)+n_z(2)),-3);
%     Values=arrayfun(FnToValueOnGrid, dvals, a1primevals, a2primevals, a1vals,a2vals, z1vals,z2vals, ParamCell{:});
% elseif l_d==2 && l_a==1 && l_z==1
%     d1vals=PolicyValuesPermute(:,:,1);
%     d2vals=PolicyValuesPermute(:,:,2);
%     aprimevals=PolicyValuesPermute(:,:,3);
%     avals=a_grid;
%     zvals=shiftdim(z_grid,-1);
%     Values=arrayfun(FnToValueOnGrid, d1vals, d2vals, aprimevals, avals, zvals, ParamCell{:});
% elseif l_d==2 && l_a==1 && l_z==2
%     d1vals=PolicyValuesPermute(:,:,:,1);
%     d2vals=PolicyValuesPermute(:,:,:,2);
%     aprimevals=PolicyValuesPermute(:,:,:,3);
%     avals=a_grid;
%     z1vals=shiftdim(z_grid(1:n_z(1)),-1);
%     z2vals=shiftdim(z_grid(n_z(1)+1:n_z(1)+n_z(2)),-2);
%     Values=arrayfun(FnToValueOnGrid, d1vals, d2vals, aprimevals, avals, z1vals,z2vals, ParamCell{:});
% elseif l_d==2 && l_a==2 && l_z==1
%     d1vals=PolicyValuesPermute(:,:,:,1);
%     d2vals=PolicyValuesPermute(:,:,:,2);
%     a1primevals=PolicyValuesPermute(:,:,:,3);
%     a2primevals=PolicyValuesPermute(:,:,:,4);
%     a1vals=a_grid(1:n_a(1));
%     a2vals=shiftdim(a_grid(n_a(1)+1:n_a(1)+n_a(2)),-1);
%     zvals=shiftdim(z_grid,-2);
%     Values=arrayfun(FnToValueOnGrid, d1vals, d2vals, a1primevals,a2primevals, a1vals,a2vals, zvals, ParamCell{:});
% elseif l_d==2 && l_a==2 && l_z==2
%     d1vals=PolicyValuesPermute(:,:,:,:,1);
%     d2vals=PolicyValuesPermute(:,:,:,:,2);
%     a1primevals=PolicyValuesPermute(:,:,:,:,3);
%     a2primevals=PolicyValuesPermute(:,:,:,:,4);
%     a1vals=a_grid(1:n_a(1));
%     a2vals=shiftdim(a_grid(n_a(1)+1:n_a(1)+n_a(2)),-1);
%     z1vals=shiftdim(z_grid(1:n_z(1)),-2);
%     z2vals=shiftdim(z_grid(n_z(1)+1:n_z(1)+n_z(2)),-3);
%     Values=arrayfun(FnToValueOnGrid, d1vals, d2vals, a1primevals, a2primevals, a1vals,a2vals, z1vals,z2vals, ParamCell{:});
% end

Values=reshape(Values,[N_a,N_z]);


end