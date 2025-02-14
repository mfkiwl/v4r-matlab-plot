%% 参考
% 1. writematrix (2019a)
% https://ww2.mathworks.cn/help/matlab/ref/writematrix.html
% 2. writematrix (2019a)
% https://ww2.mathworks.cn/help/matlab/ref/writetable.html

%% 文件夹结构
% ..
% .
% anno/
% scaledata/
% calScale.m
% calAtt.m
% 如果新增参数，需要将 scaledata/ 内原有文件删除

%% 代码
clc;clear;close all;
% UAV20L UAV123 UAV123_10fps UAVDT DTB70 VisDrone2018
dataset = 'UAV20L';

% 相关文件夹
attFolder = ['./anno/' dataset '/att/'];
annoFolder = ['./anno/' dataset '/'];
xlsxFolder = './datasetAttTable/';

% 读取后namelist 的格式为
% name -- filename
% date -- modification date
% bytes -- number of bytes allocated to the file
% isdir -- 1 if name is a directory and 0 if not
namelist = dir([attFolder '*.txt']);
len = length(namelist);
dataset_num = cell(len,1);
for i = 1:len
    dataset_num{i,1}=namelist(i).name;
    dataSeq{i,1} = dataset_num{i,1}(1:end-4);
end

%% 数据集指标

% 数据集对应指标
switch dataset
    case {'UAV123_10fps', 'UAV123', 'UAV20L'}
        attName={'Scale variation' 'Aspect ratio change' 'Low resolution' 'Fast motion' 'Full occlusion' 'Partial occlusion' 'Out-of-view' 'Background clutter' 'Illumination variation' 'Viewpoint change' 'Camera motion' 'Similar object'};
        attName_abbr = {'SV','ARC','LR','FM','FOC','POC','OV','BC','IV','VC','CM','SOB'}; % 行标缩写
        attNum = 12;
    case 'UAVDT'
        attName = {'Background clutter','Camera motion','Object motion','Small object','Illumination variations','Object blur','Scale variations','Long-term tracking','Large occlusion'};
        attName_abbr = {'BC','CM','OM','SO','IV','OB','SV','LTT','LO'}; % 行标缩写
        attNum = 9;
    case 'DTB70'
        attName={'Scale variation' 'Aspect ratio variation' 'Occlusion'	'Deformation' 'Fast camera motion'	'In-plane rotation' 'Out-of-plane rotation'  'Out-of-view'	'Background clutter' 'Similar objects around' 'Motion blur'};
        attName_abbr = {'SV','ARV','OCC','DEF','FCM','IPR','OPR','OV','BC','SOA','MB'}; % 行标缩写
        attNum = 11;
    case 'VisDrone2018'
        attName = {'Aspect ratio change','Background clutter','Camera motion','Fast motion','Full occlusion','Illumination variation','Low resolution',...
               'Out-of-view','Partial occlusion','Similar object','Scale variation','Viewpoint change'};
        attName_abbr = {'ARV','BC','CM','FM','FOC','IV','LR','OV','POC','SOB','SV','VC'}; % 行标缩写
        attNum = 12;
end


% 构建参数矩阵
attMatrix = zeros(len, attNum);
frameNum = zeros(len, 1);
for i = 1:len
    % 将TXT文档load到matlab的工作区间中
    att=load([attFolder dataset_num{i}]);
    % 也可以取指定的行和列
    attMatrix(i,:) = att(1,:);%即取所有行，以及2-3列
    % 计算每个序列的长度
    gt =load([annoFolder dataset_num{i}]);
    frameNum(i) = size(gt,1);
end
fileName = [dataset '_att.xlsx'];
% 写入矩阵
% writematrix(attMatrix,fileName);
% 写入表格
% 表格抬头
% dataSeq   frameNum <指标缩写>
% 数据集     帧数     <指标全称>
T1 = table(dataSeq, frameNum);writetable(T1, [xlsxFolder fileName], 'Range','A1');
% corner [char('A'+1) '1']
for j = 1:attNum
    T = table(attMatrix(:,j));
    T.Properties.VariableNames = {attName_abbr{j}};
    writetable(T, [xlsxFolder fileName], 'Range',[char('B'+j) '1']);
end

disp('End !')