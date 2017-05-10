temperature = 300; % 27,300k 
bw = 10*10^6; % 10M
%I = 0;
N = myNoise(300,bw);
GT_db = 14;
GR_db = 14;
BSpower_db = 33-30; % 33dBm
MSpower_db = 23-30; % 23dBm

GT = db_to_linear(GT_db);
GR = db_to_linear(GR_db);
BSpower = db_to_linear(BSpower_db);
MSpower = db_to_linear(MSpower_db);

BSheight = 51.5; %1.5+ 50
MSheight = 1.5;

n = 100;%number of ms

minSpeed = 1;
maxSpeed = 15;
minT = 1;
maxT = 6;

testTime = 900;
%location of 19 BS (modified from hw2)
x_BS = sqrt(3)*[-500, -500, -500, -250, -250, -250, -250,    0,   0,  0,    0,     0, 250,  250,  250,  250, 500, 500,  500];
y_BS =         [500 ,    0, -500,  750,  250, -250, -750, 1000, 500,  0, -500, -1000, 750 , 250, -250, -750, 500,   0, -500];

outer_x_BS = sqrt(3)*[-750, -750 , -750, -750, -500,  -500, -250 , -250,    0,    0,  250,  250,  500,  500, 750, 750, 750, 750];
outer_y_BS =         [ 750,  250 , -250, -750, 1000, -1000, 1250 ,-1250, 1500,-1500, 1250,-1250, 1000,-1000, 750, 250,-250,-750];

xv = zeros(7,19);
yv = zeros(7,19); %vertice of hexagon

outer_xv = zeros(7,18);
outer_yv = zeros(7,18);

%center cell
figure
hold on
[~ , ~ , xq , yq] = get_cell( 0 , 0 , n);


for i = 1:19
    %use get_cell to get every ms in a cell
    [xv(:,i),yv(:,i), ~ , ~] = get_cell( x_BS(i) , y_BS(i) , n);
    
    plot( xv(:,i), yv(:,i))
    axis equal
    plot(x_BS(i),y_BS(i),'k*')  
end

for i = 1:19
    %label each cell with id
    mytext = text(x_BS(i)+15,y_BS(i)+15,int2str(i));
    mytext.FontSize = 12;
end
title('figure B-1') 
xlabel('x(m)')
ylabel('y(m)')
hold off

%-----------------------end of b-1
figure
hold on
for i = 1:19    
    plot( xv(:,i), yv(:,i))
    axis equal
    plot(x_BS(i),y_BS(i),'k*')  
end

for i = 1:18
    [outer_xv(:,i),outer_yv(:,i), ~ , ~] = get_cell( outer_x_BS(i) , outer_y_BS(i) , n);
%     plot( outer_xv(:,i), outer_yv(:,i))
%     axis equal
%     plot(outer_x_BS(i),outer_y_BS(i),'k*')  
end

%randomly shift the 100 ms from center cell to each cell
rnd_cell = ceil( unifrnd(0,19,[1,n]));
connected_bs = rnd_cell;

for i = 1:n
    xq(i) = xq(i) + x_BS(rnd_cell(i));
    yq(i) = yq(i) + y_BS(rnd_cell(i));
    plot(xq(i),yq(i),'ro')
end
title('figure B-2') 
xlabel('x(m)')
ylabel('y(m)')
hold off
%------------------------------end of b-2



moving_time = ceil( unifrnd( minT-1 , maxT ,[1,n])); %integer
mydir = unifrnd(0, 2*pi, [1,n]); %my direction
speed = unifrnd(minSpeed,maxSpeed , [1,n]); %double
speed_x = zeros(1,n);
speed_y = zeros(1,n);

next_connected_bs = zeros(1,n);
record = [0 0 0];


d_to_BS = zeros(n,19); %distance: n points to 19 bs

for  k = 1:n
    for i = 1:19
        d_to_BS(k,i) = sqrt( (xq(k) - x_BS(i) )^2 + ( yq(k) - y_BS(i) )^2 );
    end
end

BS_RCpower = g_of_d(BSheight, MSheight , d_to_BS).*GT.*GR.*MSpower;
BS_RCpower_db = linear_to_db(BS_RCpower);
total_power = sum(BS_RCpower,1);

% figure,plot(d_to_BS , BS_RCpower_db ,'bo'); %received power in dB
% xlabel('distance(m)');  
% ylabel('received power(dB)');
% title('test RCPOWER');  

S = zeros(n,19);
I = zeros(n,19);
SINR_matrix = zeros(n,19);

for i = 1:19
     for k = 1:n
         S(k,i) = g_of_d(BSheight, MSheight , d_to_BS(k,i)).*GT.*GR.*MSpower;
         I(k,i) = total_power(i) - S(k,i);
         SINR_matrix(k,i) = mySINR( S(k,i), N , I(k,i));
     end
end


[currentSINR , currentSINR_index] = max(SINR_matrix,[],2);%first bs chosen initially
%--------------------------

figure
hold on
for i = 1:19    
    plot( xv(:,i), yv(:,i))
    axis equal
    plot(x_BS(i),y_BS(i),'k*')  
end

for i = 1:19
    mytext = text(x_BS(i)+15,y_BS(i)+15,int2str(i));
    mytext.FontSize = 12;
end

%testTime = 10;
for t = 1:testTime
    for k = 1:n
        if moving_time(k) ~= 0
            speed_x(k) = speed(k).*cos(mydir(k));
            speed_y(k) = speed(k).*sin(mydir(k));
        else
            moving_time(k) = ceil( unifrnd( minT-1 , maxT ,1));
            
            mydir(k) = unifrnd(0, 2*pi, 1); %my direction
            speed_x(k) = speed(k).*cos(mydir(k));
            speed_y(k) = speed(k).*sin(mydir(k));
        end

        %[next_bs_temp ,xq(k),yq(k)] = update_with_coordinates(xv,yv, outer_xv, outer_yv, x_BS , y_BS,outer_x_BS, outer_y_BS, xq(k) , yq(k) , speed_x(k) , speed_y(k));
        %############################################# update with SINR
        outer_map = [17 18 19 8 12 13 16 17 19 1 3 4 7 8 12 1 2 3]; %corresponding 20-37
        xq(k) = xq(k) + speed_x(k)*1;
        yq(k) = yq(k) + speed_y(k)*1;
        
        %update xq yq coordinates
        in_19_hexagon = 0;
        for i = 1:19
            in_19_hexagon = inpolygon(xq(k),yq(k),xv(:,i), yv(:,i));
            if in_19_hexagon
                break;
            end
        end
        
        in_outer_hexagon = 0;
        if(in_19_hexagon == 0)
            for i = 1:18
                in_outer_hexagon = inpolygon(xq(k),yq(k), outer_xv(:,i), outer_yv(:,i));
                if in_outer_hexagon
                    next_cell = outer_map(i);
                    rel_x = xq(k) - outer_x_BS(i);%relative x,y
                    rel_y = yq(k) - outer_y_BS(i);
                    xq(k) = x_BS(next_cell) + rel_x;
                    yq(k) = y_BS(next_cell) + rel_y;
                    break;
                end
            end
        end
        
        if(in_19_hexagon == 0 && in_outer_hexagon == 0)
            error('not in hexagons');
        end

        %update best SINR with new xq yq
        for i = 1:19
                d_to_BS(k,i) = sqrt( (xq(k) - x_BS(i) )^2 + ( yq(k) - y_BS(i) )^2 );
        end

        BS_RCpower = g_of_d(BSheight, MSheight , d_to_BS).*GT.*GR.*MSpower;
        BS_RCpower_db = linear_to_db(BS_RCpower);
        total_power = sum(BS_RCpower,1);

        for i = 1:19
             S(k,i) = g_of_d(BSheight, MSheight , d_to_BS(k,i)).*GT.*GR.*MSpower;
             I(k,i) = total_power(i) - S(k,i);
             SINR_matrix(k,i) = mySINR( S(k,i), N , I(k,i));
        end

        [bestSINR , bestSINR_index] = max(SINR_matrix,[],2);
        
        %calculate current SINR with new xq yq
   
        d_temp = sqrt( (xq(k) - x_BS(currentSINR_index(k)) )^2 + ( yq(k) - y_BS(currentSINR_index(k)) )^2 );
        
        S_temp = g_of_d(BSheight, MSheight , d_temp).*GT.*GR.*MSpower;
        
        I_temp = total_power(currentSINR_index(k)) - S_temp; 
        currentSINR(k) = mySINR(S_temp, N ,I_temp);
        
        next_bs_temp = currentSINR_index(k);
        if bestSINR(k) - currentSINR(k) > 10 %threshold not sure
            next_bs_temp = bestSINR_index(k);
        elseif currentSINR(k) < -30
            if bestSINR(k) - currentSINR(k) > 3
                next_bs_temp = bestSINR_index(k);
            end
        end
        %##############################################################
        next_connected_bs(k) = next_bs_temp;
        if next_connected_bs(k) ~= currentSINR_index(k) %handover occurs
            %disp_str = "at t = " + int2str(t)+ ", from cell " + int2str(currentSINR_index(k))+" to "+int2str(next_connected_bs(k));
            disp_str = strcat( 'At t = ' , int2str(t)  , ',from cell:'  , int2str(currentSINR_index(k)) , ' to cell:' , int2str(next_connected_bs(k)));
            disp(disp_str);
            record(:,:,size(record,3)+1 ) = [t currentSINR_index(k) next_connected_bs(k)];
            
            currentSINR(k) = bestSINR(k); 
            currentSINR_index(k) = bestSINR_index(k);
        end
    end
    
    hold on
    plot(xq,yq,'r.')
    hold off
    %pause(0.1)
    axis tight
    moving_time = moving_time - 1;
end

title('B-3 moving test') 
xlabel('x(m)')
ylabel('y(m)')
hold off
number_of_handovers = size(record,3)-1;

record_print = reshape(record,size(record,2),size(record,3));
record_print = record_print';
xlswrite('3-b',record_print)