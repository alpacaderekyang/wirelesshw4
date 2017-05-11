temperature = 300; % 27,300k 
B = 10*10^6/50; %bandwidth 10M
%I = 0;
N = myNoise(300,B);
GT_db = 14;
GR_db = 14;
BSpower_db = 33-30; % 33dBm
%changed here
MSpower_db = 0-30; % 0dBm

GT = db_to_linear(GT_db);
GR = db_to_linear(GR_db);
BSpower = db_to_linear(BSpower_db);
MSpower = db_to_linear(MSpower_db);

BSheight = 51.5; %1.5+ 50
MSheight = 1.5;

n = 50;%number of ms in a cell

bufferSize = 6*10^6; %6M
testTime = 1000;%duration 1000
%CBR = [0.25, 0.5 , 1]*10^6; %constant bit rate, CBR parameters {Xl, Xm, Xh}
PTA = [0.25, 0.5 , 1]*10^6;% Poisson traffic arrival  = {lamda_l,lamda_m, lamda_h},


%location of 19 BS (modified from hw2)
x_BS = sqrt(3)*[-500, -500, -500, -250, -250, -250, -250,    0,   0,  0,    0,     0, 250,  250,  250,  250, 500, 500,  500];
y_BS =         [500 ,    0, -500,  750,  250, -250, -750, 1000, 500,  0, -500, -1000, 750 , 250, -250, -750, 500,   0, -500];

%outer_x_BS = sqrt(3)*[-750, -750 , -750, -750, -500,  -500, -250 , -250,    0,    0,  250,  250,  500,  500, 750, 750, 750, 750];
%outer_y_BS =         [ 750,  250 , -250, -750, 1000, -1000, 1250 ,-1250, 1500,-1500, 1250,-1250, 1000,-1000, 750, 250,-250,-750];

xv = zeros(7,19);
yv = zeros(7,19); %vertice of hexagon

xq = zeros(n,19);
yq = zeros(n,19);

%center cell
figure
hold on
%[~ , ~ , xq , yq] = get_cell( 0 , 0 , n);

%use get_cell to get every ms in central cell
for i = 1:19
    [xv(:,i),yv(:,i), xq(:,i) , yq(:,i)] = get_cell(x_BS(i), y_BS(i), n);
end

axis equal
plot( xv(:,10), yv(:,10))
plot(x_BS(10),y_BS(10),'k*')  
plot(xq(:,10),yq(:,10),'ro')

title('figure B-1') 
xlabel('x(m)')
ylabel('y(m)')
hold off

%shannon capacity C=B*log2(1+linearSINR)

I = zeros(n,1);
d_to_centralBS = sqrt( xq(:,10).^2 + yq(:,10).^2 ); %d_to_centralBS size n*1
S =  g_of_d(BSheight, MSheight , d_to_centralBS).*GT.*GR.*BSpower; %S size n*1

for i=1:n %i th MS in central cell
    temp_p = 0;
    for k=1:19 % k th BS
        temp_d = sqrt( (xq(i,10) - x_BS(k))^2 + (yq(i,10)-y_BS(k))^2 );
        if k~=10 %except central bs
            temp_p = temp_p + g_of_d(BSheight, MSheight , temp_d).*GT.*GR.*BSpower;
        end
    end
    I(i,1) = temp_p;
end

linearSINR =  S./(N+I);
C=B.*log2(1+linearSINR); %shannon capacity C=B/*log2(1+S./(I+N))

figure
plot(d_to_centralBS , C ,'o');
title('figure B-2') 
xlabel('distance(m)')
ylabel('Shannon Capacity(bits/s)')


bitloss = zeros(1,3);
total_bit = zeros(1,3); %total bits
rem_buff = ones(1,3)*bufferSize; %remaining buffer
data_buff = zeros(n,3); %data in buffer corresponding to each MS
for t = 1:testTime
    for i=1:n
        for k=1:3 %rate low medium high
            temp_arrival = poissrnd(PTA(k));
            total_bit(1,k) = total_bit(1,k) + temp_arrival;
            if C(i,1) < temp_arrival %rate > capacity , goes to buffer
                rem_buff(1,k) = rem_buff(1,k) - (temp_arrival-C(i,1));
                data_buff(i,k) = data_buff(i,k) + (temp_arrival-C(i,1));
                if (rem_buff(1,k) < 0) %buffer is full
                    bitloss(1,k) = bitloss(1,k) - rem_buff(1,k);
                    rem_buff(1,k) = 0;
                end
            elseif  C(i,1) > temp_arrival %less thing in buffer
                if data_buff(i,k) ~=0 
                    if data_buff(i,k) > (C(i,1) - temp_arrival) %can not clear all buffer caused by the MS
                        rem_buff(1,k) = rem_buff(1,k) + (C(i,1) - temp_arrival);
                        data_buff(i,k) = data_buff(i,k) - (C(i,1) - temp_arrival);
                    else %can clear all buffer caused by the MS
                        rem_buff(1,k) = rem_buff(1,k) + data_buff(i,k);
                        data_buff(i,k) = 0; 
                    end
                end
            end
        end
    end
end

loss_prob = bitloss ./ total_bit; 
    
figure
bar(PTA , loss_prob);
title('figure B-3') 
xlabel('traffic load(bits/s)')
ylabel('bits loss probability')