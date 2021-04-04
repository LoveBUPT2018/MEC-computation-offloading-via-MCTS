function [max_objective, X, F] = task_offloading( ...
    CarNumber,...              % 车辆个数
    serverNumber,...            % 服务器个数
    sub_bandNumber,...          % 子带个数
    T_min,...                   % 温度下界
    alpha,...                   % 温度的下降率
    k, ...                      % 邻域解空间的大小
    para...                     % 所需参数
)
%TA Task allocation,任务分配算法，采用模拟退火算法

    [x_old,fx_old,F] = genOriginX(CarNumber, serverNumber,sub_bandNumber,para);    %得到初始解
    
    picture = zeros(2,1);
    iterations = 1;
    T = CarNumber;
    max_objective = 0;
    
    while(T>T_min)
        for I=1:k
            x_new = getneighbourhood(x_old,CarNumber, serverNumber,sub_bandNumber);
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
        T=T*alpha;
    end
%     figure
%     plot(picture(:,1),picture(:,2),'b-.');
%     set(gca,'XDir','reverse');      %对X方向反转
%     title('标准模拟退火算法进行任务调度优化');
%     xlabel('温度T');
%     ylabel('目标函数值');
end
 
function res = getneighbourhood(x,CarNumber,serverNumber,sub_bandNumber)
    Car = unidrnd(CarNumber);     %指定要扰动的车辆对象
    flag_found = 0;
    for server = 1:serverNumber
        for band = 1:sub_bandNumber
            if x(Car,server,band) ~= 0
                flag_found = 1;
                break;  %找到车辆所分配的服务器和频带
            end
        end
        if flag_found == 1
            break;
        end
    end
    %两种扰动方式，交换或者赋值
    chosen = rand;
    if chosen > 0.2
        if chosen < 0.75   %55%的概率更改车辆的服务器（选择offload）
            x(Car,server,band) = 0;
            vary_server = unidrnd(serverNumber);    %目标服务器
            vary_band = randi(sub_bandNumber);    %目标频带
            x(Car,vary_server,vary_band) = 1;
        else    %25%的概率更改车辆的频带（选择offload）
            if sub_bandNumber ~= 1
                x(Car,server,band) = 0;
                vary_band = unidrnd(sub_bandNumber);    %目标频带
                while vary_band == band
                    vary_band = unidrnd(sub_bandNumber);
                end
                x(Car,server,vary_band) = 1;
            end
        end
    else 
        if chosen > 0.05  %15%的概率交换两个车辆的服务器和频带
            if CarNumber ~= 1
                Car_other = unidrnd(CarNumber);    %指定另一个车辆
                while Car_other == Car
                    Car_other = unidrnd(CarNumber);
                end
                flag_found = 0;
                for server_other = 1:serverNumber
                    for band_other=1:sub_bandNumber
                        if x(Car_other,server_other,band_other) ~= 0
                            flag_found = 1;
                            break;  %找到另一个车辆所分配的服务器和频带
                        end
                    end
                    if flag_found == 1
                        break;
                    end
                end
                xValue =  x(Car,server,band);
                xValue_other =  x(Car_other,server_other,band_other);
                x(Car,server,band) = 0;
                x(Car_other,server_other,band_other) = 0;
                x(Car,server_other,band_other) = xValue_other;  %更改频带和服务器
                x(Car_other,server,band) = xValue;
            end
        else    %5%的概率改变该车辆的决策
            x(Car,server,band) = 1 - x(Car,server,band);
        end
    end
    res = x;
end
 
function p = getProbability(delta,t)
    p = exp(delta/t);
end

function [seed,old_J,F] = genOriginX(CarNumber, serverNumber,sub_bandNumber,para)
%GenRandSeed    生成满足约束的随机种子矩阵
    seed = zeros(CarNumber, serverNumber,sub_bandNumber);
    old_J = 0;
    for Car=1:CarNumber
        find = 0;
        for server=1:serverNumber
            for band=1:sub_bandNumber
                seed(Car,server,band) = 1;
                [new_J,new_F] = Fx(seed,para);
                if new_J > old_J
                    old_J = new_J;
                    F = new_F;
                    find = 1;
                    break;
                else
                    seed(Car,server,band) = 0;
                end
            end
            if find == 1
                break;
            end
        end
    end
end