function [J, X, F] = ta_standard_model(Fu,Fs,Tu,W,Pu,H,...
    lamda,Sigma_square,beta_time,beta_enengy,...
    k,...                       % оƬ�ܺ�ϵ��
    carNumber,serverNumber,sub_bandNumber,...
    T,...                       % ��ʼ�¶�
    T_min,...                   % �¶��½�
    alpha,...                   % �¶ȵ��½���
    n ...                       % �����ռ�Ĵ�С
    )

%optimize ����ִ���Ż���������ͳ�˻�ʽ
    tu_local = zeros(carNumber,1);
    Eu_local = zeros(carNumber,1);
    for i = 1:carNumber    %��ʼ���������
        tu_local(i) = Tu(i).circle/Fu(i);   %���ؼ���ʱ�����
        Eu_local(i) = k * (Fu(i))^2 * Tu(i).circle;    %���ؼ����ܺľ���
    end
    Eta_car = zeros(carNumber,1);
    for i=1:carNumber  %����CRA����Ħ�
        Eta_car(i) = beta_time(i) * Tu(i).circle * lamda(i) / tu_local(i);
    end
    
    %��װ����
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
    
   [J, X, F] = ta( ...
    carNumber,...              % �û�����
    serverNumber,...            % ����������
    sub_bandNumber,...          % �Ӵ�����
    T,...                       % ��ʼ�¶�
    T_min,...                   % �¶��½�
    alpha,...                   % �¶ȵ��½���
    n, ...                      % �����ռ�Ĵ�С
    para...                     % �������
    );

end

function [max_objective, X, F] = ta( ...
    carNumber,...              % �û�����
    serverNumber,...            % ����������
    sub_bandNumber,...          % �Ӵ�����
    T,...                       % ��ʼ�¶�
    T_min,...                   % �¶��½�
    alpha,...                   % �¶ȵ��½���
    k, ...                      % �����ռ�Ĵ�С
    para...                     % �������
)
%TA Task allocation,��������㷨������ģ���˻��㷨

    [x_old,fx_old,F] = genOriginX(carNumber, serverNumber,sub_bandNumber,para);    %�õ���ʼ��
    
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
        T=T*alpha;
    end
%     figure
%     plot(picture(:,1),picture(:,2),'b-.');
%     set(gca,'XDir','reverse');      %��X����ת
%     title('��׼ģ���˻��㷨������������Ż�');
%     xlabel('�¶�T');
%     ylabel('Ŀ�꺯��ֵ');
end
 
function res = getneighbourhood(x,carNumber,serverNumber,sub_bandNumber)
    car = unidrnd(carNumber);     %ָ��Ҫ�Ŷ����û�����
    flag_found = 0;
    for server = 1:serverNumber
        for band = 1:sub_bandNumber
            if x(car,server,band) ~= 0
                flag_found = 1;
                break;  %�ҵ��û�������ķ�������Ƶ��
            end
        end
        if flag_found == 1
            break;
        end
    end
    %�����Ŷ���ʽ���������߸�ֵ
    chosen = rand;
    if chosen > 0.2
        if chosen < 0.75   %55%�ĸ��ʸ����û��ķ�������ѡ��offload��
            x(car,server,band) = 0;
            vary_server = unidrnd(serverNumber);    %Ŀ�������
            vary_band = randi(sub_bandNumber);    %Ŀ��Ƶ��
            x(car,vary_server,vary_band) = 1;
        else    %25%�ĸ��ʸ����û���Ƶ����ѡ��offload��
            if sub_bandNumber ~= 1
                x(car,server,band) = 0;
                vary_band = unidrnd(sub_bandNumber);    %Ŀ��Ƶ��
                while vary_band == band
                    vary_band = unidrnd(sub_bandNumber);
                end
                x(car,server,vary_band) = 1;
            end
        end
    else 
        if chosen > 0.05  %15%�ĸ��ʽ��������û��ķ�������Ƶ��
            if carNumber ~= 1
                car_other = unidrnd(carNumber);    %ָ����һ���û�
                while car_other == car
                    car_other = unidrnd(carNumber);
                end
                flag_found = 0;
                for server_other = 1:serverNumber
                    for band_other=1:sub_bandNumber
                        if x(car_other,server_other,band_other) ~= 0
                            flag_found = 1;
                            break;  %�ҵ���һ���û�������ķ�������Ƶ��
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
                x(car,server_other,band_other) = xValue_other;  %����Ƶ���ͷ�����
                x(car_other,server,band) = xValue;
            end
        else    %5%�ĸ��ʸı���û��ľ���
            x(car,server,band) = 1 - x(car,server,band);
        end
    end
    res = x;
end
 
function p = getProbability(delta,t)
    p = exp(delta/t);
end

function [seed,old_J,F] = genOriginX(carNumber, serverNumber,sub_bandNumber,para)
%GenRandSeed    ��������Լ����������Ӿ���
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