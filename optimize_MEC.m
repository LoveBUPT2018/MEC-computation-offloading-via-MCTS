function [J, X, F] = optimize_MEC(Fu,Fs,Tu,W,Pu,H,...
    lamda,Sigma_square,beta_time,beta_enengy,...
    k,...                       % 芯片能耗系数
    CarNumber,serverNumber,sub_bandNumber,...
    T_min,...                   % 温度下界
    alpha,...                   % 温度的下降率
    n ...                      % 邻域解空间的大小
    )

%optimize 负责执行优化操作
    tu_local = zeros(CarNumber,1);
    Eu_local = zeros(CarNumber,1);
    for i = 1:CarNumber    %初始化任务矩阵
        tu_local(i) = Tu(i).circle/Fu(i);   %本地计算时间矩阵
        Eu_local(i) = k * (Fu(i))^2 * Tu(i).circle;    %本地计算能耗矩阵
    end
    Eta_Car = zeros(CarNumber,1);
    for i=1:CarNumber  %计算CRA所需的η
        Eta_Car(i) = beta_time(i) * Tu(i).circle * lamda(i) / tu_local(i);
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
    para.Eta_Car = Eta_Car;
    
   [J, X, F] = task_offloading( ...
    CarNumber,...              % 车辆个数
    serverNumber,...            % 服务器个数
    sub_bandNumber,...          % 子带个数
    T_min,...                   % 温度下界
    alpha,...                   % 温度的下降率
    n, ...                      % 邻域解空间的大小
    para...                    % 所需参数
    );

end