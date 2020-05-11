%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Evaluation of EQE measurement data + Urbach tail to determine the radiative open-circuit voltage, non-radiative voltage loss, and external luminescence quantum efficiency
% by: Lisa Krückemeier & Dane W. deQuilettes  
% (supplemented version of 'SCRIPT_Vocrad_EQE_fit_Urbachtail.m' by Lisa Krückemeier) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
clc
close all
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% NOTE: !!!!(input EQE data should be a two-column file (x:energy [eV] or wavelength [nm],y:EQE [in either absolute or % values]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% !!!! ENTER FILE NAME (options are .dat, .txt, .csv, .xls) and your solar cell parameters:
enter_filename='EQE_Liu_ACSEnergyLett_19_recipeB.dat';
Voc_measured = 1.262; % measured Voc of your device
PCE_measured = 20.7;  % measured PCE of the device
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% !!!! VARIABLE: ADJUST URBACH ENERGY IF NECESSARY
E_Urbach=0.0135;                        % [eV] Urbach energy (usually between 13.5 to 16 meV for metal-halide perovskites)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decide if you want to choose the EQE value for Urbach Tail attachment manually or automatically
manually='no';                          % choose 'yes' or 'no' if you want to chose the transition point manually 'yes' if a manual correction is necessary or automatically 'no'. 'no' attaches Urbach tail midway between data on logscale.
EQE_level=0.01;                         % EQE value at which the Urbach Tail should be attached (if manually 'yes').
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decide if you want to compare your Voc to a survey of literature values
comparsion_literature='yes';            % choose 'yes' or 'no'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decide if you want to clean up the workspace
clean_up='yes';                         % Decide if you want to clean up the workspace and delete unimportant variables (enter 'yes') or keep all variables (enter 'no')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONSTANTS
global VT
q=1.602176462e-19;                      % [As], elementary charge
h_Js=6.62606876e-34;                    % [Js], Planck's constant
h_eVs=4.135667662e-15;                  % [eVs], Planck's constant
k = 1.38064852e-23;                     % [(m^2)kg(s^-2)(K^-1)], Boltzmann constant
T = 300;                                % [K], temperature
VT=(k*T)/q;                             % [V], 25.8mV thermal voltage at 300K
c=299792458;                            % [m/s], speed of light c_0
vor=((h_Js*c)/q)/(1e-9);                % prefactor for converting between energy and wavelength in (eVnm)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PARAMETER
E_all=linspace(0.4,6,3000)';            % [eV], general energy axis
%E_all=linspace(0.4,6,500)';            % [eV], general energy axis
%E_all=linspace(0.4,6,300)';            % [eV], general energy axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%_______________________DATA______________________________________________
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXTERNAL QUANTUM EFFICIENCY (EQE)-DATA
% Import data from data file. The name must be manually entered above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% identifies and loads data according to file extension
        if contains(enter_filename,'csv','IgnoreCase',true) == 1  % load data for .csv
            EQEdata = readtable(enter_filename, 'HeaderLines',0);  % skips rows if necessary
            EQEdata = table2array(EQEdata);
        elseif contains(enter_filename,["txt","dat"],'IgnoreCase',true) == 1 % load data for .txt and .dat
            EQEdata=load(enter_filename); 
        elseif contains(enter_filename,'xls','IgnoreCase',true) == 1 % load data for .xls
            EQEdata = xlsread(enter_filename);
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
E_EQE_original=EQEdata(:,1);                 % x-axis, of this data set-- energy or wavelength
EQE_original=EQEdata(:,2);                   % EQE of the solar cell     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adjust data format: 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % converts the x-axis into an energy axis if it is in wavelengths before:
        if max(E_EQE_original)>10    % if data is in wavelength, convert to energy
            E_EQE_original=1240./E_EQE_original; 
            % No need for Jacobian correction because cancels out in EQE ratio
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %flips the data if necessary so that it goes from low to highenergies
        if E_EQE_original(1)>E_EQE_original(end)          % turn around if energy axis starts at high energies
            E_EQE_original=flipud(E_EQE_original);
            EQE_original=flipud(EQE_original);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % converts the EQE from % to absolut values if necessary 
        if max(EQE_original)>2    % if data is % then change to ratio
            EQE_original=EQE_original/100; 
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Transition point
    if strcmpi(manually, 'yes')
        EQE_level=EQE_level;             % EQE value for Urbach Tail attachment, manually set value
    else
        Center_logvalue = logspace(log10(min(EQE_original)), log10(max(EQE_original)), 3);
        EQE_level= Center_logvalue(2);  % EQE value for Urbach Tail attachment, irrespective of data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
            % if the max & min search goes wrong this can be used for the attachement instead: 
            % factor_auto_attachment=10;              % automatical attachment at the minimum of the EQE times factor_auto_attachment
            % EQE_level=min(EQE_original)*factor_auto_attachment;  % EQE value for Urbach Tail attachment, irrespective of data
        %%%%%%%%%%%%%%%%%%%%%%%%%%% 
    end
%% INTERPOLATION of the EQE data
E_EQE_int=linspace(E_EQE_original(1),E_EQE_original(end),500)';            % [eV],energy axis with smaller stepsize (same range as original dataset) - but higher resolution

EQE=interp1(E_EQE_original,EQE_original,E_EQE_int); %interpolation to the energy axis with smaller stepsize (same range as original dataset)
E_EQE=E_EQE_int;
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
    %OR
    %if an interpolation is not necessary
    E_EQE=E_EQE_original;
    EQE=EQE_original;
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Select band edge region of the EQE data set - range where already the exponential tail slope is apparent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot and select characteristic data points (1: start bandbap tail ,2: endbandgap tail)
select.your_fig = figure('Name','EQE-Data Selection');
select.your_axes = axes;
select.your_fig.Position = [65, 80,1250, 600]; %aligment of the size of the figure window
semilogy(E_EQE,EQE);
axis([1.4 2.5 1e-4 2]);
title({'Zoom in. Then select two points by using the data cursor and holding ALT. After selection press (almost) any key', 'Point1: Start of the Bandgap Tail','Point2: End of the Bandgap Tail' })
xlabel('energy {\it E} (eV)');
ylabel('external quantum efficiency {\it Q}_{e}');
legend('directly measured {\it Q}_{e} data','Location','southeast');
% Initialize data cursor object
selection = datacursormode(select.your_fig);
selection.SnapToDataVertex = 'on'; % Snap to our plotted data, on by default
datacursormode on;
while ~waitforbuttonpress
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Analysis of the selected points
% selected data point 1
selection_your_points = getCursorInfo(selection);
point_2_value=selection_your_points(:,1).Position; %1 because the points are saved in the reverse order in the mypoints file (1:data point2; 2:data point 1)
point_2=selection_your_points(:,1).DataIndex;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% selected data point 2
selection_your_points = getCursorInfo(selection);
point_1_value=selection_your_points(:,2).Position;
point_1=selection_your_points(:,2).DataIndex;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Definition of the Urbach tail
E_EQE_level=interp1(EQE(point_1(:,1):point_2(:,1)),E_EQE(point_1(:,1):point_2(:,1)),EQE_level); %find the energy for which EQE value equals EQE_level
prefactor=EQE_level./(exp(E_EQE_level./E_Urbach));
urbach_tail=prefactor*exp(E_all./E_Urbach); %the corresponding prefactor should be chosen so that it fits to the position of the EQE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Merge Urbach Tail (fit) and EQE-data to an extented quantum efficiency Q_e, which cover the entire energy range of interest for the calculation of J0_rad ind Voc_rad (later on used for the determination of Voc_rad)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[minValue1,pos_EQE]=min(abs(E_EQE-E_EQE_level)); %find matching position
Q_e_EQE_connection=EQE(pos_EQE);

[minValue2,pos_fit]=min(abs(E_all-E_EQE_level));
E=[E_all(1:pos_fit); E_EQE((pos_EQE+1):end)]; %combine the two energy axis for the extend, overall quantum efficiency
Q_e_PV_fit=[urbach_tail(1:(pos_fit)); EQE((pos_EQE+1):end)]; %extended, overall Q_e_PV_fit

E_int=linspace(E_all(1),E_EQE(end),1000)'; %new energy axis
Q_e_PV_fit_int=interp1(E,Q_e_PV_fit,E_int); %interpolated, extended, overall Q_e_PV_fit
%[Jsc_rad,Jo_rad,Voc_rad,FF_rad,eff_rad]=efficiency(E,Q_e_PV_fit)
[Jsc_rad,Jo_rad,Voc_rad,FF_rad,eff_rad]=efficiency(E_int,Q_e_PV_fit_int);
RESULTS_rad_limit=array2table([Jsc_rad,Jo_rad,Voc_rad,FF_rad,eff_rad],  'VariableNames', {'Jsc_rad' 'Jo_rad' 'Voc_rad' 'FF_rad' 'efficiency_rad'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BLACK BODY SPECTRUM BB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BB=(1e-4*2*pi*q^3*(E_all).^2)./(h_Js^3*c^2*(exp(E_all./VT)-1)); %black body spectrum BB (s^-1cm^-2(eV)^-1)(in photon flux!)
BB_int=interp1(E_all,BB,E_int); %same energy axis as Q_e_PV_fit
%{
    figure('Name','black body spectra','NumberTitle','off')
    semilogy(E_all,BB);
    hold on;
    semilogy(E_int,BB_int);
    xlabel('energy {\it E}(eV)');
    ylabel('photon flux (s^{-1}cm^{-2}(eV)^{-1})');
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Detailed Balance -convert combined quantum efficiency into EL emission
Q_e_EL=Q_e_PV_fit_int.*BB_int; %recalculated electroluminescence; useful to compare it to measured EL data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Voltage Loss!
NR_Voc_loss = Voc_rad-Voc_measured;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculate the external luminescence quantum efficiency Q_e_lum: 
%Q_e_LED = (100*Jo_rad*exp((q*Voc_measured)/(k*T)))/(Jsc_rad);
Q_e_LED=100*exp(-(q*NR_Voc_loss)/(k*T));   %[%] external luminescence quantum efficiency Q_e_lum, also denoted as external radiative efficiency or LED quantum efficiency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RESULTS/ SUMMARY
%RESULTS_EQE=array2table([E_EQE_original,EQE_original,E_EQE,EQE],  'VariableNames', {'energy_orignal' 'EQE_orignal' 'energy_interpolated' 'EQE_interpolated'});
%RESULTS_EQE={array2table([E_EQE_original,EQE_original],  'VariableNames', {'energy_orignal' 'EQE_orignal'}; array2table([E_EQE,EQE],  'VariableNames', {'energy_interpolated' 'EQE_interpolated'}}
RESULTS(1).original_EQE=[E_EQE_original,EQE_original];%[eV,absolut values]
RESULTS(1).interpolated_EQE=[E_EQE,EQE];              %[eV,absolut values]
RESULTS(1).fit_Urbachtail=[E_all,urbach_tail];        %[eV,absolut values]
RESULTS(1).combined_EQE=[E_int,Q_e_PV_fit_int];       %[eV,absolut values]
RESULTS(1).reproduced_EL=[E_int,Q_e_EL./max(Q_e_EL)]; %norm EL [photonflux per energy]
RESULTS(1).UrbachEnergy=[E_Urbach]; %[eV,absolut values]
RESULTS(1).radiative_Voc=[Voc_rad]; %[eV,absolut values]
RESULTS(1).external_LuminescenceQuantumEfficiency=[Q_e_LED]; %[%]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
result_original_EQE=[E_EQE_original,EQE_original];%[eV,absolut values]
result_interpolated_EQE=[E_EQE,EQE];              %[eV,absolut values]
result_fit_Urbachtail=[E_all,urbach_tail];        %[eV,absolut values]
result_combined_EQE=[E_int,Q_e_PV_fit_int];       %[eV,absolut values]
result_reproduced_EL=[E_int,Q_e_EL./max(Q_e_EL)]; %norm EL [photonflux per energy]
result_rad_limit=table2array(RESULTS_rad_limit); %radiative-limit [short-circuit current denstiy Jsc (mA/cm^2), dark current density J0 (mA/cm^2), open-circuit voltage Voc (V), fill factor FF, efficiency eff (%)]
%% PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FIGURE measured EQE
figure ('Name','measured EQE-data','Color','white')
semilogy(E_EQE,EQE,'ro-','MarkerFace','r','MarkerSize', 5);
hold on;
semilogy(E_EQE_original,EQE_original,'sb','MarkerFace','w','MarkerSize', 5);
xlabel('energy {\it E} (eV)')
ylabel('external quantum efficiency {\it Q}_{e}');
legend('EQE');
axis([1.2 4 1e-4 1]);
title('measured EQE-data');
legend('measured {\it Q}_{e} (interpolated data set)','measured {\it Q}_{e} (original data set)','Location','southeast');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FIGURE combine EQE-data and Urbach tail
figure ('Name','combine EQE-data and Urbach tail','Color','white')
set(gcf,'units','normalized','position',[0.1 0.15 0.8 0.7])
subplot(1,2,1);
semilogy(E_EQE,EQE, 'ro','MarkerFace','r','MarkerSize', 8);
hold on;
semilogy(E_all,urbach_tail,'k','LineWidth',3);
hold on;
semilogy(E, Q_e_PV_fit, 'bo-','MarkerFace','w','MarkerSize', 5);
hold on;
semilogy(E_all(pos_fit),urbach_tail(pos_fit),'sm','MarkerFace',[1, 1, 1],'MarkerSize', 8);
xlabel('energy {\it E} (eV)');
title('combine EQE-data and Urbach tail');
legend('measured {\it Q}_{e} data','Urbach tail','combined quantum efficiency {\it Q}_{e}^{PV,fit}', 'transition point','Location','southeast');
axis([1.4 3 1e-5 1]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(1,2,2);
semilogy(E_EQE,EQE, 'ro','MarkerFace','r','MarkerSize', 8);
hold on;
semilogy(E_all,urbach_tail,'k','LineWidth',3);
hold on;
semilogy(E, Q_e_PV_fit, 'bo-','MarkerFace','w','MarkerSize', 5);
hold on;
semilogy(E_all(pos_fit),urbach_tail(pos_fit),'sm','MarkerFace',[1, 1, 1],'MarkerSize', 8);
xlabel('energy {\it E} (eV)');
title('Zoom: combine EQE-data and Urbach tail');
legend('measured {\it Q}_{e} data','Urbach tail','combined quantum efficiency {\it Q}_{e}^{PV,fit}', 'transition point','Location','southeast');
axis([1.4 1.7 1e-5 1]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FIGURE combine EQE-data and EL
figure ('Name','combined quantum efficiency and associated EL spectrum','Color','white')
set(gcf,'units','normalized','position',[0.1 0.15 0.8 0.7])
subplot(1,2,1);
semilogy(E_int,Q_e_EL./max(Q_e_EL),'r*-',  'MarkerSize', 5);
hold on;
semilogy(E_int, Q_e_PV_fit_int, 'co','MarkerFace','c','MarkerSize', 5);
hold on;
semilogy(E, Q_e_PV_fit, 'bo-','MarkerFace','w','MarkerSize', 7);
xlabel('energy {\it E} (eV)');
title('combined quantum efficiency');
legend('recalculated EL spectrum','combined quantum efficiency {\it Q}_{e}^{PV,fit} (interpolated)','combined quantum efficiency {\it Q}_{e}^{PV,fit}','Location','southeast');
axis([1.2 2 1e-4 1]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(1,2,2);
plot(E_int,Q_e_EL./max(Q_e_EL),'r*-',  'MarkerSize', 5);
hold on;
plot(E_int, Q_e_PV_fit_int, 'co','MarkerFace','c','MarkerSize', 5);
hold on;
plot(E, Q_e_PV_fit, 'bo-','MarkerFace','w','MarkerSize', 7);
xlabel('energy {\it E} (eV)');
title('combined quantum efficiency (linear scale)');
legend('recalculated EL spectrum','combined quantum efficiency {\it Q}_{e}^{PV,fit} (interpolated)','combined quantum efficiency {\it Q}_{e}^{PV,fit}','Location','southeast');
axis([1.2 2 1e-4 1]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LITERATUR SURVEY & COMPARSION
% Load data bank containing non-radiave voltage loss for other pioneering device work
    if strcmpi(comparsion_literature, 'yes')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        LitSurvey = xlsread('LiteratureSurvey.xlsx', 'A3:L33'); % load data bank
        PCE_LitSurvey = LitSurvey(:,7);  % power conversion efficiencys (%)
        Q_e_LED_LitSurvey = LitSurvey(:,4);
        NR_Voc_Loss_LitSurvey = LitSurvey(:,2);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        figure ('Name','PCE vs. ERE and NR Voc Loss','Color','white');
        set(gcf,'units','normalized','position',[0.1 0.15 0.8 0.7])
        semilogx(Q_e_LED_LitSurvey,PCE_LitSurvey,'sb','MarkerFace','w','MarkerSize', 10,'LineWidth', 3);
        hold on
        txt = {['Your data! {\it\Delta V}_{OC}^{NR} (V)= ',num2str(NR_Voc_loss),'V \rightarrow']};
        text(Q_e_LED,PCE_measured,txt,'HorizontalAlignment','right','BackgroundColor', 'w', 'EdgeColor', 'k')
        plot(Q_e_LED,PCE_measured,'ro','MarkerSize', 10, 'LineWidth', 3);
        xlabel('{\it Q}_{e,LED}^{calc} (%)');
        ylabel('power conversion efficiency PCE (%)');
        set(gca,'box','off')
        ax1 = gca;
        ax1_pos = ax1.Position;
        ax2 = axes('Position',ax1_pos,...
            'XAxisLocation','top',...
            'YAxisLocation','left',...
            'Color','none',...
            'YColor', 'none');
        hold on;
        plot(ax2,-NR_Voc_Loss_LitSurvey,PCE_LitSurvey,'wo','MarkerSize', 1e-3);
        ax1.YLim = max(ax1.YLim, ax2.YLim); 
        xlabel('non-radiative voltage losses -{\it\Delta V}_{OC}^{NR} (V)');
        dim = [.375 .6 .3 .3]; %four-element vector of the form [x y w h]
        str = 'Your Results Compared to the Literature';
        a = annotation('textbox',dim,'String',str,'FitBoxToText','on');
        a.Color = 'red';
        a.FontSize = 14;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        figure ('Name','Voc losses','Color','white');
        set(gcf,'units','normalized','position',[0.1 0.15 0.8 0.7])
%         Eg = 1.6; % Need to populate this value with Eg determined from tauc EQE or EQE_ip
%         bar(Eg);
        hold on;
        bar(Voc_rad);
        bar(Voc_measured);
        txt = {['\downarrow {\it\Delta V}_{OC}^{NR} = ',num2str(NR_Voc_loss),'V \downarrow']};
        text(0.85,(Voc_rad+Voc_measured)/2,txt, 'color', 'w', 'fontweight', 'bold')
        legend(['{\it V}_{OC}^{rad} = ',num2str(Voc_rad),' V'], ['{\it V}_{OC} = ', num2str(Voc_measured), ' V'])
%         legend(['Bandgap = ',num2str(Eg),' eV'],['{\it V}_{OC}^{rad} = ',num2str(Voc_rad),' V'], ['{\it V}_{OC} = ', num2str(Voc_measured), ' V'])
        ylabel('photovoltage (V)');
        title('open-circuit voltage losses');
        ylim([0 Voc_rad*1.2]);
        xticks([])
    else 
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SAVE
save('RESULTS.mat', 'RESULTS');
save('RESULTS_rad_limit.mat', 'RESULTS');
%save the important variables again separately; (these variables are maybe need for data analysis in Origin or another plot programm)
save -ascii original_EQE.dat result_original_EQE          %[eV,absolut values]
save -ascii interpolated_EQE.dat result_interpolated_EQE  %[eV,absolut values]
save -ascii combined_EQE.dat result_combined_EQE          %[eV,absolut values]
save -ascii Urbachtail.dat result_fit_Urbachtail          %[eV,absolut values]
save -ascii reproduced_EL.dat result_reproduced_EL        %norm EL [eV, norm. photonflux ~ a.u.(s^{-1}cm^{-2}(eV)^{-1})]
save -ascii raditive_limit.dat result_rad_limit  %radiative-limit [short-circuit current denstiy Jsc (mA/cm^2), dark current density J0 (mA/cm^2), open-circuit voltage Voc (V), fill factor FF, efficiency eff (%)]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% clean up (clear unimportant and auxiliary variables) - CLEAR -(optional)
if strcmpi(clean_up, 'yes')
    %unimportant at all:
    clear q c h h_eVs h_Js vor VT k T Jsc_rad Jo_rad FF_rad eff_rad
    clear E E_EQE_int E_int minValue1 minValue2
    clear BB BB_int cursorobj pos_EQE pos_fit
    clear point_1 point_2 point_1_value point_2_value prefactor result_rad_limit
    clear a ax1 ax1_pos ax2 dim str manually clean_up comparsion_literature txt
    %maybe important:
    clear Q_e_PV_fit Q_e_PV_fit_int Q_e_EL EQEdata E_EQE_original EQE_original E_EQE EQE E_all urbachtail
    clear Center_logvalue select selection
end