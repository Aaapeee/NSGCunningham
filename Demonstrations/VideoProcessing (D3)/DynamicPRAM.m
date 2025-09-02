function DynamicPRAM(MovieDirectory,Moviename)  
% e.g.: DynamicPRAM('D:\PhD Study\Projects\AutoPRAM\DynamicCount\MATLAB\','100aM-05232023182141-0000.mp4'); 

interval = 2;                           % sampling frame interval

%% Movie to images
obj = VideoReader(Moviename);
numFrames = obj.NumFrames;              % Total of frames
endframe = 10;                           % default: numFrames. % endFrame/interval is the number of frames will be processed
for k = 1:interval:endframe             % imput data 
     frame = read(obj,k);
     imwrite(frame,strcat(MovieDirectory, num2str(1+(k-1)/interval),'.png'),'png');    % save image
 end

%% Differentiation - save differential images
step = 1; 
samp = 1:step:endframe/interval-step;
npc = zeros(length(samp),1);
mkdir diffpro

for idx = 1:length(samp)
    raw1 = imread([strcat(MovieDirectory,num2str(0+(idx-1)*step+1)) '.png']);
    raw2 = imread([strcat(MovieDirectory,num2str(0+(idx)*step+1)) '.png']);
    dpro = double(raw2)./double(raw1);

    figure;
    a = imshow(dpro(:,:,1),[],'border','tight');
    saveas(gcf,[strcat(MovieDirectory,'\diffpro\',num2str(0+(idx-1)*step+1), 'dp') '.png'],'png')
end

%% differential image processing and counting
pixel_tolerance = 10;
npc_d = zeros(length(samp),1);
npc_b = zeros(length(samp),1);
npc = zeros(length(samp)+1,1);
Thre_d = 25E-2;         % threshold for dark spots couting
Thre_b = 25E-2;         % threshold for bright spots counting
[npc(1,1), ~] = PRAM_NPCountONLY_T_F_C_MSER([MovieDirectory '1']);
M_d = 50;               % Manual deviation in case some particles have more counts
direct = strcat(MovieDirectory,'\diffpro\');
[npc_d(1),ct_1d] =  DiffCountONLY_R_O_MSER(strcat(direct,num2str(1),'dp'),Thre_d);
[npc_b(1),ct_1b] =  DiffCountONLY_R_O_MSERb(strcat(direct,num2str(1),'dp'),Thre_b);

n_dis = 0;
if ct_1d(1) > 0 && ct_1b(1) > 0
    for id = 1: length(ct_1b(:,1))
        id_dis = find(sqrt((ct_1d(:,2)-ct_1b(id,2)).^2+(ct_1d(:,1)-ct_1b(id,1)).^2)<pixel_tolerance);
        if id_dis
            n_dis = n_dis+length(id_dis);
        end
    end
    npc_b(1) = npc_b(1) - n_dis;
    npc_d(1) = npc_d(1) - n_dis;
end

counter=1;
h = waitbar(0,'Calculating...');

for i = 2:length(samp)
    [npc_d(i),ct_id] =  DiffCountONLY_R_O_MSER(strcat(direct,num2str(0+(i-1)*step+1),'dp'),Thre_d);
    [npc_b(i),ct_ib] =  DiffCountONLY_R_O_MSERb(strcat(direct,num2str(0+(i-1)*step+1),'dp'),Thre_b);
    n_dis = 0;
    %% remove wiggling NP within 'pixel_tolerance'
    if ct_id(1) > 0 && ct_ib(1) > 0
        for id = 1:length(ct_ib(:,1))
            id_dis = find(sqrt((ct_id(:,2)-ct_ib(id,2)).^2+(ct_id(:,1)-ct_ib(id,1)).^2)<0.2*pixel_tolerance);
            if id_dis
                n_dis = n_dis+length(id_dis);
            end
        end
        npc_b(i) = npc_b(i) - n_dis;
        npc_d(i) = npc_d(i) - n_dis;
    end
    %% remove dark and bright non-specific binding and unbinding
    if i ~=length(samp)
        [~,ct_2d] =  DiffCountONLY_R_O_MSER(strcat(direct,num2str(0+i*step+1),'dp'),Thre_d);
        [~,ct_2b] =  DiffCountONLY_R_O_MSERb(strcat(direct,num2str(0+i*step+1),'dp'),Thre_b);
        n_nsb = 0;
        n_nsub = 0;
        % remove dark
        if ct_id(1) > 0 && ct_1d(1) > 0
            for id = 1:length(ct_id(:,1))
                id_dis1 = find(sqrt((ct_id(id,2)-ct_1d(:,2)).^2+(ct_id(id,1)-ct_1d(:,1)).^2)<0.1*pixel_tolerance);
                if ~id_dis1
                    id_dis2 = find(sqrt((ct_id(id,2)-ct_2d(:,2)).^2+(ct_id(id,1)-ct_2d(:,1)).^2)<0.1*pixel_tolerance);
                    if ~id_dis2
                        n_nsb = n_nsb + 1;
                    end
                end
            end
            npc_b(i) = npc_b(i) - n_nsb;
            npc_d(i) = npc_d(i) - n_nsb;
        end
        % remove bright
        if ct_ib(1) > 0 && ct_1b(1) > 0
            for id = 1:length(ct_ib(:,1))
                id_dis1 = find(sqrt((ct_ib(id,2)-ct_1b(:,2)).^2+(ct_ib(id,1)-ct_1b(:,1)).^2)<0.1*pixel_tolerance);
                if ~id_dis1
                    id_dis2 = find(sqrt((ct_ib(id,2)-ct_2b(:,2)).^2+(ct_ib(id,1)-ct_2b(:,1)).^2)<0.1*pixel_tolerance);
                    if ~id_dis2
                        n_nsub = n_nsub + 1;
                    end
                end
            end
            npc_b(i) = npc_b(i) - n_nsub;
            npc_d(i) = npc_d(i) - n_nsub;
        end
        if (i>length(samp)/20*counter)
            waitbar(i/length(samp),h);
            counter=counter+1;
        end
    end
end  

close(h);
        
close all
%% Data visualization
figure;
binding = zeros(length(samp)-1,1);
debinding = zeros(length(samp)-1,1);

binding(1) = npc_d(1);
for i = 1:length(npc_d)-1
    binding(i+1) = npc_d(i+1)+binding(i);
end

debinding(1) = npc_b(1);
for i = 1:length(npc_b)-1
    debinding(i+1) = npc_b(i+1)+debinding(i);
end
npc(2:end) = npc(1,1) + binding -debinding; 

plot(1*interval:interval:length(binding)*interval,binding/0.092785,'LineWidth',3,'LineStyle','-.')
hold on;
plot(1*interval:interval:length(debinding)*interval,debinding/0.092785,'LineStyle','--','LineWidth',3)
plot(0*interval:interval:length(samp)*interval,npc/0.092785,'LineStyle','-','LineWidth',3)
xlabel('Time/s','FontSize',16);
ylabel('Count/mm^2','FontSize',16);
legend('Binding','Unbinding','NP Accumulation');
set(gca,'fontsize',16);
save('Data');