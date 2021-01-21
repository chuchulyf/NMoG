% Demo on non_i.i.d. Gaussian + deadline Noise
clear,clc
currentFolder = pwd;
addpath(genpath(currentFolder))
load('pure_DCmall.mat');
[M,N,B] = size(Ori_H);

muOn = 0;                     % muOn = 0: set mu as 0 without updating;
                              % muOn = 1: update mu in each iteration.
Rank = 5;                     % objective rank of low rank component
param.initial_rank = 30;      % initial rank of low rank component
param.rankDeRate = 7;         % the number of rank reduced in each iteration
param.mog_k = 3;              % the number of component reduced in each band
param.lr_init = 'SVD';
param.maxiter = 30;
param.tol = 1e-4;
param.display = 1;
[prior, model] = InitialPara(param,muOn,B);        % set hyperparameters and initialize model parameters

temph = reshape(Ori_H,M*N,B);
sigma_signal = sum(temph.^2)/(M*N);
for num = 1:2
    % add noise
    SNR = 10 + rand(1,B)*10;
    SNR1 = 10.^(SNR./10);
    sigma_noi = sigma_signal./SNR1;
    for i=1:B
        Noi_H(:,:,i) = Ori_H(:,:,i) + randn(M,N)*sqrt(sigma_noi(i));
    end
    band = ceil((B-20)*rand(1,40)+10);                  % bands chose to add deadline noise
    deadlinenum = 5+ceil(10*rand(1,length(band)));     % number of deadline in these bands
    for i=1:length(band)
        loc = ceil(N*rand(1,deadlinenum(i)));
        Noi_H(:,loc,band(i)) = 0;
    end
    
    Y = reshape(Noi_H,M*N,B);
    tic
    [Model,Lr_model] = NMoG_RPCA(Y,Rank,param,model,prior);
    time(num) = toc;
    U = Lr_model.U;
    V = Lr_model.V;
    Denoi_HSI = reshape(U*V',size(Ori_H));
    [PSNR(:,num),MPSNR(num),SSIM(:,num),MSSIM(num)] = zhibiao(Ori_H,Denoi_HSI);
end

disp('*********************** DC_NGaussian_deadline ************************'); 
meanPSNR = mean(MPSNR);
varPSNR = var(MPSNR);
meanSSIM = mean(MSSIM);
varSSIM = var(MSSIM);
Time = mean(time);
vTime = var(time);
disp(['meanMPSNR:',num2str(meanPSNR),'   varMPSNR:',num2str(varPSNR),'   meanMSSIM:',num2str(meanSSIM),...
    '   varMSSIM:',num2str(varSSIM),'   meantime:',num2str(Time),'   vartime:',num2str(vTime)]);

