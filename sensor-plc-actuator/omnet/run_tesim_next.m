function [tstart, tstop, xmeas_out, xmv_out] = run_tesim_next(tstart, tstep, mdlname, ts)
%
% Author: Rick Candell
% Organization: National Institute of Standards and Technology
%               U.S. Department of Commerce
% License: Public Domain

if nargin < 4
    % 1 = base
    % 2 = scan
    % 3 = save
    ts = 1/3600*ones(1,3);
end

if nargin < 3
    mdlname = 'te_plant_controller_for_omnet';  
end

if nargin < 2
    tstep = 10/3600;
end
tstop = tstart + tstep;

if nargin < 1
    error 'start time not specified.  Use the last stop time as start time'
end

% open the model        
open(mdlname);
mdl = bdroot;

% initialize model data
Ts_base = ts(1); % TODO: update the model to use Ts_base in the plant module
Ts_scan = ts(2); % TODO: update the model to use Ts_scan in the controller module
Ts_save = ts(3);
model_data_init(Ts_base, Ts_scan, Ts_save)

% run the simulation for the first time step
% set_param(mdl, 'StartTime', num2str(0));
% set_param(mdl, 'StopTime', num2str(0));
set_param(mdl, 'SaveFinalState', 'on');
set_param(mdl, 'FinalStateName', 'xFinal');
set_param(mdl, 'SaveFormat', 'Structure');
set_param(mdl, 'SaveCompleteFinalSimState', 'off');  % this is must 
set_param(mdl, 'LoadInitialState', 'on');
set_param(mdl, 'InitialState', 'xInitial');

% set new start time
set_param(mdl, 'StartTime', num2str(tstart));

% set new stop time
set_param(mdl, 'StopTime', num2str(tstop));   

% run the simulation 
% disp(['tstart: ' get_param(mdl, 'StartTime')])
% disp(['tstop: ' get_param(mdl, 'StopTime')])
simout = sim(mdl);

% save states, inputs, and outputs to file
% xFinal state
xFinal = simout.get('xFinal'); 
save('xFinal.mat','xFinal');
% xmeas_out
xmeas_out = simout.get('xmeas_out'); 
dlmwrite('xmeas_out.txt',xmeas_out,'\t');
% xmv_out
xmv_out = simout.get('xmv_out'); 
dlmwrite('xmv_out.txt',xmv_out,'\t');
%  rx_k
dlmwrite('rx_k.txt', simout.get('rx_k'), '\t');  % TODO: Verify that rx_k is saved and reloaded correctly to the right spot

end  


function model_data_init(Ts_base, Ts_scan, Ts_save)

    %  Load TEFUNC states (tesim_ic)
    load('xFinal.mat')
    assignin('base','xInitial',xFinal);
    tesim_ic = xFinal.signals(1).values; % explicitly load the plant ic's
    assignin('base','tesim_ic',tesim_ic);

    %  XMEAS input from network
    xmeas_in = dlmread('xmeas_in.txt');
    assignin('base','xmeas_in',xmeas_in);

    %  XMV input from network
    xmv_in = dlmread('xmv_in.txt');
    assignin('base','xmv_in',xmv_in);

    % TS_base is the integration step size in hours.  The simulink model
    % is using a fixed step size (Euler) method.  Variable step-size methods
    % don't work very well (high noise level).  TS_base is also the sampling
    % period of most discrete PI controllers used in the simulation.
    assignin('base','Ts_base',Ts_base);
    assignin('base','Ts_scan',Ts_scan);
    assignin('base','Ts_save',Ts_save);

    % initialize the IDV condition (disturbances)
    IDVspec = dlmread('idv.txt','\t');
    assignin('base','IDVspec',IDVspec);
    
    % controller loop initials
    xmv_in = dlmread('xmv_in.txt','\t'); 
    % load the xmv block initalization values
    for i=1:12;
        iChar=int2str(i);
        evalin('base',['xmv',iChar,'_0=xmv_in(',iChar,');']);  
    end
    assignin('base','xmv_in',xmv_in);
    
    Eadj_0=0;       assignin('base','Eadj_0',0);       % TODO: Is this being reinitd instead of state propagated?
    SP17_0=80.1;    assignin('base','SP17_0',SP17_0);  % TODO: Is this being reinitd instead of state propagated?  
    
    % load the rx_k values
%     rx_k = dlmread('rx_k.txt','\t');
%     assignin('base','r1_0',rx_k(1)); % TODO: Verify that these are correctly assigned in the model
%     assignin('base','r2_0',rx_k(2));
%     assignin('base','r3_0',rx_k(3));
%     assignin('base','r4_0',rx_k(4));
%     assignin('base','r5_0',rx_k(5));
%     assignin('base','r6_0',rx_k(6));
%     assignin('base','r7_0',rx_k(7));
    
end
