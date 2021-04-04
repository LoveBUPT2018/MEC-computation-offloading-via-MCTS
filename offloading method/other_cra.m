function [F,T] = other_cra(G,Fs,Eta_car)
%CRA computer resourses allocation 运算能力分配
    [carNumber,serverNumber,~] = size(G);
    F = zeros(carNumber,serverNumber);
    T = 0;
    for server = 1:serverNumber
        [Us,n] = genUs(G,server);
        EtaRoot_sum = 0;
        for car = 1:n
            EtaRoot_sum = EtaRoot_sum + Eta_car(Us(car,1))^(0.5);
        end
        if n > 0
            for car = 1:n
                if Eta_car(Us(car,1)) > 0
                    F(Us(car,1),server) = Fs(server) * Eta_car(Us(car,1))^(0.5) / EtaRoot_sum;
                end
            end
            T = T + 1/Fs(server) * EtaRoot_sum^2;
        end
    end
end