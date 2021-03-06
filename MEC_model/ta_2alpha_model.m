function [J, X, F] = ta_2alpha_model(Fu,Fs,Tu,W,Pu,H,...
    lamda,Sigma_square,beta_time,beta_enengy,...
    k,...                       % 芯片能耗系数
    carNumber,serverNumber,sub_bandNumber,...
    T_min,...                   % 温度下界
    alpha,...                   % 温度的下降率
    n ...                      % 邻域解空间的大小
    )

%optimize 负责执行优化操作，采用双阶段不同下降率的模拟退火方式

    tu_local = zeros(carNumber,1);
    Eu_local = zeros(carNumber,1);
    for i = 1:carNumber    %初始化任务矩阵
        tu_local(i) = Tu(i).circle/Fu(i);   %本地计算时间矩阵
        Eu_local(i) = k * (Fu(i))^2 * Tu(i).circle;    %本地计算能耗矩阵
    end
    Eta_car = zeros(carNumber,1);
    for i=1:carNumber  %计算CRA所需的η
        Eta_car(i) = beta_time(i) * Tu(i).circle * lamda(i) / tu_local(i);
    end
    
    %封装参数
    para.beta_time = beta_time;
    para.beta_enengy = beta_enengy;
    para.Tu = Tu;
    para.tu_local = tu_local;
    para.Eu_local = Eu_local;
    para.W = W;
    para.Ht = H;
    para.lamda = lamda;
    para.Pu = Pu;
    para.Sigma_square = Sigma_square;
    para.Fs = Fs;
    para.Eta_car = Eta_car;
    
   [J, X, F] = ta_2alpha_annealing( ...
    carNumber,...              % 用户个数
    serverNumber,...            % 服务器个数
    sub_bandNumber,...          % 子带个数
    T_min,...                   % 温度下界
    alpha,...                   % 温度的下降率
    n, ...                      % 邻域解空间的大小
    para...                    % 所需参数
    );

end

function [max_objective, X, F] = ta_2alpha_annealing( ...
    carNumber,...              % 用户个数
    serverNumber,...            % 服务器个数
    sub_bandNumber,...          % 子带个数
    T_min,...                   % 温度下界
    alpha,...                   % 温度的下降率
    k, ...                      % 邻域解空间的大小
    para...                    % 所需参数
)
%TA Task allocation,任务分配算法，采用模拟退火算法

    T = carNumber*0.15;
    threshold = round(log(carNumber)/log(0.95));

    [x_old,fx_old,F] = genOriginX(carNumber, serverNumber,sub_bandNumber,para);    %得到初始解
    
    picture = zeros(2,1);
    iterations = 1;
    
    max_objective = 0;
    
    while(T>T_min)
        for I=1:k
            x_new = getneighbourhood(x_old,carNumber, serverNumber,sub_bandNumber);
            [fx_new, F_new] = Fx(x_new,para);
            delta = fx_new-fx_old;
            if (delta>0)
                x_old = x_new;
                fx_old = fx_new;
                if fx_new > max_objective
                    max_objective = fx_new;
                    X = x_new;
                    F = F_new;
                end
            else
                pro=getProbability(delta,T);
                if(pro>rand)
                    x_old=x_new;
                    fx_old = fx_new;
                end
            end
        end
        picture(iterations,1) = T;
        picture(iterations,2) = fx_old;
        iterations = iterations + 1;
        if iterations < threshold
            T=T*0.95;
        else
            T=T*alpha;
        end
    end
    figure
    plot(picture(:,1),picture(:,2),'b-.');
    set(gca,'XDir','reverse');      %对X方向反转
    title('模拟退火算法进行任务调度优化');
    xlabel('温度T');
    ylabel('目标函数值');
end
 
function res = getneighbourhood(x,carNumber,serverNumber,sub_bandNumber)
    car = unidrnd(carNumber);     %指定要扰动的用户对象
    flag_found = 0;
    for server = 1:serverNumber
        for band = 1:sub_bandNumber
            if x(car,server,band) ~= 0
                flag_found = 1;
                break;  %找到用户所分配的服务器和频带
            end
        end
        if flag_found == 1
            break;
        end
    end
    %两种扰动方式，交换或者赋值
    chosen = rand;
    if chosen > 0.2
        if chosen < 0.75   %55%的概率更改用户的服务器（选择offload）
            x(car,server,band) = 0;
            vary_server = unidrnd(serverNumber);    %目标服务器
            vary_band = randi(sub_bandNumber);    %目标频带
            x(car,vary_server,vary_band) = 1;
        else    %25%的概率更改用户的频带（选择offload）
            if sub_bandNumber ~= 1
                x(car,server,band) = 0;
                vary_band = unidrnd(sub_bandNumber);    %目标频带
                while vary_band == band
                    vary_band = unidrnd(sub_bandNumber);
                end
                x(car,server,vary_band) = 1;
            end
        end
    else 
        if chosen > 0.05  %15%的概率交换两个用户的服务器和频带
            if carNumber ~= 1
                car_other = unidrnd(carNumber);    %指定另一个用户
                while car_other == car
                    car_other = unidrnd(carNumber);
                end
                flag_found = 0;
                for server_other = 1:serverNumber
                    for band_other=1:sub_bandNumber
                        if x(car_other,server_other,band_other) ~= 0
                            flag_found = 1;
                            break;  %找到另一个用户所分配的服务器和频带
                        end
                    end
                    if flag_found == 1
                        break;
                    end
                end
                xValue =  x(car,server,band);
                xValue_other =  x(car_other,server_other,band_other);
                x(car,server,band) = 0;
                x(car_other,server_other,band_other) = 0;
                x(car,server_other,band_other) = xValue_other;  %更改频带和服务器
                x(car_other,server,band) = xValue;
            end
        else    %5%的概率改变该用户的决策
            x(car,server,band) = 1 - x(car,server,band);
        end
    end
    res = x;
end
 
function p = getProbability(delta,t)
    p = exp(delta/t);
end

function [seed,old_J,F] = genOriginX(carNumber, serverNumber,sub_bandNumber,para)
%GenRandSeed    生成满足约束的随机种子矩阵
    seed = zeros(carNumber, serverNumber,sub_bandNumber);
    old_J = 0;
    for car=1:carNumber
        find = 0;
        for server=1:serverNumber
            for band=1:sub_bandNumber
                seed(car,server,band) = 1;
                [new_J,new_F] = Fx(seed,para);
                if new_J > old_J
                    old_J = new_J;
                    F = new_F;
                    find = 1;
                    break;
                else
                    seed(car,server,band) = 0;
                end
            end
            if find == 1
                break;
            end
        end
    end
end