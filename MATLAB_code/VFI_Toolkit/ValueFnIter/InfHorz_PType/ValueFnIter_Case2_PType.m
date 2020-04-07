function [V, PolicyIndexes]=ValueFnIter_Case2_PType(Tolerance, V0, n_d, n_a, n_z,n_i, pi_z, Phi_aprimeKron, Case2_Type, beta, FmatrixFn_i, Howards)

N_z=prod(n_z);
N_a=prod(n_a);
N_d=prod(n_d);
N_i=prod(n_i);

V0Kron=reshape(V0,[N_a,N_z,N_i);
[VKron, PolicyIndexesKron]=ValueFnIter_Case2_PType_raw(Tolerance, V0Kron, N_d, N_a, N_z,N_i, pi_z, Phi_aprimeKron, Case2_Type, beta, FmatrixFn_i, Howards);

%Transform V & PolicyIndexes out of kroneckered form
V=reshape(VKron,[n_a,n_z,n_i]);
PolicyIndexes=UnKronPolicyIndexes_Case2_PType(PolicyIndexesKron, n_d, n_a, n_z,n_i);

end