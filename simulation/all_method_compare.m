carNumber = 11;
serverNumber = 2;
sub_bandNumber = 2;
Fs = 20e9 * ones(serverNumber,1);   %服务器运算能力矩阵
Fu = 1e9 * ones(carNumber,1);  %车辆运算能力矩阵
T0.data = [];   %任务由数据大小、运算所需时钟周期数、输出大小组成
T0.circle = [];
gapOfServer = 25;
H = genGain(carNumber,serverNumber,sub_bandNumber,gapOfServer);   %车辆到服务器的增益矩阵
    
%测试不同任务所需时钟周期数下的各个算法的目标函数值
index = 1;

annealing_time_mean = zeros(4,1);
MCTS_time_mean = zeros(4,1);
greedy_time_mean = zeros(4,1);
localSearch_time_mean = zeros(4,1);
exhausted_time = zeros(4,1);

annealing_objective_mean = zeros(4,1);
MCTS_objective_mean = zeros(4,1);
greedy_objective_mean = zeros(4,1);
localSearch_objective_mean = zeros(4,1);
exhausted_objective = zeros(4,1);
    
for task_circle = [250e6 500e6 1000e6 2000e6]    %100 Megacycles 
    task_size = 420 * 1024 * 8; %480KB
    Tu = repmat(T0,carNumber,1);
    for i = 1:carNumber    %初始化任务矩阵
    Tu(i).data = task_size;
    Tu(i).circle = task_circle;
    end
    lamda = ones(carNumber,1);
    beta_time = 0.5 * ones(carNumber,1);
    beta_enengy = ones(carNumber,1) - beta_time;

    Pu = 0.001 * 10^2 * ones(carNumber,1);    %车辆输出功率矩阵

    Sigma_square = 1e-13;
    W = 20e6;   %系统总带宽
    k = 5e-27;

    test_time = 15;  %每个算法循环次数

    annealing_time = zeros(test_time,1);
    MCTS_time = zeros(test_time,1);
    greedy_time = zeros(test_time,1);
    localSearch_time = zeros(test_time,1);
    annealing_objective = zeros(test_time,1);
    MCTS_objective = zeros(test_time,1);
    greedy_objective = zeros(test_time,1);
    localSearch_objective = zeros(test_time,1);

    %MCTS算法
    parfor time = 1: test_time    
    tic;
    [J0,X0,F0] = optimize_MCTS(Fu,Fs,Tu,W,Pu,H,...
    lamda,Sigma_square,beta_time,beta_enengy,...
    k,...                           % 芯片能耗系数
    carNumber,serverNumber,sub_bandNumber ...
    );
    MCTS_time(time) = toc;
    MCTS_objective(time) = J0;
    end

    %退火算法
    parfor time = 1: test_time  
    tic;
    [J2,X2,F2] = optimize_MEC(Fu,Fs,Tu,W,Pu,H,...
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

    %贪心算法
    parfor time = 1: test_time
    tic;
    [J3,X3,F3] = optimize_greedy(Fu,Fs,Tu,W,Pu,H,...
    lamda,Sigma_square,beta_time,beta_enengy,...
    k,...                           % 芯片能耗系数
    carNumber,serverNumber,sub_bandNumber ...
    );
    greedy_time(time) = toc;
    greedy_objective(time) = J3;
    end

    %局部搜索算法
    parfor time = 1: test_time
    tic;
    [J4,X4,F4] = optimize_localSearch(Fu,Fs,Tu,W,Pu,H,...
    lamda,Sigma_square,beta_time,beta_enengy,...
    k,...                           % 芯片能耗系数
    carNumber,serverNumber,sub_bandNumber,...
    30 ...                          % 最大迭代次数
    );
    localSearch_time(time)  = toc;
    localSearch_objective(time) = J4;
    end

    %穷举法
    tic;
    [J5,X5,F5] = optimize_exhausted(Fu,Fs,Tu,W,Pu,H,...
    lamda,Sigma_square,beta_time,beta_enengy,...
    k,...                           % 芯片能耗系数
    carNumber,serverNumber,sub_bandNumber...
    );
    exhausted_time(index) = toc;
    exhausted_objective(index) = J5;

    annealing_time_mean(index) = mean(annealing_time);
    MCTS_time_mean(index) = mean(MCTS_time);
    greedy_time_mean(index) = mean(greedy_time);
    localSearch_time_mean(index) = mean(localSearch_time);

    annealing_objective_mean(index) = mean(annealing_objective);
    MCTS_objective_mean(index) = mean(MCTS_objective);
    greedy_objective_mean(index) = mean(greedy_objective);
    localSearch_objective_mean(index) = mean(localSearch_objective);
    
    index = index + 1;
end
   
figure
vals = [annealing_objective_mean(1),MCTS_objective_mean(1),greedy_objective_mean(1),localSearch_objective_mean(1),exhausted_objective(1);
    annealing_objective_mean(2),MCTS_objective_mean(2),greedy_objective_mean(2),localSearch_objective_mean(2),exhausted_objective(2);
    annealing_objective_mean(3),MCTS_objective_mean(3),greedy_objective_mean(3),localSearch_objective_mean(3),exhausted_objective(3);
    annealing_objective_mean(4),MCTS_objective_mean(4),greedy_objective_mean(4),localSearch_objective_mean(4),exhausted_objective(4)];
b = bar(vals,0.4);
xlabel('任务负载/兆周期');
ylabel('目标函数值');
grid on
legend('模拟退火算法','MCTS算法','贪心算法','局部搜索算法','穷举算法');

figure
vals = [annealing_time_mean(1),MCTS_time_mean(1),greedy_time_mean(1),localSearch_time_mean(1),exhausted_time(1);
    annealing_time_mean(2),MCTS_time_mean(2),greedy_time_mean(2),localSearch_time_mean(2),exhausted_time(2);
    annealing_time_mean(3),MCTS_time_mean(3),greedy_time_mean(3),localSearch_time_mean(3),exhausted_time(3);
    annealing_time_mean(4),MCTS_time_mean(4),greedy_time_mean(4),localSearch_time_mean(4),exhausted_time(4)];
b = bar(vals,0.4);
xlabel('任务负载/兆周期');
ylabel('计算时间/s');
grid on
legend('模拟退火算法','MCTS算法','贪心算法','局部搜索算法','穷举算法');