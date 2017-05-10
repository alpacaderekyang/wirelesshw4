function [ xv, yv, xq , yq ] = get_cell( x_BS , y_BS , number_of_ms)

%rng default %if want to fix random seed, don't comment it.
xq = unifrnd(-250, 250, 1, number_of_ms*10);
yq = unifrnd(-250, 250, 1, number_of_ms*10);
xq = xq+x_BS;
yq = yq+y_BS;


L = linspace(0,2.*pi,7);
xv = 250/sqrt(3)*2*cos(L)';
yv = 250/sqrt(3)*2*sin(L)';

xv = xv+x_BS;
yv = yv+y_BS;

in_hexagonal = inpolygon(xq,yq,xv,yv);


xq = xq(in_hexagonal);
yq = yq(in_hexagonal);


index = randperm(number_of_ms);
xq = xq(index);
yq = yq(index);



end

