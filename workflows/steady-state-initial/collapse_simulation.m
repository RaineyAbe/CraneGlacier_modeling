%% Glacier flowline model: script to simulate glacier response to ice shelf collapse
% Rainey Aberle 
% Spring 2022
% 
%   0. Load initial model parameters
%   1. Model pre-collapse steady-state conditions
%   2. Model ice shelf collapse
%   3. Conduct sensitivity tests

%% 0. Load initial model parameters  

clear all; close all;
warning off; % turn off warnings (velocity coefficient matrix is close to singular)
    
% define home path in directory and add necessary paths
homepath = '/Users/raineyaberle/Research/MS/CraneGlacier_flowlinemodeling/';
addpath([homepath,'workflows/'],...
    [homepath,'workflows/2_steady-state/'],...
    [homepath,'functions/cmocean_v2.0/cmocean'],...
    [homepath,'inputs-outputs/']);

% -----load initialization file
load([homepath,'inputs-outputs/modelInitialization_preCollapse.mat']);
SMR_mean_fit = load('LarsenC_MeanMeltRate.mat').mr_mean_fit;

% -----time stepping [s]-----
dt = 0.01*3.1536e7;

% -----densities and g-----
rho_i = 917; % ice density (kg m^-3)
rho_sw = 1028; % ocean water density (kg m^-3)
rho_fw = 1000; % fresh water density (kg m^-3)
g = 9.81; % acceleration (m s^-2)

% -----stress parameters (unitless)-----
m = 3; % basal sliding exponent
n = 3; % flow law exponent
E = 1; % enhancement factor

% -----calving parameters-----
DFW0 = 0; % fresh water depth in crevasses [m]

% -----instability checks (using thickness and speed)
H_max = 2000; % maximum thickness (m)
H_min = 100;  % minimum thickness (m)
U_min = 100./3.1536e7;  % minimum mean speed (m s^-1)
    
% -----initial conditions-----
dx0 = mean(x0(2:end)-x0(1:end-1));
H0 = h0-b0; % ice thickness (m)
dUdx0 = [(U0(2:end)-U0(1:end-1))./(x0(2:end)-x0(1:end-1)) 0]; % strain rate (1/s) %%EE: flipped this to be consistent w/ other computations 15/09/21
% find the location of the grounding line and the end of the ice-covered domain
Hf = -(rho_sw./rho_i).*b0; % flotation thickness (m)
gl0 = find(Hf-H0>0,1,'first')-1; % grounding line location 
if isempty(gl0)
    % set grounding line to calving front location if all ice is grounded
    gl0=c0; 
else
    % adjust thickness for flotation
    H0(gl0+1:length(x0))=h0(gl0+1:end)*rho_sw/(rho_sw-rho_i); % buoyant thickness using surface
    H0(H0>=(h0-b0))=h0(H0>=(h0-b0))-b0(H0>=(h0-b0)); % thickness can't go beneath bed elevation
    H0(c0+1:end) = 0; % zero ice thickness past calving front 
end

%% 1. Model pre-collapse steady-state conditions

saveFinal = 0; % = 1 to save variables once steady-state is reached
plotTimeSteps = 1; % = 1 to plot geometry, speed, cf/gl positions every dt*500

% -----initialize parameters-----
x=x0; U=U0; W=W0; gl=gl0; dUdx=dUdx0; A=A0; h=h0; b=b0; H=H0; 
DFW=DFW0; dx=dx0; c=c0; SMB=SMB0; SMR=SMR0; 
beta0 = interp1([0 x0(end)], [1 2], x0); % beta = beta0; 
sigma_b = 350e3; %sigma_b0;

% -----run flowline model-----
i=1; % counter for iterations
while i

    % -----establish time
    t(i) = (i-1)*dt; % [s]

    % -----calving front location 
    c = c; % constant until steady-state is achieved
    xcf = x(c); % calving front location [m]

    % -----grounding line location
    % calculate the thickness required to remain grounded at each grid cell
    Hf = -(rho_sw./rho_i).*b; % flotation thickness (m)
    % find the location of the grounding line and use a floating
    % geometry from the grounding line to the calving front
    if ~isempty(find(Hf-H>0,1,'first'))
        if length(Hf)>=find(Hf-H>0,1,'first')+1
            xgl = interp1(Hf(find(Hf-H>0,1,'first')-1:find(Hf-H>0,1,'first')+1)...
                -H(find(Hf-H>0,1,'first')-1:find(Hf-H>0,1,'first')+1),...
                x(find(Hf-H>0,1,'first')-1:find(Hf-H>0,1,'first')+1),0,'linear','extrap'); % (m along centerline)
        else
            xgl = x(find(Hf-H>0,1,'first')-1);
        end
    else
        xgl=xcf;
    end
    if xgl>xcf % grounding line can't be past calving front
        xgl=xcf;
    end

    % -----create coordinate system that hits cf and gl exactly
    % has resolution dxmax near the ice divide
    % has resolution dxmin from gl to c
    % and has smooth variation between
    xl = round(xgl/dx0); % number of ideal grid spaces needed to reach the grounding line
    dx = xgl/xl; % new grid spacing (should be ~dx0)
    xn = 0:dx:xgl; % new distance vector
    if xcf-xgl > 0
        xl = round((xcf-xgl)/dx0);
        dx = (xcf-xgl)/xl;
        xn = [xn xn(end)+dx:dx:xcf];
    end
    clear dx; dxn = [xn(2:end)-xn(1:end-1) xn(end)-xn(end-1)];

    % -----get geometry on new coordinates
    c = length(xn);
    H = interp1(x,H,xn,'linear','extrap');
    % H gradient
    dHdx(1) = (H(2)-H(1))/(xn(2)-xn(1)); % forward difference
    dHdx(2:c-1) = (H(3:c)-H(1:c-2))./(xn(3:c)-xn(1:c-2)); % central difference
    dHdx(c) = (H(c)-H(c-1))./(xn(c)-xn(c-1)); % backward difference            
    % if there is a sudden jump in H (large gradient) past the grounding
    % line, set that to the previous point
    % thickness gradient
    if any(dHdx>50)
        c = find(dHdx>50,1,'first')-1;            
        H = H(1:c);
        xn = xn(1:c);
    end
    gl = dsearchn(xn',xgl); % indices for xcf and xgl
    b = interp1(x0,b0,xn,'linear','extrap');
    W = interp1(x0,W0,xn,'linear','extrap');
    U = interp1(x,U,xn,'linear','extrap');
    A = interp1(x0,A0,xn,'linear','extrap');
    beta = interp1(x0,beta0,xn,'linear','extrap');
    x = xn; dx = dxn; clear xn dxn; %EE: added the clear statement 14/09/21
    XGL(i) = xgl; % save grounding line position over time

    % -----calculate surface elevation
    h = b+H; % surface elevation (m a.s.l.)
    h(gl+1:c) = (1-rho_i/rho_sw).*H(gl+1:c); % adjust the surface elevation of ungrounded ice to account for buoyancy
    H(h<0)=0-b(h<0); h(h<0)=0; % surface cannot go below sea level
    h(h-H<b) = b(h-H<b)+H(h-H<b); % thickness cannot go beneath bed elevation

    % -----plot geometry, speed, & grounding line and calving front positions
    col = parula(50e3); % color scheme for plots
    if plotTimeSteps
        if i==1
            drawnow
            figure(1); clf
            set(gcf,'Position',[0 100 1300 450]);
            ax1 = axes('Position',[0.05 0.12 0.27 0.78]); % glacier geometry
            hold on; grid on;
            set(gca,'FontSize',16,'linewidth',2);
            title([num2str(t(i)*3.1536e7), 'yrs']);
            xlim([0 95]); ylim([min(b)-100 max(h)+200]);
            xlabel('Distance Along Centerline [km]'); ylabel('Elevation [m]');
            % ice surface
            plot(x(1:c)./10^3,h(1:c),'color',col(i,:),'linewidth',2,'displayname','2009');
            % calving front
            plot(x(c)*[1,1]/10^3,[h(c)-H(c),h(c)],'.-','color',col(i,:),'linewidth',2,'HandleVisibility','off');
            % floating bed
            plot(x(gl:c)/10^3,h(gl:c)-H(gl:c),'color',col(i,:),'linewidth',2,'HandleVisibility','off');
            % bed elevation
            plot(x0./10^3,b0,'k','linewidth',2,'HandleVisibility','off');
            % mean sea level
            plot([x(1),x(end)]/10^3,[0,0],'k--','HandleVisibility','off');
            % ice speed
            ax2 = axes('Position',[0.37 0.1 0.28 0.8]);
            hold on; grid on;
            set(gca,'FontSize',14,'linewidth',2);
            xlim([0 95]); 
%                     ylim([0 800]);
            xlabel('Distance Along Centerline [km]'); ylabel('Speed [m a^{-1}]');
            plot(x(1:c)./10^3,U(1:c).*3.1536e7,'color',col(i,:),'linewidth',2,'displayname','2009');
            % calving front & grounding line positions
            ax3 = axes('Position',[0.7 0.1 0.28 0.8]); 
            hold on; grid on;
            set(gca,'FontSize',14,'linewidth',2);
            xlim([30 95]);
            xlabel('Distance Along Centerline [km]'); 
            ylabel('Year');
            plot(x(c)/10^3,t(i)./3.1536e7,'.','markersize',15,'color',col(i,:),'displayname','2009');
            plot(ax3,x(gl)./10^3,t(i)./3.1536e7,'x','Color',col(i,:),'markersize',10,'linewidth',2,'HandleVisibility','off');
        elseif mod(t(i),dt*200)==0 % display every dt*200
            figure(1);
            % glacier geometry
            plot(ax1,x(1:c)/10^3,h(1:c),'-','color',col(i,:),'linewidth',2,'displayname',num2str(round(t(i)./3.1536e7)+2009));
            plot(ax1,x(gl:c)/10^3,h(gl:c)-H(gl:c),'-','color',col(i,:),'linewidth',2,'HandleVisibility','off');
            plot(ax1,[x(c);x(c)]/10^3,[h(c);h(c)-H(c)],'-','color',col(i,:),'linewidth',2,'HandleVisibility','off');
            title(ax1, [num2str(t(i)/3.1536e7), 'yrs']);
            plot(ax1,x(c)*[1,1]/10^3,[h(c)-H(c),h(c)],'.-','color',col(i,:),'linewidth',2,'HandleVisibility','off'); % calving front
            plot(ax1,x(gl:c)/10^3,h(gl:c)-H(gl:c),'color',col(i,:),'linewidth',2,'HandleVisibility','off'); % floating bed (gl:c)
            % ice speed
            plot(ax2,x(1:c)/10^3,U(1:c).*3.1536e7,'-','Color',col(i,:),'linewidth',2,'DisplayName',num2str(round(t(i)./3.1536e7)+2009));
            % calving front & grounding line positions
            plot(ax3,x(c)/10^3,t(i)/3.1536e7,'.','Color',col(i,:),'markersize',15,'displayname',num2str(round(t(i)./3.1536e7)+2009)); hold on;
            plot(ax3,x(gl)/10^3,t(i)/3.1536e7,'x','Color',col(i,:),'markersize',10,'linewidth',2,'HandleVisibility','off'); hold on;
        end    
    end

    % -----calculate the effective pressure 
    % (ice overburden pressure minus water pressure) assuming an easy & 
    % open connection between the ocean and ice-bed interface
    sl = find(b<=0,1,'first'); % find where the glacier base first drops below sea level
    N_ground = rho_i*g*H(1:sl); % effective pressure where the bed is above sea level (Pa)
    N_marine = rho_i*g*H(sl+1:length(x))+(rho_sw*g*b(sl+1:length(x))); % effective pressure where the bed is below sea level (Pa)
    N = [N_ground N_marine];
    N(N<0)=0; % cannot have negative values

    % -----solve for new velocity
    [U,dUdx] = U_convergence(x,U,H,h,A,E,N,W,dx,c,n,m,beta,rho_i,rho_sw,g,sigma_b);

    % -----calculate ice flux
    F = U.*H.*W; % ice flux (m^3 s^-1)
    F(isnan(F))=0;
    F(1)=F(2);

    % -----save grounding line oce flux (discharge)
    Fgl(i) = F(gl)*917*1e-12*3.1536e7; % Gt/a

    % -----implement SMB, SMR, & RO
    SMB = interp1(x0,SMB0+Q0/2,x);
%         SMB = interp1(x0, SMB0, x);
    RO = interp1(x0,RO0,x);
    delta_mdot = 0; % m/s
    SMR = zeros(1,c);
    % use the Larsen C mean melt rate profile to scale SMR
    % using the max initial SMR
    if gl<c
        SMR(gl+1:c) = (SMR0+delta_mdot)/(SMR_mean_fit.a+1)*feval(SMR_mean_fit,x(gl+1:c)-x(gl+1)); 
    end

    % -----calculate the  change in ice thickness from continuity
    clearvars dHdt
    dHdt(1) = (-1/W(1))*(F(1)-F(2))/(x(1)-x(2)); % forward difference
    dHdt(2:c-1) = (-1./W(2:c-1)).*(F(1:c-2)-F(3:c))./(x(1:c-2)-x(3:c)); % central difference
    dHdt(c:length(x)) = (-1./W(c:length(x))).*(F(c-1:length(x)-1)-F(c:length(x)))./(x(c-1:length(x)-1)-x(c:length(x))); % backward difference
    dH = dHdt.*dt;

    % -----new thickness (change from dynamics, SMB, & SMR)
    Hn = H+dH+(SMB.*dt)+(SMR.*dt)-(interp1(x0,RO0,x)*dt);
    Hn(Hn < 0) = 0; % remove negative values

    % -----stop the model if it behaves unstably (monitored by ice thickness and speed)
    if max(H) > H_max
        disp(['Adjust dt']);
        break;
    end
    if mean(U) < U_min
        disp('Too slow!');
        break;
    end
    if any(~isfinite(H(1:c))) || any(~isfinite(U(1:c))) || any(~isfinite(h(1:c)))
        disp('non finite values');
        break;
    end

    % -----stop model if stead-state conditions reached
    % (change in U at each point is less than set threshold) 
    if all(abs(H-Hn) < 0.00005*abs(H))
        disp('steady-state conditions achieved'); 
        break;
    else
        H = Hn; 
    end

    % -----continue loop
    i=i+1;
end

% -----save
if saveFinal
    save([homepath,'inputs-outputs/steady_state_conditions.mat'],'x', 'h', 'b', 'H',...
        'U', 'W', 'A', 'beta', 'gl', 'c', 'sigma_b', 'SMB', 'SMR', 'DFW');
    disp('steady-state conditions saved');
end

%% 2. Model ice shelf collapse

plotTimeSteps = 1; % = 1 to plot geometry, speed, cf/gl positions every dt*500
  
% -----load steady-state conditions-----
% load([homepath,'inputs-outputs/steady_state_conditions.mat']);

% -----time stepping [s]-----
t_start = 0*3.1536e7;
t_end = 100*3.1536e7; 
t = [t_start:dt:t_end];

% -----remove backstress-----
sigma_b = sigma_b;% - 100e3; % Pa 

% -----run flowline model-----
for i=1:length(t)
    
    % -----calving front location 
    % find the calving front location (based on Benn et al., 2007 & Nick et al., 2010)
    if i==1 % use observed calving front position for first iteration
        c=c0;
        xcf = x0(c0);
    else
        % to allow for advance, extrapolate U, dUdx, h, b, and H past the calving front
        U_cf = interp1(x(1:c),U(1:c),x0,'linear','extrap');
        dUdx_cf(1) = (U_cf(2)-U_cf(1))/(x0(2)-x0(1)); % forward difference at upper boundary
        dUdx_cf(2:length(x0)-1) = (U_cf(3:length(x0))-U_cf(1:length(x0)-2))...
            /(x0(3:length(x0))-x0(1:length(x0)-2)); % central difference
        dUdx_cf(length(x0)) = (U_cf(length(x0))-U_cf(length(x0)-1))/(x0(end)-x0(end-1)); % backward difference at end
        h_cf = interp1(x(1:c),h(1:c),x0,'linear','extrap');
            h_cf(c-50:end) = feval(fit(x0(c-50:c)',h(c-50:c)','poly1'),x0(c-50:end))';
        H_cf = interp1(x(1:c),H(1:c),x0,'linear','extrap');  
        % height above buoyancy (m)
        Hab = H_cf+rho_sw/rho_i*(b0); 
        % resistive stress (Pa)
        Rxx = 2*nthroot(dUdx_cf./(E.*A0),n);  
        
        % -----surface crevasses
        % surface crevasse penetration depth (m)
        crev_s = (Rxx./(rho_i.*g))+((rho_fw./rho_i).*(DFW)); 
        % calving front located where the inland-most crevasse intersects sea level  
        Icf_s = find(h_cf-crev_s<0, 1, 'first'); % index
%         if isempty(Icf_s)
%             Icf_s = find(h_cf-crev_s<15, 1, 'first'); % index
%         end
        if isempty(Icf_s)
            Icf_s = c;
        end
%         xcf_s = x0(Icf);
        xcf_s = interp1(h_cf(Icf_s-1:Icf_s+1) - crev_s(Icf_s-1:Icf_s+1),...
            x0(Icf_s-1:Icf_s+1),0,'linear','extrap'); % (m along centerline)   
        
        % -----basal crevasses
        % basal crevasse penetration depth (m)
        crev_b = rho_i/(rho_sw-rho_i).*(Rxx./(rho_i*g)-Hab);     
        Icf_b = find(h_cf-crev_b < 0, 1, 'first');
        if isempty(Icf_b)
            Icf_b = find(h_cf-crev_b < 10, 1, 'first');
        end
%         xcf_b = x0(Icf_b);
        xcf_b = interp1(h_cf(Icf_b-1:Icf_b+1) - crev_b(Icf_b-1:Icf_b+1),...
            x0(Icf_b-1:Icf_b+1),0,'linear','extrap'); % (m along centerline)
        
        % -----calving front located where the inland-most crevasse intersects sea level
        if xcf_s<xcf_b
            xcf = xcf_s;
        else
            xcf = xcf_b;
        end
        xcf=xcf_s;
    end
        
    % -----grounding line location
    % calculate the thickness required to remain grounded at each grid cell
    Hf = -(rho_sw./rho_i).*b; % flotation thickness (m)
    % find the location of the grounding line and use a floating
    % geometry from the grounding line to the calving front
    if ~isempty(find(Hf-H>0,1,'first'))
        if length(Hf)>=find(Hf-H>0,1,'first')+1
            xgl = interp1(Hf(find(Hf-H>0,1,'first')-1:find(Hf-H>0,1,'first')+1)...
                -H(find(Hf-H>0,1,'first')-1:find(Hf-H>0,1,'first')+1),...
                x(find(Hf-H>0,1,'first')-1:find(Hf-H>0,1,'first')+1),0,'linear','extrap'); % (m along centerline)
        else
            xgl = x(find(Hf-H>0,1,'first')-1);
        end
    else
        xgl=xcf;
    end
    if xgl>xcf % grounding line can't be past calving front
        xgl=xcf;
    end

    % -----create coordinate system that hits gl exactly
    xl = round(xgl/dx0); % number of ideal grid spaces needed to reach the grounding line
    dx = xgl/xl; % new grid spacing (should be ~dx0)
    xn = 0:dx:xgl; % new distance vector
    if xcf-xgl > 0
        xl = round((xcf-xgl)/dx0);
        dx = (xcf-xgl)/xl;
        xn = [xn xn(end)+dx:dx:xcf];
    end
    clear dx; dxn = [xn(2:end)-xn(1:end-1) xn(end)-xn(end-1)];

    % -----get geometry on new coordinates
    c = length(xn); % index for xcf
    H = interp1(x,H,xn,'linear','extrap');
    % H gradient
    dHdx(1) = (H(2)-H(1))/(xn(2)-xn(1)); % forward difference
    dHdx(2:c-1) = (H(3:c)-H(1:c-2))./(xn(3:c)-xn(1:c-2)); % central difference
    dHdx(c) = (H(c)-H(c-1))./(xn(c)-xn(c-1)); % backward difference            
    % if there is a sudden jump in H (large gradient) past the grounding
    % line, set that to the previous point
    % thickness gradient
    if any(dHdx>50)
        c = find(dHdx>50,1,'first')-1;            
        H = H(1:c);
        xn = xn(1:c);
    end
    gl = dsearchn(xn',xgl); % index for xgl
    b = interp1(x0,b0,xn,'linear','extrap');
    W = interp1(x0,W0,xn,'linear','extrap');
    U = interp1(x,U,xn,'linear','extrap');
    A = interp1(x0,A0,xn,'linear','extrap');
    beta = interp1(x0,beta0,xn,'linear','extrap');
    x = xn; dx = dxn; 
    clear xn dxn; % clear to prevent issues in future iterations
    XGL(i) = xgl; % save grounding line position over time

    % -----calculate surface elevation
    h = b+H; % surface elevation (m a.s.l.)
    h(gl+1:c) = (1-rho_i/rho_sw).*H(gl+1:c); % adjust the surface elevation of ungrounded ice to account for buoyancy
    H(h<0)=0-b(h<0); h(h<0)=0; % surface cannot go below sea level
    h(h-H<b) = b(h-H<b)+H(h-H<b); % thickness cannot go beneath bed elevation

    % -----plot geometry, speed, & grounding line and calving front positions
    col = parula(length(t)); % color scheme for plots
    if plotTimeSteps
        if i==1
            drawnow
            figure(1); clf
            set(gcf,'Position',[0 100 1300 450]);
            ax1 = axes('Position',[0.05 0.12 0.27 0.78]); % glacier geometry
            hold on; grid on;
            set(gca,'FontSize',16,'linewidth',2);
            title([num2str(t(i)*3.1536e7), 'yrs']);
            xlim([0 95]); ylim([min(b)-100 max(h)+200]);
            xlabel('Distance Along Centerline [km]'); ylabel('Elevation [m]');
            % ice surface
            plot(x(1:c)./10^3,h(1:c),'color',col(i,:),'linewidth',2,'displayname','2009');
            % calving front
            plot(x(c)*[1,1]/10^3,[h(c)-H(c),h(c)],'.-','color',col(i,:),'linewidth',2,'HandleVisibility','off');
            % floating bed
            plot(x(gl:c)/10^3,h(gl:c)-H(gl:c),'color',col(i,:),'linewidth',2,'HandleVisibility','off');
            % bed elevation
            plot(x0./10^3,b0,'k','linewidth',2,'HandleVisibility','off');
            % mean sea level
            plot([x(1),x(end)]/10^3,[0,0],'k--','HandleVisibility','off');
            % ice speed
            ax2 = axes('Position',[0.37 0.1 0.28 0.8]);
            hold on; grid on;
            set(gca,'FontSize',14,'linewidth',2);
            xlim([0 95]); 
%                     ylim([0 800]);
            xlabel('Distance Along Centerline [km]'); ylabel('Speed [m a^{-1}]');
            plot(x(1:c)./10^3,U(1:c).*3.1536e7,'color',col(i,:),'linewidth',2,'displayname','2009');
            % calving front & grounding line positions
            ax3 = axes('Position',[0.7 0.1 0.28 0.8]); 
            hold on; grid on;
            set(gca,'FontSize',14,'linewidth',2);
            xlim([30 95]);
            xlabel('Distance Along Centerline [km]'); 
            ylabel('Year');
            plot(x(c)/10^3,t(i)./3.1536e7,'.','markersize',15,'color',col(i,:),'displayname','2009');
            plot(ax3,x(gl)./10^3,t(i)./3.1536e7,'x','Color',col(i,:),'markersize',10,'linewidth',2,'HandleVisibility','off');
        elseif mod(t(i),dt*200)==0 % display every dt*200
            figure(1);
            % glacier geometry
            plot(ax1,x(1:c)/10^3,h(1:c),'-','color',col(i,:),'linewidth',2,'displayname',num2str(round(t(i)./3.1536e7)+2009));
            plot(ax1,x(gl:c)/10^3,h(gl:c)-H(gl:c),'-','color',col(i,:),'linewidth',2,'HandleVisibility','off');
            plot(ax1,[x(c);x(c)]/10^3,[h(c);h(c)-H(c)],'-','color',col(i,:),'linewidth',2,'HandleVisibility','off');
            title(ax1, [num2str(t(i)/3.1536e7), 'yrs']);
            plot(ax1,x(c)*[1,1]/10^3,[h(c)-H(c),h(c)],'.-','color',col(i,:),'linewidth',2,'HandleVisibility','off'); % calving front
            plot(ax1,x(gl:c)/10^3,h(gl:c)-H(gl:c),'color',col(i,:),'linewidth',2,'HandleVisibility','off'); % floating bed (gl:c)
            % ice speed
            plot(ax2,x(1:c)/10^3,U(1:c).*3.1536e7,'-','Color',col(i,:),'linewidth',2,'DisplayName',num2str(round(t(i)./3.1536e7)+2009));
            % calving front & grounding line positions
            plot(ax3,x(c)/10^3,t(i)/3.1536e7,'.','Color',col(i,:),'markersize',15,'displayname',num2str(round(t(i)./3.1536e7)+2009)); hold on;
            plot(ax3,x(gl)/10^3,t(i)/3.1536e7,'x','Color',col(i,:),'markersize',10,'linewidth',2,'HandleVisibility','off'); hold on;
        end    
    end

    % -----calculate the effective pressure 
    % (ice overburden pressure minus water pressure) assuming an easy & 
    % open connection between the ocean and ice-bed interface
    sl = find(b<=0,1,'first'); % find where the glacier base first drops below sea level
    N_ground = rho_i*g*H(1:sl); % effective pressure where the bed is above sea level (Pa)
    N_marine = rho_i*g*H(sl+1:length(x))+(rho_sw*g*b(sl+1:length(x))); % effective pressure where the bed is below sea level (Pa)
    N = [N_ground N_marine];
    N(N<0)=0; % cannot have negative values

    % -----solve for new velocity
    [U,dUdx] = U_convergence(x,U,H,h,A,E,N,W,dx,c,n,m,beta,rho_i,rho_sw,g,sigma_b);

    % -----calculate ice flux
    F = U.*H.*W; % ice flux (m^3 s^-1)
    F(isnan(F))=0;
    F(1)=F(2);

    % -----save grounding line oce flux (discharge)
    Fgl(i) = F(gl)*917*1e-12*3.1536e7; % Gt/a

    % -----implement SMB, SMR, & RO
    SMB = interp1(x0,SMB0+Q0/2,x);
    RO = interp1(x0,RO0,x);
    delta_mdot = 0; % m/s
    SMR = zeros(1,c);
    % use the Larsen C mean melt rate profile to scale SMR
    % using the max initial SMR
    if gl<c
        SMR(gl+1:c) = (SMR0+delta_mdot)/(SMR_mean_fit.a+1)*feval(SMR_mean_fit,x(gl+1:c)-x(gl+1)); 
    end

    % -----calculate the  change in ice thickness from continuity
    clearvars dHdt
    dHdt(1) = (-1/W(1))*(F(1)-F(2))/(x(1)-x(2)); % forward difference
    dHdt(2:c-1) = (-1./W(2:c-1)).*(F(1:c-2)-F(3:c))./(x(1:c-2)-x(3:c)); % central difference
    dHdt(c:length(x)) = (-1./W(c:length(x))).*(F(c-1:length(x)-1)-F(c:length(x)))./(x(c-1:length(x)-1)-x(c:length(x))); % backward difference
    dH = dHdt.*dt;

    % -----new thickness (change from dynamics, SMB, & SMR)
    Hn = H+dH+(SMB.*dt)+(SMR.*dt)-(interp1(x0,RO0,x)*dt);
    Hn(Hn < 0) = 0; % remove negative values
    H = Hn; % set thickness to new value

    % -----stop the model if it behaves unstably (monitored by ice thickness and speed)
    if max(H) > H_max
        disp(['Adjust dt']);
        break;
    end
    if mean(U) < U_min
        disp('Too slow!');
        %break;
    end
    if any(~isfinite(H(1:c))) || any(~isfinite(U(1:c))) || any(~isfinite(h(1:c)))
        disp('non finite values');
        break;
    end
    
end

%% 3. Conduct sensitivity tests

