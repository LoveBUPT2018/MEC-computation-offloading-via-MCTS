function H = genGain(carNumber,serverNumber,sub_bandNumber,gapOfServer)
%GENGAIN 生成随机的信道增益
    [serverMap,carMap] = genLocation(carNumber,serverNumber,gapOfServer);
    H = zeros(carNumber,serverNumber,sub_bandNumber);
    for i = 1:carNumber
        for j = 1:serverNumber
            dis = ((carMap(i,1)-serverMap(j,1))^2+(carMap(i,2)-serverMap(j,2))^2)^0.5;
            gain_DB = 140.7 + 36.7*log10(dis/1000);
            H(i,j,:) = 1/(10^(gain_DB/10)) * ones(1,sub_bandNumber);
        end
    end
%     plot(serverMap(:,1),serverMap(:,2),'*r')
%     hold on
%     plot(carMap(:,1),carMap(:,2),'.b')
end


