%% Estimate Stress-Coupling Length
% Rainey Aberle 2021
% Script to estimate the glacier stress-coupling length using methods 
% adapted from Enderlin et al. (2016) at Crane Glacier, Antarctic Peninsula. 
% 1. Load centerline observations of ice speed, ice thickness, glacier width
% 2. 

clear all; close all;

save_results = 0; % = 1 to save results

% Define home path
homepath = '/Users/raineyaberle/Desktop/Research/CraneModeling/CraneGlacier_flowlinemodeling/';
cd([homepath,'inputs-outputs/']);

% 1. Load centerline observations of ice speed, ice thickness, glacier width
% and define constants

    x0 = load('flowlineModelInitialization.mat').x0'; % spatial grid (m along centerline)
    hb0 = load('flowlineModelInitialization.mat').hb0'; % glacier bed elevation (m)
    h0 = load('flowlineModelInitialization.mat').h0'; % ice surface elevation (m)
    W0 = load('flowlineModelInitialization.mat').W0'; % glacier width (m)
    U0 = load('flowlineModelInitialization.mat').U0'; % ice surface speed (m/s)
    A0 = load('flowlineModelInitialization.mat').A0'; % rate factor (Pa^-n s^-1)
    c0 = load('flowlineModelInitialization.mat').c0; % calving front position
    % end variables at observed calving front location
    x0(c0+1:end)=[]; hb0(c0+1:end)=[]; h0(c0+1:end)=[]; W0(c0+1:end)=[];
    U0(c0+1:end)=[]; A0(c0+1:end)=[];
    H0 = h0-hb0; % ice thickness (m)
    
    % regrid using equal spatial resolution
    dx = 300; % grid spacing (m)
    x = 0:dx:x0(end);
    hb = interp1(x0,hb0,x);
    h = interp1(x0,h0,x);
    W = interp1(x0,W0,x);
    U = interp1(x0,U0,x);
    A = interp1(x0,A0,x);
    H = interp1(x0,H0,x);
    c = dsearchn(x',x0(c0));
    
    % Define constants
    n = 3; % flow law exponent (unitless)
    m = 1; % basal sliding exponent (unitless)
    rho_i = 917; % density of ice (kg/m^3)
    rho_sw = 1028; % ocean water density (kg m^-3)
    g = 9.81; % gravitational acceleration (m/s^2)
    E = 1; % enhancement factor (unitless)
    
    % Define averaging window
    w = [30 105]; % indices of spatial grid to use in averaging

% 2. Calculate gradients in speed and ice surface elevation 

    % fit a linear regression to speed observations
    U_lin = feval(fit(x(w(1):w(2))',U(w(1):w(2))','poly1'),x)'; % (m/s)
    
    % calculate strain rates dUdx (1/s)
    dUdx = zeros(1,length(x));
    dUdx(1) = (U(2)-U(1))./(x(2)-x(1)); % forward difference
    dUdx(2:end-1) = (U(3:end)-U(1:end-2))./(x(3:end)-x(1:end-2)); % central difference
    dUdx(end) = (U(end)-U(end-1))./(x(end)-x(end-1)); % backward difference
    % use a linear regression for dUdx
    dUdx_lin = feval(fit(x(w(1):w(2))',dUdx(w(1):w(2))','poly1'),x)'; 
    
    % fit a linear regression to ice surface elevation observations
    h_lin = feval(fit(x(w(1):w(2))',h(w(1):w(2))','poly1'),x)'; % (m/m)
    
    % calculate surface slope (unitless)
    dhdx = zeros(1,length(x));
    dhdx(1) = (h(2)-h(1))./(x(2)-x(1)); % forward difference
    dhdx(2:end-1) = (h(3:end)-h(1:end-2))./(x(3:end)-x(1:end-2)); % central difference
    dhdx(end) = (h(end)-h(end-1))./(x(end)-x(end-1)); % backward difference
    % use a linear regression for dhdx
    dhdx_lin = feval(fit(x(w(1):w(2))',dhdx(w(1):w(2))','poly1'),x)';   
    
    % plot speed, strain rates, surface, & surface slope
    figure(1); clf
    set(gcf,'position',[10 245 749 405]);    
    subplot(1,2,1);
        set(gca,'fontsize',12,'fontname','arial','linewidth',2);
        hold on; grid on; legend('Location','best');
        plot(x,U,'.k','markersize',10,'displayname','U');
        plot(x,U_lin,'--k','linewidth',2,'displayname','U_{lin}');
        ylabel('m a^{-1}'); title('Ice Surface Speed');
        yyaxis right;
        plot(x,dUdx,'.r','markersize',10,'displayname','\partialU/\partialx');
        plot(x,dUdx_lin,'--r','linewidth',2,'displayname','\partialU/\partialx_{lin}');
        xlabel('distance along centerline (km)'); ylabel('s^{-1}');
    subplot(1,2,2);
        set(gca,'fontsize',12,'fontname','arial','linewidth',2);
        hold on; grid on; legend('Location','best');
        plot(x,h,'.k','markersize',10,'displayname','h');
        plot(x,h_lin,'--k','linewidth',2,'displayname','h_{lin}');
        ylabel('m.a.s.l.'); title('Ice Surface Elevation');
        yyaxis right;
        plot(x,dhdx,'.r','markersize',10,'displayname','\partialh/\partialx');
        plot(x,dhdx_lin,'--r','linewidth',2,'displayname','\partialh/\partialx_{lin}');
        xlabel('distance along centerline (km)'); ylabel('m m^{-1}');    
    
% 3. Calculate resistive stress 
    
    % estimate effective viscosity v (Pa s)
    v = ((E.*A).^(-1/n)).*((abs(dUdx_lin)).^((1-n)/n));
    
    % calculate the effective pressure N (ice overburden pressure minus water
    % pressure) assuming an easy & open connection between the ocean and
    % ice-bed interface
    sl = find(hb<=0,1,'first'); % find where the glacier base first drops below sea level
    N_ground = rho_i*g*H(1:sl); % effective pressure where the bed is above sea level (Pa)
    N_marine = rho_i*g*H(sl+1:length(x))+(rho_sw*g*hb(sl+1:length(x))); % effective pressure where the bed is below sea level (Pa)
    N = [N_ground N_marine];
    N(N<0)=0; % cannot have negative values
    
    % calculate along-flow resistive stress as a sum of the local 
    % longitudinal stresses and basal drag
    % Td = Tlat + Tb + Tlon
    % Rxx = Tlon + Tb
    Td = rho_i*g.*H.*dhdx; % driving stress (Pa)
    Tlat = H./W.*(5.*U./(E.*A.*W)).^(1/n); % lateral resistance (Pa)
    Tlon = (2./dx.*(H.*v.*dUdx_lin)); % longitudinal resistance (Pa)
    Tb = -Td-Tlat+Tlon; % basal drag (Pa)
    Rxx = Tlon+Tb;  % (Pa) 
        Rxx(end-2:end)=Rxx(end-3);
    
    % estimate period of Rxx and H sequences
    ITRxx = find(islocalmax(Rxx)); % indices to Rxx local maxima
    T_Rxx = mean(diff(x(ITRxx))); % (m)
    ITH = find(islocalmax(H)); % indices to H local maxima
    T_H = mean(diff(x(ITH))); % (m)
    % display
    disp(['T_Rxx = ',num2str(round(T_Rxx)),' m']);
    disp(['T_H = ',num2str(round(T_H)),'m']);   
    disp(['mean(SCL:H) = ',num2str(T_Rxx/nanmean(H))]);
    
    % plot results
    figure(2); clf
    set(gcf,'position',[750 80 615 715]);        
    subplot(2,1,1);
        set(gca,'fontsize',14,'fontname','arial','linewidth',2);
        hold on; grid on; 
        plot(x/10^3,Rxx./10^3,'k','linewidth',2);
        for i=1:length(ITRxx)
            plot([x(ITRxx(i)) x(ITRxx(i))]/10^3,[min(Rxx) max(Rxx)],'-','color',[136 86 167]/255,'linewidth',1);
        end
        ylim([min(Rxx)/10^3 max(Rxx)/10^3]);
        ylabel('R_{xx} (kPa)');
    subplot(2,1,2);
        set(gca,'fontsize',14,'fontname','arial','linewidth',2);
        hold on; grid on; 
        plot(x/10^3,H,'k','linewidth',2); 
        for i=1:length(ITRxx)
            plot([x(ITRxx(i)) x(ITRxx(i))]/10^3,[-2000 2000],'-','color',[136 86 167]/255,'linewidth',1);
        end
        ylim([min(H)-100 max(H)+100]);
        xlabel('distance along centerline (km)'); ylabel('Thickness (m)'); 
        
% save resulting resistive stress, peaks, fit        
if save_results
    cd([homepath,'inputs-outputs/']);
    save('SCL_results.mat','x','Rxx','ITRxx');
    disp('results saved.');
end




    