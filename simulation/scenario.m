serverNumberSet = [4,9,16,25];
carNumberSet = [12,30,50,100];
gapOfServerSet = [300,250,100,20];
sub_bandNumber = 3;
T0.data = [];   %任务由数据大小、运算所需时钟周期数、输出大小组成
T0.circle = [];

    
%测试不同部署场景下算法的计算时间

annealing_time_mean = zeros(4,1);
annealing_objective_mean = zeros(4,1);
    
for index = 1:4
    serverNumber = serverNumberSet(index);
    carNumber = carNumberSet(index);
    gapOfServer = gapOfServerSet(index);
    
    Fs = 20e9 * ones(serverNumber,1);   %服务器运算能力矩阵
    H = genGain(carNumber,serverNumber,sub_bandNumber,gapOfServer);   %用户到服务器的增益矩阵
    Fu = 1e9 * ones(carNumber,1);  %用户运算能力矩阵
    task_circle = 1000e6;
    task_size = 420 * 1024 * 8; %480KB
    Tu = repmat(T0,carNumber,1);
    for i = 1:carNumber    %初始化任务矩阵
    Tu(i).data = task_size;
    Tu(i).circle = task_circle;
    end
    lamda = ones(carNumber,1);
    beta_time = 0.2 * ones(carNumber,1);
    beta_enengy = ones(carNumber,1) - beta_time;

    Pu = 0.001 * 10^2 * ones(carNumber,1);    %用户输出功率矩阵

    Sigma_square = 1e-13;
    W = 20e6;   %系统总带宽
    k = 5e-27;

    test_time = 15;  %每个算法循环次数

    annealing_time = zeros(test_time,1);
    annealing_objective = zeros(test_time,1);

    %退火算法
    parfor time = 1: test_time  
    tic;
    [J2,X2,F2] = optimize_annealing(Fu,Fs,Tu,W,Pu,H,...
    lamda,Sigma_square,beta_time,beta_enengy,...
    k,...                           % 芯片能耗系数
    carNumber,serverNumber,sub_bandNumber,...
    10e-9,...                       % 温度下界
    0.97,...                        % 温度的下降率
    5 ...                           % 邻域解空间的大小
    );
    annealing_time(time) = toc;
    annealing_objective(time) = J2;
    end

    annealing_time_mean(index) = mean(annealing_time);
    annealing_objective_mean(index) = mean(annealing_objective);
   
end