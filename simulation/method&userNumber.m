clear;
serverNumber = 9;
sub_bandNumber = 3;
Fs = 20e9 * ones(serverNumber,1);   %服务器运算能力矩阵
T0.data = [];   %任务由数据大小、运算所需时钟周期数、输出大小组成
T0.circle = [];
gapOfServer = 25;
Sigma_square = 1e-13;
W = 20e6;   %系统总带宽
k = 5e-27;

%测试不同用户数下不同算法的平均函数值和平均计算时间
index = 1;
size = 11;

annealing_time_mean = zeros(size,1);
MCTS_time_mean = zeros(size,1);
greedy_time_mean = zeros(size,1);
localSearch_time_mean = zeros(size,1);
exhausted_time = zeros(size,1);

annealing_objective_mean = zeros(size,1);
MCTS_objective_mean = zeros(size,1);
greedy_objective_mean = zeros(size,1);
localSearch_objective_mean = zeros(size,1);
exhausted_objective = zeros(size,1);
    
task_circle = 1000e6;

for carNumber = 5:10:105
    
    H = genGain(carNumber,serverNumber,sub_bandNumber,gapOfServer);   %用户到服务器的增益矩阵
    Fu = 1e9 * ones(carNumber,1);  %用户运算能力矩阵
    task_size = 420 * 1024 * 8; %480KB
    Tu = repmat(T0,carNumber,1);
    for i = 1:carNumber    %初始化任务矩阵
        Tu(i).data = task_size;
        Tu(i).circle = task_circle;
    end
    lamda = ones(carNumber,1);
    beta_time = 0.5 * ones(carNumber,1);
    beta_enengy = ones(carNumber,1) - beta_time;
    Pu = 0.001 * 10^2 * ones(carNumber,1);    %用户输出功率矩阵
    
    test_time = 20;  %每个算法循环次数

    annealing_time = zeros(test_time,1);
    MCTS_time = zeros(5,1);
    greedy_time = zeros(test_time,1);
    localSearch_time = zeros(test_time,1);
    annealing_objective = zeros(test_time,1);
    MCTS_objective = zeros(5,1);
    greedy_objective = zeros(test_time,1);
    localSearch_objective = zeros(test_time,1);

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
    
    %MCTS算法
    for time = 1: 5    
        tic;
        [J0,X0,F0] = optimize_MCTS(Fu,Fs,Tu,W,Pu,H,...
        lamda,Sigma_square,beta_time,beta_enengy,...
        k,...                           % 芯片能耗系数
        carNumber,serverNumber,sub_bandNumber ...
        );
        MCTS_time(time) = toc;
        MCTS_objective(time) = J0;
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
x =  5:10:105;
plot(x,annealing_time_mean,'-s');
hold on
plot(x,MCTS_time_mean,'-d');
hold on
plot(x,greedy_time_mean,'-o');
hold on
plot(x,localSearch_time_mean,'-x');
xlabel('用户数');
ylabel('平均计算时间');
grid on
legend('模拟退火算法','MCTS算法','贪心算法','局部搜索算法');

figure
x =  5:10:105;
plot(x,annealing_objective_mean,'-s');
hold on
plot(x,MCTS_objective_mean,'-d');
hold on
plot(x,greedy_objective_mean,'-o');
hold on
plot(x,localSearch_objective_mean,'-x');
xlabel('用户数');
ylabel('平均目标函数值');
grid on
legend('模拟退火算法','MCTS算法','贪心算法','局部搜索算法');
