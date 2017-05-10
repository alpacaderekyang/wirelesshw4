function [ next_cell, xq , yq] = update_with_coordinates( xv,yv, outer_xv, outer_yv , x_BS, y_BS, outer_x_BS , outer_y_BS , xq , yq , speed_x , speed_y)
outer_map = [17 18 19 8 12 13 16 17 19 1 3 4 7 8 12 1 2 3]; %corresponding 20-37
xq = xq + speed_x*1;
yq = yq + speed_y*1;
for i = 1:19
    in_19_hexagon = inpolygon(xq,yq,xv(:,i), yv(:,i));
    if in_19_hexagon
        next_cell = i;
        return;
    end
end

for i = 1:18
    in_outer_hexagon = inpolygon(xq,yq, outer_xv(:,i), outer_yv(:,i));
    if in_outer_hexagon
        next_cell = outer_map(i);
        rel_x = xq - outer_x_BS(i);%relative x,y
        rel_y = yq - outer_y_BS(i);
        xq = x_BS(next_cell) + rel_x;
        yq = y_BS(next_cell) + rel_y;
        return;
    end
end

error('not in hexagons');