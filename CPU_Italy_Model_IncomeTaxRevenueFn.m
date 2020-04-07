function [IncomeTaxRevenue]=CPU_Italy_Model_IncomeTaxRevenueFn(d1_val,d2_val,a_val,s_val,J,r,theta,delta,omega,e1,e2,e3,e4,e5,a0,a1,a2,a3)

%d1_values %h (hours worked)
%d2_values %z
%a_values %a (capital)
%s_indexes %age (& determines retirement)

w=(1-theta)*(((r+delta)/(theta))^(theta/(theta-1)));

% Income
% If retired
e=0;
y=a_val*r+e*d1_val*w+omega;
if s_val<=J %If working
    e=e1*(s_val==1)+e2*(s_val==2)+e3*(s_val==3)+e4*(s_val==4)+e5*(s_val==5);
    y=a_val*r+e*d1_val*w;
end

%Income tax revenue
IncomeTaxRevenue=a0*(y-(y^(-a1)+a2)^(-1/a1))+a3*y;

%c=0;
%c=y+a_val-d1_val;

end