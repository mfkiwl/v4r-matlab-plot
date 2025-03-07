% 文件夹结构
% ..
% .
% anno/
% scaledata/
% calScale.m
% 如果新增参数，需要将 scaledata/ 内原有文件删除

clc;clear;close all;
% DTB70 UAV20L UAV123 UAV123_10fps UAVDT
datasetName = 'UAV123_10fps';

% 相关文件夹
annoFolder = ['./anno/' datasetName '/'];
resultFolder = ['./scaledata/' datasetName '/'];

% 读取后namelist 的格式为
% name -- filename
% date -- modification date
% bytes -- number of bytes allocated to the file
% isdir -- 1 if name is a directory and 0 if not
namelist = dir([annoFolder '*.txt']);
len = length(namelist);
for i = 1:len
    file_name{i}=namelist(i).name;
end

%% 尺寸变化可视化
vis = 0; % 是否可视化
visNum = 2; % 可视化N个序列
if vis
    for i = 1:visNum
        read_data = dlmread([annoFolder file_name{i}]);
        seqLen = max(size(read_data));
        % beforeScale = read_data(1:len-1,3:4);
        % 初始比例
        ratio0 = read_data(1,4) / read_data(1,3);
        beforeScale = read_data(1,3:4);
        beforeScale = repmat(beforeScale,seqLen-1,1);
        afterScale = read_data(2:seqLen,3:4);
        scaleChange = afterScale ./ beforeScale;
        [m,n]=find(isnan(scaleChange)==1);
        scaleChange(m,:)=[];
        figure(100+i);
        scatter(scaleChange(:,1), scaleChange(:,2));
        axis equal
        title([file_name{i}(1:end-4) ' height/width: ' num2str(ratio0)]);
        hold on
        minX = min(scaleChange(:,1));
        maxX = max(scaleChange(:,1));
        x = minX:0.01:maxX;
        y = x;
        plot(x, y);
    end
end

%% 尺寸变化可视化（按步长）
visStep = 0; % 是否可视化
visStepNum = 1; % 可视化N个序列
stepSize = 1.02; % 步长
% log1.02(8)=log10(8)/log10(1.02)
if visStep
    for i = 1:visStepNum
        read_data = dlmread([annoFolder file_name{i}]);
        seqLen = max(size(read_data));
        % beforeScale = read_data(1:len-1,3:4);
        % 初始比例
        ratio0 = read_data(1,4) / read_data(1,3);
        beforeScale = read_data(1,3:4);
        beforeScale = repmat(beforeScale,seqLen-1,1);
        afterScale = read_data(2:seqLen,3:4);
        scaleChange = afterScale ./ beforeScale;
        [m,n]=find(isnan(scaleChange)==1);
        scaleChange(m,:)=[];
        logscaleChange = log10(scaleChange)/log10(stepSize);
        figure(200+i);
        scatter(logscaleChange(:,1), logscaleChange(:,2));
        axis equal
        title([file_name{i}(1:end-4) ' height/width: ' num2str(ratio0)]);
%         hold on
%         minX = min(scaleChange(:,1));
%         maxX = max(scaleChange(:,1));
%         x = minX:0.01:maxX;
%         y = x;
%         plot(x, y);
    end
end

%% 统计h>w的情况
calFrame = 1; % 是否计算并输出
calNum = len; % 写入 len
table_name = [datasetName '_scale_data.xlsx'];
txt_name = [datasetName '_scale_data.txt'];
if calFrame
    for i = 1:calNum
        read_data = dlmread([annoFolder file_name{i}]);
        seqLen = max(size(read_data));
        % 与上一帧比较
        % beforeScale = read_data(1:len-1,3:4); 
        % 与第一帧比较
        beforeScale = read_data(1,3:4);
        beforeScale = repmat(beforeScale,seqLen-1,1);
        afterScale = read_data(2:seqLen,3:4);
        scaleChange = afterScale ./ beforeScale;
        [m,n]=find(isnan(scaleChange)==1);
        scaleChange(m,:)=[];
        % w比h大的帧数
        wFrame = sum(scaleChange(:,1) > scaleChange(:,2), 1);
        % h比w大的帧数
        hFrame = sum(scaleChange(:,1) < scaleChange(:,2), 1);
        % 一样大的帧数
        eFrame = sum(scaleChange(:,1) == scaleChange(:,2), 1);
        % NaN帧数 = (总帧数-1) - w比h大的帧数 - h比w大的帧数 - 一样大的帧数
        nanFrame = seqLen - 1 - wFrame - hFrame - eFrame; % 第一帧不考虑
        % 序列名
        seqName = file_name{i}(1:end-4);
        % 初始比例
        ratio0 = read_data(1,4) / read_data(1,3);
        % 序列wFrame >= hFrame
        if wFrame >= hFrame
            wGeqh='1'; wLh='0';
        % 序列wFrame < hFrame
        else
            wGeqh='0'; wLh='1';
        end
        % maxW
        maxW = max(scaleChange(:,1));
        % minW
        minW = min(scaleChange(:,1));
        % maxH
        maxH = max(scaleChange(:,2));
        % minH
        minH = min(scaleChange(:,2));
        % TO DO 其他新增参数
        % 新增参数需要改 write_data, T=table(...) T.Properties.VariableNames
        
        % 写入txt数据格式
        write_data = [seqName ',' num2str(wFrame) ',' num2str(hFrame) ',' ...
            num2str(eFrame) ',' num2str(nanFrame) ',' num2str(ratio0) ',' ...
            wGeqh ',' wLh, ',' ...
            num2str(maxW) ',' num2str(minW) ',' ...
            num2str(maxH) ',' num2str(minH)];
        % 关于文件夹相关判定
        if exist(resultFolder)==0 %该文件夹不存在，则直接创建
            mkdir(resultFolder);
%         else %该文件夹存在，则先删除再创建
%             rmdir(resultFolder, 's'); %该文件夹中有没有文件均可
%             mkdir(resultFolder);
        end
        fid=fopen([resultFolder txt_name],'a+'); % validation training
        fprintf(fid,'%s\n',write_data);
        fclose(fid);
    end
    % txt转xlsx/csv
    dt=importdata([resultFolder txt_name]); 
    T=table(dt.rowheaders,dt.data(:,1),dt.data(:,2),...
        dt.data(:,3),dt.data(:,4),dt.data(:,5),...
        dt.data(:,6),dt.data(:,7),dt.data(:,8),...
        dt.data(:,9),dt.data(:,10),dt.data(:,11));
    T.Properties.VariableNames = {'seqName','wBiggerFrames','hBiggerFrames','whEqualFrames','nanFrames','initialRatio'...
        'wDominance','hDominance','maxW','minW','maxH','minH'};
    writetable(T,[resultFolder table_name]);
end

%% TODO 计算尺度变化方格
