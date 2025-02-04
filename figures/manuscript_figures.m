%% Generate figures for MS thesis and JGlac manuscript
% Rainey Aberle 2022

% Figures:
%   - Map of the study area
%   - Observed Conditions Time Series
%   - Cumulative Strain Rates / A adjustment
%   - Beta Solution
%   - Sensitivity Tests
%   - Regional glacier terminus time series
%   - 2018 Model Misfits

% close all; 
clear all;

% -----Define necessary paths
% basepath = path in directory to CraneGlacier_flowlinemodeling
basepath = '/Users/raineyaberle/Research/MS/CraneGlacier_flowlinemodeling/';
% outpath = where output figures will be places
outpath = [basepath,'figures/'];
% datapath = base directory where data exist
datapath = '/Volumes/LaCie/raineyaberle/Research/MS/CraneGlacier_flowlinemodeling/data/';

% -----Add necessary paths to working directories
addpath([basepath,'functions/']);
addpath([basepath,'functions/gridLegend_v1.4/']);
addpath([basepath,'functions/cmocean_v2.0/cmocean/']);
addpath([basepath,'functions/AntarcticMappingTools/']);
addpath([basepath,'inputs-outputs/']);
addpath([datapath,'bed_elevations/OIB_L1B']);
addpath([basepath,'functions/line2arrow-kakearney-pkg-8aead6f/']);
addpath([basepath,'functions/line2arrow-kakearney-pkg-8aead6f/line2arrow/']);
addpath([basepath,'functions/line2arrow-kakearney-pkg-8aead6f/axescoord2figurecoord/']);
addpath([basepath,'functions/line2arrow-kakearney-pkg-8aead6f/parsepv']);

% -----Load Crane centerline
cl.Xi = load('Crane_centerline.mat').x; cl.Yi = load('Crane_centerline.mat').y;
% Define x as distance along centerline
cl.xi = zeros(1,length(cl.Xi));
for i=2:(length(cl.Xi))
    cl.xi(i)=sqrt((cl.Xi(i)-cl.Xi(i-1))^2+(cl.Yi(i)-cl.Yi(i-1))^2)+cl.xi(i-1);
end
% Regrid the centerline to 300m equal spacing between points
cl.x = 0:300:cl.xi(end);
cl.X = interp1(cl.xi,cl.Xi,cl.x); cl.Y = interp1(cl.xi,cl.Yi,cl.x);

% -----Load model initialization variables
load([basepath,'inputs-outputs/model_initialization_pre-collapse.mat']);

% -----Load 2018 grounding line position
xgl_2018 = load([basepath,'inputs-outputs/2018_modeledConditions.mat']).x(...
    load([basepath,'inputs-outputs/2018_modeledConditions.mat']).gl);
Xgl_2018 = interp1(cl.xi, cl.Xi, xgl_2018); Ygl_2018 = interp1(cl.xi, cl.Yi, xgl_2018);

% -----Define parameters for figures
fontsize = 16;          % font size for figure text
fontname = 'Arial';     % font name
        
%% Map of the study area

save_figure = 0;    % = 1 to save figure
markersize = 8;    % marker size
linewidth = 1.5;      % line width

% Specify xticks/yticks coordinates and axes limits
xticks = linspace(-2.455e6,-2.375e6,5); yticks=linspace(1.21e6,1.29e6,5);
xlimits=[xticks(1) xticks(end)]; ylimits = [yticks(1) yticks(end)];
xlimits2 = -2.4196e6:0.005e6:-2.4046e6; ylimits2 = 1.2460e6:0.005e6:1.2610e6; 
    
% Load & display Landsat image 1
cd([datapath,'imagery/']);
landsat_fn = "LC08_L1GT_217106_20200110_20200114_01_T2_B8.TIF";
[LS.im,LS.R] = readgeoraster(landsat_fn); [LS.ny,LS.nx] = size(LS.im);
% polar stereographic coordinates of image boundaries
LS.x = linspace(min(LS.R.XWorldLimits),max(LS.R.XWorldLimits),LS.nx); 
LS.y = linspace(min(LS.R.YWorldLimits),max(LS.R.YWorldLimits),LS.ny);
% display image on ax(1)
F1 = figure(1); clf; hold on; 
set(gcf,'position',[557 75 724 622],'color','w');
ax(1)=gca;
im1 = imagesc(ax(1),LS.x,LS.y,flipud(LS.im*1.1)); colormap('gray');
% set axes properties
ax(1).XTick=xticks+5e3; ax(1).XTickLabel=string((xticks+5e3)./10^3);
ax(1).YTick=yticks; ax(1).YTickLabel=string(yticks./10^3);
set(ax(1),'YDir','normal','XLim',xlimits','YLim',ylimits,'FontSize',14,...
    'linewidth',2,'fontsize',fontsize,'Position',[0.165 0.08 0.67 0.84]); 
xlabel('Easting [km]'); ylabel('Northing [km]');
    
% load & display REMA as contours
[REMA.im,REMA.R] = readgeoraster('REMA_clipped.tif');
REMA.im(REMA.im==-9999)=NaN;
[REMA.ny,REMA.nx] = size(REMA.im);
% polar stereographic coordinates of image boundaries
REMA.x = linspace(min(REMA.R.XWorldLimits),max(REMA.R.XWorldLimits),REMA.nx); 
REMA.y = linspace(min(REMA.R.YWorldLimits),max(REMA.R.YWorldLimits),REMA.ny);
% display contours on ax(1)
hold on; contour(ax(1),REMA.x,REMA.y,flipud(REMA.im),0:500:2000,'-k','linewidth',2,'ShowText','on');
    
% load & display ITS_LIVE velocity map
cd([datapath,'surface_velocities/ITS_LIVE/']);
v.v = ncread('ANT_G0240_2017.nc','v'); v.v(v.v==-3267)=NaN;
v.x = ncread('ANT_G0240_2017.nc','x'); 
v.y = ncread('ANT_G0240_2017.nc','y');
% display velocity map on ax(2)
ax(2) = axes; 
im2=imagesc(ax(2),v.x,v.y,v.v'); colormap(cmocean('haline'));
im2.AlphaData=0.5; clim([0 1100]);
% set axes properties
ax(2).XLim=xlimits; ax(2).YLim=ylimits; 
set(ax(2),'YDir','normal','Visible','off','fontsize',fontsize,'XTick',[],'YTick',[]); hold on; 
% add legend
l=legend('Position',[0.23 0.8 0.12 0.07],'Color',[175 175 175]/255,...
    'fontname','arial','fontsize',fontsize);
    
% Add lat lon coordinates to top and right axes
latlon = graticuleps(-66:0.25:-64,-64:0.5:-62,'color',[175 175 175]/255,'linewidth',1,...
    'HandleVisibility','off');
ax(1).Position = [0.135 0.1 0.73 0.85];
ax(2).Position=[0.001 0.1 1 0.85];     
annotation('textarrow',[0.6 0.6],[0.6 0.6],'string','62.00^oS','textcolor',[175 175 175]/255,...
    'HeadStyle','none','LineStyle', 'none','Position',[.97 .67 0 0],'FontSize',fontsize,'FontName',fontname);     
annotation('textarrow',[0.6 0.6],[0.6 0.6],'string','62.50^oS','textcolor',[175 175 175]/255, ...
    'HeadStyle','none','LineStyle', 'none','Position',[.97 .39 0 0],'FontSize',fontsize,'FontName',fontname);     
annotation('textarrow',[0.6 0.6],[0.6 0.6],'string','65.25^oW','textcolor',[175 175 175]/255, ...
    'HeadStyle','none','LineStyle', 'none','Position',[.64 .97 0 0],'FontSize',fontsize,'FontName',fontname);     
annotation('textarrow',[0.6 0.6],[0.6 0.6],'string','65.00^oW','textcolor',[175 175 175]/255, ...
    'HeadStyle','none','LineStyle', 'none','Position',[.36 .97 0 0],'FontSize',fontsize,'FontName',fontname); 
    
% plot OIB flights
cd([datapath,'surface_elevations/OIB_L2/']);
OIBfiles = dir('*IRMCR2*.csv');
count=0;
for i=1:length(OIBfiles)
    OIB.file = readmatrix(OIBfiles(i).name);
    if any(~isnan(OIB.file))
        count=count+1;
        [OIB.x,OIB.y] = wgs2ps(OIB.file(:,2),OIB.file(:,1),'StandardParallel',-71,'StandardMeridian',0);
        if count==1
            hold on; plot(ax(2),OIB.x,OIB.y,'color',[254,227,145]./256,...
                'displayname','NASA OIB','linewidth',linewidth-0.5);
        else
            hold on; plot(ax(2),OIB.x,OIB.y,'color',[254,227,145]./256,...
                'HandleVisibility','off','linewidth',linewidth-0.5);            
        end
    end
end
    
% plot (b) as outline polygon
r = rectangle('Position',[xlimits2(1) ylimits2(1) xlimits2(end)-xlimits2(1) ylimits2(end)-ylimits2(1)],...
    'EdgeColor','k','linewidth',linewidth+0.5);
    
% plot centerline points
plot(cl.X,cl.Y,'o','color','m','markerfacecolor','m',...
    'markeredgecolor','k','markersize',markersize-3,'displayname','Centerline');

% plot centerline distance markers
dist = 0:10e3:cl.x(end); Idist = dsearchn(cl.x',dist'); % ticks every 10 km
plot(cl.X(Idist),cl.Y(Idist),'o','markerfacecolor',[253,224,221]/255,...
    'markeredgecolor','k','markersize',markersize,'handlevisibility','off');
labels = string(dist./10^3);
for i=1:length(labels)
    labels(i) = strcat(labels(i)," km");
end
text(cl.X(Idist)+1500,cl.Y(Idist),labels,'color',[253,224,221]/255,...
    'fontweight','bold','fontname','arial','fontsize',fontsize);

% plot 2018 grounding line location
plot(Xgl_2018, Ygl_2018, 'xw', 'markersize', markersize+4,'linewidth',3,'displayname','2018 x_{gl}');

% add colorbar
c = colorbar('Position',[0.29 0.58 0.02 0.15],'fontsize',fontsize,'fontweight',...
    'bold','color','w','fontname',fontname);
set(get(c,'Title'),'String','Flow speed [m yr^{-1}]','color','w','fontname',...
    fontname,'Position',[5 100 0]);

% insert text labels
% Crane
annotation('textarrow',[0.6 0.6],[0.6 0.6],'string','Crane', ...
   'HeadStyle','none','LineStyle', 'none', 'TextRotation',70,'Position',[.52 0.65 0 0],...
   'FontSize',fontsize-1,'FontName',fontname,'fontweight','bold','TextColor','w');%[200 200 200]/255);
% Jorum
annotation('textarrow',[0.6 0.6],[0.6 0.6],'string','Jorum', ...
    'HeadStyle','none','LineStyle', 'none', 'TextRotation',35,'Position',[.52 .855 0 0],...
    'FontSize',fontsize-1,'FontName',fontname,'fontweight','bold','TextColor','w');%[200 200 200]/255);    
% Flask
annotation('textarrow',[0.6 0.6],[0.6 0.6],'string','Flask', ...
   'HeadStyle','none','LineStyle', 'none', 'TextRotation',55,'Position',[.8 .19 0 0],...
   'FontSize',fontsize-1,'FontName',fontname,'fontweight','bold','TextColor','w');%[200 200 200]/255);    
% Mapple
%annotation('textarrow',[0.6 0.6],[0.6 0.6],'string','Mapple', ...
%    'HeadStyle','none','LineStyle', 'none', 'TextRotation',66,'Position',[.65 .7 0 0],...
%    'FontSize',fontsize-1,'FontName',fontname,'fontweight','bold','TextColor',[200 200 200]/255);    
% Melville
annotation('textarrow',[0.6 0.6],[0.6 0.6],'string','Melville', ...
    'HeadStyle','none','LineStyle', 'none', 'TextRotation',70,'Position',[.68 .6 0 0],...
    'FontSize',fontsize-1,'FontName',fontname,'fontweight','bold','TextColor','w');%[200 200 200]/255);           
% Pequod
annotation('textarrow',[0.6 0.6],[0.6 0.6],'string','Pequod', ...
    'HeadStyle','none','LineStyle', 'none', 'TextRotation',66,'Position',[.74 .59 0 0],...
    'FontSize',fontsize-1,'FontName',fontname,'fontweight','bold','TextColor','w');%[200 200 200]/255);               
% Starbuck
annotation('textarrow',[0.6 0.6],[0.6 0.6],'string','Starbuck', ...
    'HeadStyle','none','LineStyle', 'none', 'TextRotation',38,'Position',[.78 .47 0 0],...
    'FontSize',fontsize-1,'FontName',fontname,'fontweight','bold','TextColor','w');%[200 200 200]/255);   
% Tributary A
txt = sprintf('A');
    text(-2.413e6,1.232e6,txt,'fontsize',fontsize-1,'fontweight','bold','fontname',fontname,'color','w');      
% Tributary B
txt = sprintf('B');
    text(-2.415e6,1.237e6,txt,'fontsize',fontsize-1,'fontweight','bold','fontname',fontname, 'color', 'w');    
% Tributary C
txt = sprintf('C');
    text(-2.417e6,1.251e6,txt,'fontsize',fontsize-1,'fontweight','bold','fontname',fontname, 'color', 'w'); 
% a - panel label
text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.05+min(get(gca,'XLim')),(max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.95+min(get(gca,'YLim')),...
    'a)','fontsize',fontsize,'linewidth',linewidth-1,'backgroundcolor','w','fontname',fontname,'fontweight','bold');          

% plot LIMA inset in figure
ax(4)=axes('pos',[0.2 0.12 0.2 0.2]);
set(ax(4),'xtick',[],'xticklabel',[],'ytick',[],'yticklabel',[]);
cd([datapath,'imagery/']);
L = imread('LIMA.jpg');
imshow(L);
hold on; plot(1100,4270,'o','color','y','markersize',10,'linewidth',3);
    
% add zoomed in Landsat B8 figure to demonstrate meltwater pooling on Crane surface
% create new figure
F2 = figure(2); clf; hold on; F2.Position = [200 200 450 390];
% display image on ax(5) 
ax(5)=gca; ax(5).Position = [0.15 0.15 0.8 0.8];
im2 = imagesc(ax(5),LS.x,LS.y,flipud(LS.im*1.1)); colormap('gray');
% set axis properties
set(ax(5),'YDir','normal','linewidth',2,'fontsize',fontsize,'fontname',fontname,...
    'XLim',[xlimits2(1) xlimits2(end)],'YLim',[ylimits2(1) ylimits2(end)]); 
ax(5).XTick=xlimits2-0.4e3; ax(5).XTickLabel=string((xlimits2-0.4e3)./10^3);
ax(5).YTick=ylimits2+4e3; ax(5).YTickLabel=string((ylimits2+4e3)./10^3);
xlabel('Easting [km]'); ylabel('Northing [km]');  
text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.05+min(get(gca,'XLim')),(max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.95+min(get(gca,'YLim')),...
    'b)','fontsize',fontsize,'linewidth',linewidth-1,'backgroundcolor','w','fontname',fontname,'fontweight','bold'); 
% Draw arrows pointing to melt features
a1 = annotation('arrow','color','w','position',[0.76 0.76 -0.1 0],'linewidth',linewidth);
a2 = annotation('arrow','color','w','position',[0.72 0.2 -0.05 0.1],'linewidth',linewidth);
a3 = annotation('arrow','color','w','position',[0.56 0.18 0 0.1],'linewidth',linewidth);
a4 = annotation('arrow','color','w','position',[0.7 0.85 -0.1 0.0],'linewidth',linewidth);
    
% save figures 1 and 2
if save_figure
    set(F1,'InvertHardCopy','off'); %set(F2,'InvertHardCopy','off'); % save colors as is
    exportgraphics(F1,[outpath,'study_area.png'],'Resolution',300);
    exportgraphics(F1,[outpath,'study_area.eps'],'Resolution',300);
    exportgraphics(F2,[outpath,'meltwater_ponds.png'],'Resolution',300); 
    exportgraphics(F2,[outpath,'meltwater_ponds.eps'],'Resolution',300);   
    disp('figures 1 and 2 saved.');    
end

%% Centerline Observations Time Series

save_figure = 0; % = 1 to save figure
linewidth = 1.2; % line width for plots
markersize = 10; % marker size for plots

col = parula(length(1995:2020)); % color scheme for plotting

years = 1994:2020; % total coverage of years for all datasets

% 1. Ice surface elevation
h = load([basepath,'inputs-outputs/observed_surface_elevations.mat']).h;
years_h = [2001 2001 2009 2010 2011 2016 2017 2018]; % years of coverage
I_years_h = [3 7 8:14]; % index of each year's profile

% 2. Glacier terminus position
termX = load([basepath,'inputs-outputs/LarsenB_centerline.mat']).centerline.termx;
termY = load([basepath,'inputs-outputs/LarsenB_centerline.mat']).centerline.termy;
termx = cl.xi(dsearchn([cl.Xi cl.Yi],[termX' termY']));
termdate = load([basepath,'inputs-outputs/LarsenB_centerline.mat']).centerline.termdate;
c_obs = dsearchn(cl.xi',interp1(termdate,termx,[2002 2001 2009 2011 2016:2018])');
c_obs(1:2) = 186;

% 3. Glacier bed (OIB)
b = load([basepath,'inputs-outputs/observed_bed_elevations.mat']).HB.hb0; % raw
b_width_ave = load([basepath,'inputs-outputs/observed_bed_elevations_width_averaged.mat']).b_adj; % width-averaged
b_width_ave_smooth = load([basepath,'inputs-outputs/model_initialization_pre-collapse.mat']).b0; % width-averaged, smoothed
x0 = load([basepath,'inputs-outputs/model_initialization_pre-collapse']).x0;
W0 = load([basepath,'inputs-outputs/model_initialization_pre-collapse']).W0;
bathym = load([basepath,'inputs-outputs/observed_bed_elevations.mat']).bathym; % Rebesco et al. (2014)

% 4. Width-averaged ice surface speeds
U = load([basepath,'inputs-outputs/observed_surface_speeds.mat']).U; 
years_U = [1994, 1995, 1999:2017]; % years of coverage
I_years_U = 1:21; % index of each year's profile

% 5. Glacier width
W = load([basepath,'inputs-outputs/observed_glacier_width.mat']).width.W;

% 6. SMB
SMB = load([basepath,'inputs-outputs/downscaled_RACMO_variables_1995-2019.mat']).smb;
RO = load([basepath,'inputs-outputs/model_initialization_pre-collapse.mat']).RO0;
years_SMB = 1995:2019; % years of coverage
I_years_SMB = 1:25; % index of each year's profile

% Plot
figure(3); clf
set(gcf,'Position',[-1000 50 800 900]);
ax(1)=axes('Position',[0.11 0.7 0.75 0.28],'linewidth',2,'fontsize',...
    fontsize,'fontname',fontname,'XTickLabels',[]); % geometry
    hold on; grid on; 
    ylabel('Elevation [m]'); 
    xlim([0 65]); 
    ylim([-1200 1350]); 
    legend('Location','northeast');
    % surface elevation
    for i=1:length(years_h)
        Icol = round(interp1(years, 1:length(years), years_h(i)));
        if years_h(i) > 2002
            xcf = interp1(termdate, termx, years_h(i)); % nearest calving front location [distance along centerline, m]
            c = dsearchn(cl.xi', xcf); % index of calving front 
        else 
            c = length(cl.xi);
        end
        plot(ax(1),cl.xi(1:c)./10^3,h(I_years_h(i)).h_centerline(1:c),'linewidth',linewidth,...
            'color',col(Icol,:),'HandleVisibility','off');
    end
    % calving front location
    for i=1:length(termx)
        Icol = round(interp1(years, 1:length(years), termdate(i)));
        plot(ax(1),termx(i)/10^3*[1,1],[interp1(x0,b_width_ave_smooth,termx(i)) 30],...
            'linewidth',linewidth,'color',col(Icol,:),'HandleVisibility','off');
    end
    % bed picks
    plot(ax(1), cl.xi./10^3, b, ':', 'color', [150,150,150]./255, 'linewidth',2, 'displayname', 'b_{centerline}');
    % bed, width-averaged
    plot(ax(1), cl.xi./10^3 ,b_width_ave, '-', 'color', [150,150,150]./255, 'linewidth', linewidth, 'displayname', 'b_{width-averaged}');  
    % bed, width-averaged, smoothed
    plot(ax(1), x0./10^3 ,b_width_ave_smooth, '-', 'color', 'k', 'linewidth', linewidth, 'displayname', 'b_{width-averaged, smoothed}');      
    % bathymetry observations from Rebesco et al. (2006)
    plot(ax(1), cl.xi./10^3, bathym, 'xk', 'linewidth', linewidth', 'markersize', 3, 'displayname', 'b_{Rebesco et al. (2006)}');
    % Add text label
    text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.03+min(get(gca,'XLim')),...
        (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
        'a)','fontsize',fontsize,'linewidth',linewidth-1,'backgroundcolor','w','fontname',fontname,'fontweight','bold');    
ax(2)=axes('Position',[0.11 0.39 0.75 0.28],'linewidth',2,...
    'fontsize',fontsize,'fontname',fontname,'XTickLabels',[]); % speed
    hold on; grid on; ylabel('Speed [m yr^{-1}]');
    set(ax(2), 'XLim', [0 65], 'YLim', [0 1400], 'YTick', 0:400:1600);
    for i=1:length(years_U)
        Icol = round(interp1(years, 1:length(years), years_U(i)));
        xcf = interp1(termdate, termx, years_U(i)); % nearest calving front location [distance along centerline, m]
        c = dsearchn(cl.xi', xcf); % index of calving front 
        plot(ax(2),cl.xi(1:c)./10^3, U(I_years_U(i)).U_centerline(1:c)*3.1536e7,...
            'linewidth', linewidth, 'color', col(Icol,:), 'HandleVisibility','off');
    end
    % Add text label
    text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.03+min(get(gca,'XLim')),...
        (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
        'b)','fontsize',fontsize,'linewidth',linewidth-1,'backgroundcolor','w','fontname',fontname,'fontweight','bold');      
ax(3)= axes('Position',[0.11 0.08 0.75 0.28],'linewidth',2,...
    'fontsize',fontsize,'fontname',fontname); % SMB
    hold on; grid on; 
    xlabel('Distance along centerline [km]'); 
    ylabel('SMB [m yr^{-1}]');
    xlim([0 65]); 
    ylim([0.15 0.6]); 
    legend('Location','northeast');
    smb = zeros(length(SMB.linear(:,1)),length(cl.xi));
    for i=1:length(years_SMB)
        Icol = interp1(years, 1:length(years), years_SMB(i));
        if years_SMB(i) > 2002
            xcf = interp1(termdate, termx, years_SMB(i)); % nearest calving front location [distance along centerline, m]
            c = dsearchn(cl.xi', xcf); % index of calving front 
        else
            c = length(cl.xi);
        end
        plot(ax(3), cl.xi(1:c)./10^3, SMB.linear(i,1:c), 'color', col(Icol,:),...
            'linewidth', linewidth, 'HandleVisibility', 'off');
    end
    plot(ax(3), cl.xi(1:c_obs(1))./10^3, SMB.downscaled_average_linear(1:c_obs(1)), '--k',...
        'linewidth', linewidth+0.3, 'displayname', 'SMB_{\mu}');
    plot(ax(3), x0/10^3, interp1(cl.xi(1:c_obs(1)), SMB.downscaled_average_linear(1:c_obs(1)),x0) ...
        - RO0.*3.1536e7, '-k', 'linewidth', linewidth+0.6, 'displayname', 'SMB_{\mu} - RO');
    % Add text label
    text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.03+min(get(gca,'XLim')),...
        (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
        'c)','fontsize',fontsize,'linewidth',linewidth-1,'backgroundcolor','w','fontname',fontname,'fontweight','bold');            
    % Add colorbar
    colormap(col); 
    cb = colorbar('Limits', [0 1], 'Ticks',...
        [1/length(years)*(2000-min(years)) 1/length(years)*(2010-min(years)) 1],...
        'TickLabels', string([2000 2010 2020]), 'Position',[.89 .32 .03 .3410],...
        'fontsize',fontsize); 
    
% Save figure
if save_figure
    exportgraphics(figure(3),[outpath,'centerline_observations.png'],'Resolution',300);     
    exportgraphics(figure(3),[outpath,'centerline_observations.eps'],'Resolution',300);     
    disp('figure 3 saved.');
end

%% Regional Glacier Termini Time Series

save_figure = 0; % = 1 to save figure
linewidth = 2; 

% load Landsat images
cd([datapath,'imagery/']);
% LSA 
landsatA = dir('LC08*20201008*B8.TIF');
    [LSA.im,LSA.R] = readgeoraster(landsatA.name); 
    [LSA.ny,LSA.nx] = size(LSA.im);
    % polar stereographic coordinates of image boundaries
    LSA.x = linspace(min(LSA.R.XWorldLimits),max(LSA.R.XWorldLimits),LSA.nx); 
    LSA.y = linspace(min(LSA.R.YWorldLimits),max(LSA.R.YWorldLimits),LSA.ny);
% LSB
landsatB = dir('LC08*20211013_01_T2_B8.tif');
    [LSB.im,LSB.R] = readgeoraster(landsatB.name); 
    [LSB.ny,LSB.nx] = size(LSB.im);
    % polar stereographic coordinates of image boundaries
    LSB.x = linspace(min(LSB.R.XWorldLimits),max(LSB.R.XWorldLimits),LSB.nx); 
    LSB.y = linspace(min(LSB.R.YWorldLimits),max(LSB.R.YWorldLimits),LSB.ny);

% load LIMA .jpg
L = imread('LIMA.jpg');

% cd to terminus coordinate shapefiles
cd([datapath,'terminus/regional/']);

% set up figure, subplots, and plot
figure(4); clf; 
set(gcf,'Position',[-1200 200 1000 725]); 
% regional map
ax1 = axes('position',[0.08 0.56 0.23 0.4]); hold on; imshow(L);
    ax1.XLim=[0.7139e3 1.4667e3]; ax1.YLim=[3.8765e3 4.6369e3];
    % plot borders around image
    plot([ax1.XLim(1) ax1.XLim(1)],ax1.YLim,'k','linewidth',linewidth-1);
    plot([ax1.XLim(2) ax1.XLim(2)],ax1.YLim,'k','linewidth',linewidth-1);    
    plot(ax1.XLim,[ax1.YLim(1) ax1.YLim(1)],'k','linewidth',linewidth-1);   
    plot(ax1.XLim,[ax1.YLim(2) ax1.YLim(2)],'k','linewidth',linewidth-1);   
    % plot location text labels
    text(940,3950,'a)','edgecolor','k','fontsize',fontsize-3,'linewidth',1,'backgroundcolor','w','fontweight','bold');
    text(1000,4120,'b)','edgecolor','k','fontsize',fontsize-3,'linewidth',1,'backgroundcolor','w','fontweight','bold');
    text(1013,4371,'c)','edgecolor','k','fontsize',fontsize-3,'linewidth',1,'backgroundcolor','w','fontweight','bold');    
    text(1080,4460,'d)','edgecolor','k','fontsize',fontsize-3,'linewidth',1,'backgroundcolor','w','fontweight','bold');    
    text(1085,4550,'e)','edgecolor','k','fontsize',fontsize-3,'linewidth',1,'backgroundcolor','w','fontweight','bold');    
    % add colorbar
    colormap(ax1,'parula'); 
    colorbar('Limits',[0 1],'Ticks',[0 0.5 1],'TickLabels',[{'2014'},{'2017'},{'2021'}],...
        'Location','southoutside','fontsize',fontsize-1,'FontName',fontname); 
% a) Edgeworth
cd([datapath,'terminus/regional/Edgeworth/']); % enter folder 
files = dir('Edgeworth*.shp'); % load file
% loop through files to grab centerline
for j=1:length(files)
    if contains(files(j).name,'CL')
        file = shaperead(files(j).name);
        cl.lon = file.X; % Lon
        cl.lat = file.Y; % Lat
        [cl.X,cl.Y] = wgs2ps(cl.lon,cl.lat,'StandardParallel',-71,'StandardMeridian',0);
        % define x as distance along centerline
        x = zeros(1,length(cl.X));
        for k=2:length(x)
            x(k) = sqrt((cl.X(k)-cl.X(k-1))^2+(cl.Y(k)-cl.Y(k-1))^2)+x(k-1); %(m)
        end
    end
end
% initialize f
clear f; files(1).lon = NaN; files(1).lat = NaN; files(1).date = NaN;
% loop through files to grab terminus positions
for j=1:length(files)
    if ~contains(files(j).name,'CL')
        file = shaperead(files(j).name);
        % loop through file
        for k=1:length(file)
            files(length(files)+1).lon = file(k).X; % Lon
            files(length(files)).lat = file(k).Y; % Lat
            % convert to polar stereographic coordinates
            [files(length(files)).X,files(length(files)).Y] = wgs2ps(files(length(files)).lon,files(length(files)).lat,'StandardParallel',-71,'StandardMeridian',0);
            files(length(files)).x = x(dsearchn([cl.X' cl.Y'],[nanmean(files(length(files)).X) nanmean(files(length(files)).Y)])); % x
        end
    end 
end
% plot
col1 = parula(length(files)); % color scheme for plotting
ax2=axes('position',[0.39 0.555 0.23 0.4]); hold on; grid on;      
    set(gca,'fontname',fontname,'fontsize',fontsize);
    ylabel('Northing [km]');
    title('a) Edgeworth');
    % plot LIMA
    colormap(ax2,'gray');
    imagesc(LSA.x/10^3,LSA.y/10^3,flipud(LSA.im)); 
    ax2.XLim=[-2.4508e3 -2.443e3]; ax2.YLim=[1.4138e3 1.4204e3]; 
    % plot centerline
    l1=line(cl.X(3:8)/10^3,cl.Y(3:8)/10^3,'color','k','linewidth',linewidth);
    % arrow
    line2arrow(l1,'color','k','linewidth',linewidth,'headwidth',20,'headlength',20);
    % plot terminus positions
    for j=1:length(files)
        plot(files(j).X/10^3,files(j).Y/10^3,'color',col1(j,:),'linewidth',linewidth);
    end
    % plot label
%     text((ax2.XLim(2)-ax2.XLim(1))*0.08+ax2.XLim(1),(max(ax2.YLim)-min(ax2.YLim))*0.92+min(ax2.YLim),...
%         'a)','edgecolor','k','fontsize',fontsize,'linewidth',1,'backgroundcolor','w','fontweight','bold'); 
% b) Drygalski
cd([datapath,'terminus/regional/Drygalski/']); % enter folder 
files = dir('Drygalski*.shp'); % load file
% loop through files to grab centerline
for j=1:length(files)
    if contains(files(j).name,'CL')
        file = shaperead(files(j).name);
        cl.lon = file.X; % Lon
        cl.lat = file.Y; % Lat
        [cl.X,cl.Y] = wgs2ps(cl.lon,cl.lat,'StandardParallel',-71,'StandardMeridian',0);
        % define x as distance along centerline
        x = zeros(1,length(cl.X));
        for k=2:length(x)
            x(k) = sqrt((cl.X(k)-cl.X(k-1))^2+(cl.Y(k)-cl.Y(k-1))^2)+x(k-1); %(m)
        end
    end
end
% initialize f
clear f; files(1).lon = NaN; files(1).lat = NaN; files(1).date = NaN;
% loop through files to grab terminus positions
for j=1:length(files)
    if ~contains(files(j).name,'CL')
        file = shaperead(files(j).name);
        % loop through file
        for k=1:length(file)
            files(length(files)+1).lon = file(k).X; % Lon
            files(length(files)).lat = file(k).Y; % Lat
            % convert to polar stereographic coordinates
            [files(length(files)).X,files(length(files)).Y] = wgs2ps(files(length(files)).lon,files(length(files)).lat,'StandardParallel',-71,'StandardMeridian',0);
            files(length(files)).x = x(dsearchn([cl.X' cl.Y'],[nanmean(files(length(files)).X) nanmean(files(length(files)).Y)])); % x
        end
    end 
end
% plot
col1 = parula(length(files)); % color scheme for plotting
ax3=axes('position',[0.72 0.555 0.24 0.4]); hold on; grid on;      
    set(gca,'fontname',fontname,'fontsize',fontsize);
    title('b) Drygalski');
    % plot LIMA
    colormap(ax3,'gray');
    imagesc(LSA.x/10^3,LSA.y/10^3,flipud(LSA.im)); 
    ax3.XLim = [-2.4416e3 -2.4247e3]; ax3.YLim = [1.3552e3 1.3721e3];        
    % plot centerline
    l3=line(cl.X(4:7)/10^3,cl.Y(4:7)/10^3,'color','k','linewidth',linewidth);
    % arrow
    line2arrow(l3,'color','k','linewidth',linewidth,'headwidth',20,'headlength',20);        
    % plot terminus positions
    for j=1:length(files)
        plot(files(j).X/10^3,files(j).Y/10^3,'color',col1(j,:),'linewidth',linewidth);
    end
    % plot label
%     text((ax3.XLim(2)-ax3.XLim(1))*0.08+ax3.XLim(1),(max(ax3.YLim)-min(ax3.YLim))*0.92+min(ax3.YLim),...
%         'b)','edgecolor','k','fontsize',fontsize,'linewidth',1,'backgroundcolor','w','fontweight','bold'); 
% c) Hektoria & Green
cd([datapath,'terminus/regional/HekGreen/']); % enter folder 
files = dir('HekGreen*.shp'); % load file
% loop through files to grab centerline
for j=1:length(files)
    if contains(files(j).name,'CL')
        file = shaperead(files(j).name);
        cl.lon = file.X; % Lon
        cl.lat = file.Y; % Lat
        [cl.X,cl.Y] = wgs2ps(cl.lon,cl.lat,'StandardParallel',-71,'StandardMeridian',0);
        % define x as distance along centerline
        x = zeros(1,length(cl.X));
        for k=2:length(x)
            x(k) = sqrt((cl.X(k)-cl.X(k-1))^2+(cl.Y(k)-cl.Y(k-1))^2)+x(k-1); %(m)
        end
    end
end
% initialize f
clear f; files(1).lon = NaN; files(1).lat = NaN; files(1).date = NaN;
% loop through files to grab terminus positions
for j=1:length(files)
    if ~contains(files(j).name,'CL')
        file = shaperead(files(j).name);
        % loop through file
        for k=1:length(file)
            files(length(files)+1).lon = file(k).X; % Lon
            files(length(files)).lat = file(k).Y; % Lat
            % convert to polar stereographic coordinates
            [files(length(files)).X,files(length(files)).Y] = wgs2ps(files(length(files)).lon,files(length(files)).lat,'StandardParallel',-71,'StandardMeridian',0);
            files(length(files)).x = x(dsearchn([cl.X' cl.Y'],[nanmean(files(length(files)).X) nanmean(files(length(files)).Y)])); % x
        end
    end 
end
% plot
col1 = parula(length(files)); % color scheme for plotting
ax4=axes('position',[0.08 0.08 0.23 0.4]); hold on; grid on;      
    set(gca,'fontname',fontname,'fontsize',fontsize);
    xlabel('Easting [km]'); 
    ylabel('Northing [km]');
    title('c) Hektoria & Green');
    % plot landsat image
    colormap(ax4,'gray');
    imagesc(LSB.x/10^3,LSB.y/10^3,flipud(LSB.im)); 
    ax4.XLim = [-2.4364e3 -2.4164e3]; ax4.YLim = [1.3002e3 1.3201e3];        
    % plot centerline
    l4=line(cl.X(2:8)/10^3,cl.Y(2:8)/10^3,'color','k','linewidth',linewidth);
    % arrow
    line2arrow(l4,'color','k','linewidth',linewidth,'headwidth',20,'headlength',20);        
    % plot terminus positions
    for j=1:length(files)
        plot(files(j).X/10^3,files(j).Y/10^3,'color',col1(j,:),'linewidth',linewidth);
    end
%     text((ax4.XLim(2)-ax4.XLim(1))*0.08+ax4.XLim(1),(max(ax4.YLim)-min(ax4.YLim))*0.92+min(ax4.YLim),...
%         'c)','edgecolor','k','fontsize',fontsize,'linewidth',1,'backgroundcolor','w','fontweight','bold'); 
% d) Jorum
cd([datapath,'terminus/regional/Jorum/']); % enter folder 
files = dir('Jorum*.shp'); % load file
% loop through files to grab centerline
for j=1:length(files)
    if contains(files(j).name,'CL')
        file = shaperead(files(j).name);
        cl.lon = file.X; % Lon
        cl.lat = file.Y; % Lat
        [cl.X,cl.Y] = wgs2ps(cl.lon,cl.lat,'StandardParallel',-71,'StandardMeridian',0);
        % define x as distance along centerline
        x = zeros(1,length(cl.X));
        for k=2:length(x)
            x(k) = sqrt((cl.X(k)-cl.X(k-1))^2+(cl.Y(k)-cl.Y(k-1))^2)+x(k-1); %(m)
        end
    end
end
% initialize f
clear f; files(1).lon = NaN; files(1).lat = NaN; files(1).date = NaN;
% loop through files to grab terminus positions
for j=1:length(files)
    if ~contains(files(j).name,'CL')
        file = shaperead(files(j).name);
        % loop through file
        for k=1:length(file)
            files(length(files)+1).lon = file(k).X; % Lon
            files(length(files)).lat = file(k).Y; % Lat
            % convert to polar stereographic coordinates
            [files(length(files)).X,files(length(files)).Y] = wgs2ps(files(length(files)).lon,files(length(files)).lat,'StandardParallel',-71,'StandardMeridian',0);
            files(length(files)).x = x(dsearchn([cl.X' cl.Y'],[nanmean(files(length(files)).X) nanmean(files(length(files)).Y)])); % x
        end
    end 
end
% plot
col1 = parula(length(files)); % color scheme for plotting
ax5=axes('position',[0.39 0.08 0.23 0.4]); hold on; grid on;      
    set(gca,'fontname',fontname,'fontsize',fontsize);
    xlabel('Easting [km]'); 
    title('d) Jorum');
    % plot landsat image
    colormap(ax5,'gray');
    imagesc(LSB.x/10^3,LSB.y/10^3,flipud(LSB.im)); 
    ax5.XLim = [-2.4193e3 -2.4134e3]; ax5.YLim = [1.2762e3 1.2821e3];                
    % plot centerline
    l5=line(cl.X(5:10)/10^3,cl.Y(5:10)/10^3,'color','k','linewidth',linewidth);
    % arrow
    line2arrow(l5,'color','k','linewidth',linewidth,'headwidth',20,'headlength',20);        
    % plot terminus positions
    for j=1:length(files)
        plot(files(j).X/10^3,files(j).Y/10^3,'color',col1(j,:),'linewidth',linewidth);
    end
%     text((ax5.XLim(2)-ax5.XLim(1))*0.08+ax5.XLim(1),(max(ax5.YLim)-min(ax5.YLim))*0.92+min(ax5.YLim),...
%         'd)','edgecolor','k','fontsize',fontsize,'linewidth',1,'backgroundcolor','w','fontweight','bold'); 
% e) Crane
cd([datapath,'terminus/regional/Crane/']); % enter folder 
files = dir('Crane*.shp'); % load file
% loop through files to grab centerline
for j=1:length(files)
    if contains(files(j).name,'CL')
        file = shaperead(files(j).name);
        cl.lon = file.X; % Lon
        cl.lat = file.Y; % Lat
        [cl.X,cl.Y] = wgs2ps(cl.lon,cl.lat,'StandardParallel',-71,'StandardMeridian',0);
        % define x as distance along centerline
        x = zeros(1,length(cl.X));
        for k=2:length(x)
            x(k) = sqrt((cl.X(k)-cl.X(k-1))^2+(cl.Y(k)-cl.Y(k-1))^2)+x(k-1); %(m)
        end
    end
end
% initialize f
clear f; files(1).lon = NaN; files(1).lat = NaN; files(1).date = NaN;
% loop through files to grab terminus positions
for j=1:length(files)
    if ~contains(files(j).name,'CL')
        file = shaperead(files(j).name);
        % loop through file
        for k=1:length(file)
            files(length(files)+1).lon = file(k).X; % Lon
            files(length(files)).lat = file(k).Y; % Lat
            % convert to polar stereographic coordinates
            [files(length(files)).X,files(length(files)).Y] = wgs2ps(files(length(files)).lon,files(length(files)).lat,'StandardParallel',-71,'StandardMeridian',0);
            files(length(files)).x = x(dsearchn([cl.X' cl.Y'],[nanmean(files(length(files)).X) nanmean(files(length(files)).Y)])); % x
        end
    end 
end
% plot
col1 = parula(length(files)); % color scheme for plotting
ax6=axes('position',[0.72 0.08 0.23 0.4]); hold on; grid on;      
    set(gca,'fontname',fontname,'fontsize',fontsize);
    xlabel('Easting [km]'); 
    title('e) Crane');
    % plot landsat image
    colormap(ax6,'gray');
    imagesc(LSB.x/10^3,LSB.y/10^3,flipud(LSB.im)); 
    ax6.XLim=[-2.4132e3 -2.4005e3]; ax6.YLim=[1.2635e3 1.2762e3];                
    % plot centerline
    l6=line(cl.X(6:13)/10^3,cl.Y(6:13)/10^3,'color','k','linewidth',linewidth);
    % arrow
    line2arrow(l6,'color','k','linewidth',linewidth,'headwidth',20,'headlength',20);        
    % plot terminus positions
    for j=1:length(files)
        plot(files(j).X/10^3,files(j).Y/10^3,'color',col1(j,:),'linewidth',linewidth);
    end
%     text((ax6.XLim(2)-ax6.XLim(1))*0.08+ax6.XLim(1),(max(ax6.YLim)-min(ax6.YLim))*0.92+min(ax6.YLim),...
%         'e)','edgecolor','k','fontsize',fontsize,'linewidth',1,'backgroundcolor','w','fontweight','bold'); 

% save figure
if save_figure
    exportgraphics(figure(4),[outpath,'regional_termini.png'],'Resolution',300);
    exportgraphics(figure(4),[outpath,'regional_termini.eps'],'Resolution',300);
    disp('figure 4 saved');
end

%% Width segments

save_figure = 0; % = 1 to save figure
linewidth = 2; 
markersize = 15;

% Load Landsat image, width, width segments, and glacier extent polygon
cd([datapath, 'imagery/']);
ls = dir('LC08*20201104_01_T2_B8.TIF');
[LS.im,R] = readgeoraster(ls.name); [LS.ny,LS.nx] = size(LS.im);
% Polar stereographic coordinates of image boundaries
LS.x = linspace(min(R.XWorldLimits),max(R.XWorldLimits),LS.nx);
LS.y = linspace(min(R.YWorldLimits),max(R.YWorldLimits),LS.ny);
cd([basepath,'inputs-outputs/']);
cl.X = load('Crane_centerline.mat').x; cl.Y = load('Crane_centerline.mat').y;
extx = load('observed_glacier_width.mat').width.extx;
exty = load('observed_glacier_width.mat').width.exty;
W = load('observed_glacier_width.mat').width.W;
ol = load('observed_glacier_outline.mat').ol;
% load observed terminus positions
file = shaperead([datapath,'terminus/regional/Crane/Crane_2000-01-01_2021-03-17.shp']);
[termX,termY] = wgs2ps(file(end).X,file(end).Y,'StandardParallel',-71,'StandardMeridian',0);
termx = cl.xi(dsearchn([cl.Xi cl.Yi], [termX(4), termY(4)]));

% Plot
col = flipud(cmocean('ice',5)); % color scheme for potting
figure(5); clf
set(gcf,'units','pixels','position',[200 200 800 800],'defaultAxesColorOrder',[[1 1 1];[0 0 0]]);
ax1 = axes('position',[0.08 0.1 0.6 0.85]);
    hold on; imagesc(LS.x/10^3,LS.y/10^3,flipud(LS.im)); colormap("gray");
    set(gca,'fontsize',fontsize,'linewidth',linewidth,'XTick',-2430:10:-2385); 
    xlabel('Easting [km]'); ylabel('Northing [km]'); 
    legend('Location','east','color',[0.8,0.8,0.8]);
    xlim([-2.43e3 -2.385e3]); 
    ylim([1.21e3 1.285e3]); 
    % glacier extent
    fill(ol.x/10^3,ol.y/10^3,col(1,:),'displayname','glacier extent');
    % glacier width segments
    for i=1:length(extx)
        if i==1
            plot(extx(i,:)/10^3,exty(i,:)/10^3,'color',col(2,:),'linewidth',linewidth,'displayname','width segments');
        else
            plot(extx(i,:)/10^3,exty(i,:)/10^3,'color',col(2,:),'linewidth',linewidth,'HandleVisibility','off');        
        end
    end
    % centerline
    plot(cl.X/10^3,cl.Y/10^3,'color',col(3,:),'linewidth',linewidth,'displayname','centerline');
    % 2019 calving front position
    plot(termX/10^3, termY/10^3,'--k','markersize',markersize,'linewidth',linewidth,'displayname','2019 calving front');
    % a text label
    text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.02+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.05+min(get(gca,'YLim')),...
            'a)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold'); 
ax2 = axes('position',[0.74 0.245 0.2 0.63]);
    hold on; set(gca,'fontsize',fontsize,'linewidth',linewidth,'XDir','reverse');
    xlabel('Width [km]'); 
    xlim([0 10]);    
    % width
    plot(ax2, W/10^3,cl.xi/10^3,'color',col(3,:),'linewidth',linewidth); grid on; 
    % 2019 calving front position
    plot([0 20], [termx/10^3 termx/10^3], '--k','linewidth',linewidth);
    ylabel('Distance along centerline [km]'); 
    text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.95+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.05+min(get(gca,'YLim')),...
            'b)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold'); 
        
% save figure
if save_figure
    exportgraphics(figure(5),[outpath,'width_segments.png'],'Resolution',300);
    exportgraphics(figure(5),[outpath,'width_segments.eps'],'Resolution',300);
    disp('figure 5 saved');
end

%% Bed picks, other bed models

save_figure = 1; % = 1 to save figure
linewidth = 2; 

% add path to IceBridge functions
addpath([basepath,'functions/IceBridge/functions/']);

% load raw picks
rawX = load([basepath,'inputs-outputs/OIBpicks_raw.mat']).RawX;
rawY = load([basepath,'inputs-outputs/OIBpicks_raw.mat']).RawY;

% load other bed observations
b_SOM = load([basepath,'inputs-outputs/observed_bed_elevations.mat']).b_cl_SOM;
b_BM = load([basepath,'inputs-outputs/observed_bed_elevations.mat']).b_cl_BM;
b_bathym = load([basepath,'inputs-outputs/observed_bed_elevations.mat']).bathym;
b0 = load([basepath,'inputs-outputs/observed_bed_elevations.mat']).HB.hb0;

gl_col = [254,178,76]./255; % color for plotting grounding line location

% load radar echogram (using workflow from main_L1B.m)
mdata = load_L1B([datapath, 'bed_elevations/OIB_L1B/IRMCR1B_20181016_01_005.nc']);
param.ylims_bins = [-inf inf];
good_bins = round(max(1,min(mdata.Surface)+param.ylims_bins(1)) : min(max(mdata.Surface)+param.ylims_bins(2),size(mdata.Data,1)));
% Apply AGC 
isGain = 1;
if isGain
    mdata.gainData = AGCgain(mdata.Data(good_bins,:),50,2);
end
% Elevation Correction
param = [];
if isGain
param.gain = true;
end
param.update_surf = false;
param.filter_surf = true;
param.er_ice = 3.15; % electric permitivity
param.depth = '[min(Surface_Elev)-2000 max(Surface_Elev)+25]';
% param.depth = '[min(Surface_Elev) max(Surface_Elev)]';
[mdata_WGS84,depth_good_idxs] = elevation_compensation(mdata,param);
% Compute Distance Along Fly Line
[mdata_WGS84.Easting,mdata_WGS84.Northing] = ll2utm(mdata_WGS84.Latitude, mdata_WGS84.Longitude);
UTMe = mdata_WGS84.Easting;
UTMn = mdata_WGS84.Northing;
Elvis = mdata_WGS84.Elevation;
% Euclidian Distance
for jj = 1:length(UTMe)-1
    D(jj) = sqrt( (UTMe(jj+1)-UTMe(jj))^2 + (UTMn(jj+1)-UTMn(jj))^2 + (Elvis(jj+1)-Elvis(jj))^2);
end
D = [0,D];
GPSlength = cumsum(D);
% Store in Data Structure
mdata_WGS84.Distance = GPSlength;
[mdata_WGS84.Easting,mdata_WGS84.Northing] = ...
    wgs2ps(mdata_WGS84.Longitude,mdata_WGS84.Latitude,...
    'StandardParallel',-71,'StandardMeridian',0);
clear('UTMe','UTMn','Elvis','D')

% -----plot
% Bed picks vs. WGS84 elevation
figure(6); clf;
set(gcf,'position',[-1000 100 1000 1000]);
ax1 = axes('position',[0.1 0.45 0.85 0.53],'YDir','normal','fontsize',fontsize,'fontname',fontname); hold on; 
    imagesc(ax1, mdata_WGS84.Distance/1000,mdata_WGS84.Elevation_Fasttime(depth_good_idxs),...
        mdata_WGS84.Data(depth_good_idxs,:));
    xlabel('Distance along fly line [km]');
    ylabel('Elevation [m]');
    colormap('bone');
    set(ax1,'CLim',[-1.1 -0.9]);
    xlim([0 50]);
    ylim([-1500 850]);
% 2018 grounding line location
gl_mdata_WGS84_interp = mdata_WGS84.Distance(dsearchn([mdata_WGS84.Easting, mdata_WGS84.Northing], [Xgl_2018, Ygl_2018]));
plot(ax1, [gl_mdata_WGS84_interp/1e3, gl_mdata_WGS84_interp/1e3], [-1500 850], 'color', gl_col, 'linewidth', linewidth, 'handlevisibility', 'off');
% Surface and bed picks
plot(ax1,mdata_WGS84.Distance/1000,mdata_WGS84.Surface_Elev,'-b','linewidth',2,'displayname','Surface picks');
plot(ax1,rawX,rawY,'ok','linewidth',1.5,'displayname','Bed picks');
legend('Location','southwest'); 
% add text label            
text((max(get(ax1,'XLim'))-min(get(ax1,'XLim')))*0.02+min(get(ax1,'XLim')),...
    (max(get(ax1,'YLim'))-min(get(ax1,'YLim')))*0.96+min(get(ax1,'YLim')),...
    'a)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold'); 
% Inset plot: Landsat image, flight path, centerline
cd([datapath,'imagery/']);
landsat = dir('LC08_L1GT_218106_20201015_20201104_01_T2_B8.TIF');
[LS.im,LS.R] = readgeoraster(landsat.name); [LS.ny,LS.nx] = size(LS.im);
% polar stereographic coordinates of image boundaries
LS.x = linspace(min(LS.R.XWorldLimits),max(LS.R.XWorldLimits),LS.nx); 
LS.y = linspace(min(LS.R.YWorldLimits),max(LS.R.YWorldLimits),LS.ny);
ax2 = axes('pos',[0.69 0.46 0.25 0.23],'fontname','Arial','fontsize',fontsize,...
    'XTickLabels',[],'YTickLabels',[],'linewidth',2);
    hold on; 
    imagesc(ax2,LS.x/1e3,LS.y/1e3,flipud(LS.im*1.1)); 
    colormap('gray');
    set(ax2,'CLim',[0 40e3]);
    plot(ax2,cl.X/1e3,cl.Y/1e3,'-.m','linewidth',2,'displayname','Centerline');
    plot(ax2,mdata_WGS84.Easting/1e3,mdata_WGS84.Northing/1e3,'-b','linewidth',2,'displayname','OIB fly line');
    scatter(ax2, Xgl_2018/1e3, Ygl_2018/1e3, 'x', 'markerfacecolor', gl_col, 'markeredgecolor', gl_col, 'linewidth', linewidth, 'displayname','2018 x_{gl}');
    legend('Location','east');
    xlim([-2.4293 -2.3574].*1e3); 
    ylim([1.2119 1.2812].*1e3);
% other bed models
ax3 = axes('pos',[0.1 0.06 0.85 0.32],'fontname','Arial','fontsize',fontsize,...
    'XDir','reverse');
    hold on; grid on;
    xlabel('Distance along centerline [km]');
    ylabel('Elevation [m]');
    legend('location','southeast');
    ci=157;
    h_interp = mdata_WGS84.Surface_Elev(dsearchn([mdata_WGS84.Easting, mdata_WGS84.Northing], [cl.Xi, cl.Yi]));
    rawY_interp = interp1(rawX*1000, rawY, mdata_WGS84.Distance); 
    b_interp = rawY_interp(dsearchn([mdata_WGS84.Easting, mdata_WGS84.Northing], [cl.Xi, cl.Yi]));
    plot(ax3, [xgl_2018/10^3 xgl_2018/10^3], [-2200 1000], '-', 'linewidth',linewidth, 'color', gl_col, 'handlevisibility','off');
    plot(ax3, cl.xi/10^3, h_interp, '-b','linewidth',linewidth,'displayname','Surface picks');    
    plot(ax3, cl.xi/10^3, b_interp, '-k','linewidth',linewidth,'displayname','Bed picks');
    plot(ax3, cl.xi/10^3,b_SOM,'--k','linewidth',linewidth,'displayname','Huss and Farinotti (2014)');
    plot(ax3, cl.xi/10^3,b_BM,':k','linewidth',linewidth,'displayname','BedMachine Antarctica');
    plot(ax3, cl.xi/10^3,b_bathym,'xk','linewidth',linewidth,'markersize', 8, 'displayname','Rebesco et al. (2014)');
    xlim([6.5 56.5]);
    ylim([-2200 1000]);
% add text label            
text((max(get(ax3,'XLim'))-min(get(ax3,'XLim')))*0.98+min(get(ax3,'XLim')),...
    (max(get(ax3,'YLim'))-min(get(ax3,'YLim')))*0.94+min(get(ax3,'YLim')),...
    'b)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');

if save_figure
    exportgraphics(figure(6),[outpath,'bed_picks.png'],'Resolution',300);
    exportgraphics(figure(6),[outpath,'bed_picks.eps'],'Resolution',300);
    disp('figure 6 saved');
end

%% Cumulative Strain Rates, Rate Factor A, & Basal Roughness Factor Beta

save_figure = 0; 
linewidth = 2;

% load rate factor
A = load([basepath,'inputs-outputs/modeled_rate_factor.mat']).A;
% load adjusted rate factor
A_adj = load([basepath,'inputs-outputs/modeled_rate_factor.mat']).A_adj;
% load annual cumulative strain rates
eta_dot_cum = load([basepath,'inputs-outputs/modeled_rate_factor.mat']).eta_dot_cum; 
eta_dot_cum_years = load([basepath,'inputs-outputs/modeled_rate_factor.mat']).eta_dot_cum_years;
% years associated with each row
years = [2013:2017 1995];
% define basal roughness
beta0 = interp1([0 x0(end)], [0.5 2], x0); 

% plot
col1 = parula(length(1995:2019)); % color scheme for plotting
figure(7); clf; 
set(gcf,'Position',[-1000 50 750 650],'defaultAxesColorOrder',[[0 0.4 0.8];[0 0 0]]);
ax1 = axes('pos',[0.1 0.35 0.8 0.6]);
set(ax1,'linewidth',2,'fontsize',fontsize,'fontname',fontname,'XTickLabels',[]);
yyaxis left; 
    xlim([0 45]); 
    ylim([-0.36 1.5]); 
    %ylabel('$$ \Sigma ( \dot{\eta} ) (s^{-1})$$','Interpreter','latex','fontname','Arial','fontsize',18);
    ylabel('Cumulative strain rate');
    hold on; grid on; 
    plot(ax1, cl.xi(1:135)/10^3,eta_dot_cum(end,1:135),'-','color',col1(1,:),'linewidth',linewidth,'displayname','Pre-collapse'); drawnow    
    for i=1:length(eta_dot_cum(:,1))-1
        plot(ax1, cl.xi(1:135)/10^3,eta_dot_cum(i,1:135),'-','color',col1(i+18,:),'linewidth',linewidth,'DisplayName',num2str(eta_dot_cum_years(i))); drawnow
    end
    % add text label            
    text((max(get(ax1,'XLim'))-min(get(ax1,'XLim')))*0.02+min(get(ax1,'XLim')),...
        (max(get(ax1,'YLim'))-min(get(ax1,'YLim')))*0.96+min(get(ax1,'YLim')),...
        'a)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');
yyaxis right; 
    ylabel('Rate factor [Pa^{-3} yr^{-1}]'); 
    colormap(col1);
    hold on; grid on; 
    xlim([0 45]); 
    ylim([0.91e-17 1.92e-17]);
    % legend
    legend('position',[0.15 0.7 0.1 0.08]);
    plot(ax1,cl.xi(1:135)/10^3,A(1:135)*3.1536e7,'--k','linewidth',linewidth+0.5,'displayname','A');
    plot(ax1,cl.xi(1:135)/10^3,A_adj(1:135)*3.1536e7,'-k','linewidth',linewidth+0.5,'displayname','A_{adj}');
ax2 = axes('pos',[0.1 0.08 0.8 0.25]); hold on;
set(ax2,'linewidth',2,'fontsize',fontsize,'fontname',fontname);
    xlabel('Distance along centerline [km]'); 
    ylabel('\beta [s^{1/m} m^{-1/m}]');
    xlim([0, 45]);
    grid on;
    plot(ax2,x0/10^3, beta0, '-b','linewidth',linewidth);
    % add text label            
    text((max(get(ax2,'XLim'))-min(get(ax2,'XLim')))*0.02+min(get(ax2,'XLim')),...
        (max(get(ax2,'YLim'))-min(get(ax2,'YLim')))*0.92+min(get(ax2,'YLim')),...
        'b)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');
    
% save figure
if save_figure
    exportgraphics(figure(7),[outpath,'rate_factor+basal_roughness.png'],'Resolution',300); 
    exportgraphics(figure(7),[outpath,'rate_factor+basal_roughness.eps'],'Resolution',300);      
    disp('figure 7 saved.'); 
end
        

%% Hindcasting simulation evolution

% -----Load steady-state conditions
xi = load([basepath,'inputs-outputs/modeled_steady_state_conditions.mat']).x;
bi = load([basepath,'inputs-outputs/modeled_steady_state_conditions.mat']).b;
hi = load([basepath,'inputs-outputs/modeled_steady_state_conditions.mat']).h;
Hi = load([basepath,'inputs-outputs/modeled_steady_state_conditions.mat']).H;
ci = load([basepath,'inputs-outputs/modeled_steady_state_conditions.mat']).c;
Ui = load([basepath,'inputs-outputs/modeled_steady_state_conditions.mat']).U;

% -----Load modeled conditions
mod_cond = load([basepath,'inputs-outputs/modeled_conditions_2002-2100_unperturbed.mat']).mod_cond;
mod_cond_hind = mod_cond(1:17); % subset to just 2002-2018

% -----Plot conditions
linewidth=1; 
figure(8); clf; 
set(gcf,'Position',[-1000 50 800 600]);
% geometry
axA = axes('position', [0.09, 0.55, 0.75, 0.4]);
legend('position', [0.87, 0.75, 0.1, 0.05]);
hold on; grid on;
ylabel('Elevation [m]')
% speed
axB = axes('position', [0.09, 0.08, 0.75, 0.4]);
hold on; grid on;
xlabel('Distance along centerline [km]');
ylabel('Speed [m yr^{-1}]');
% initial 
plot(axA, x0(1:c0)/1e3, h0(1:c0), '-', 'color', [152,0,67]./256, 'linewidth', 2, 'displayname', 'Initial');
plot(axA, [x0(c0)/1e3, x0(c0)/1e3], ...
    [h0(c0), b0(c0)], '-', 'color', [103,0,31]./256, 'linewidth', 2, 'handlevisibility', 'off');
plot(axB, x0(1:c0)/1e3, U0(1:c0)*3.1536e7, '-', 'color', [152,0,67]./256, 'linewidth', 2, 'displayname', 'Initial');
% steady state
plot(axA, xi/1e3, hi, '-m', 'linewidth', 2, 'displayname', 'Steady-state');
plot(axA, [xi(ci)/1e3, xi(ci)/1e3], ...
    [hi(ci), hi(ci) - Hi(ci)], '-m', 'linewidth', 2, 'handlevisibility', 'off');
plot(axA, x0/1e3, b0, '-k', 'linewidth', linewidth, 'displayname', 'Bed');
plot(axB, xi/1e3, Ui*3.1536e7, '-m', 'linewidth', 2, 'handlevisibility', 'off');
% 2002 - 2018
col = parula(length(mod_cond_hind)+1);
col(end, :) = [];
for i=1:length(mod_cond_hind)
    c = mod_cond_hind(i).c;
    gl = mod_cond_hind(i).gl;
    plot(axA, mod_cond_hind(i).x(1:c)/1e3, mod_cond_hind(i).h(1:c), ...
        '-', 'color', col(i,:), 'linewidth', linewidth,'handlevisibility', 'off');
    plot(axA, mod_cond_hind(i).x(gl+1:c)/1e3, mod_cond_hind(i).h(gl+1:c) - mod_cond_hind(i).H(gl+1:c), ...
        '-', 'color', col(i,:), 'linewidth', linewidth, 'handlevisibility', 'off');
    plot(axA, [mod_cond_hind(i).x(c)/1e3, mod_cond_hind(i).x(c)/1e3], ...
        [mod_cond_hind(i).h(c), mod_cond_hind(i).h(c) - mod_cond_hind(i).H(c)], ...
        '-', 'color', col(i,:), 'linewidth', linewidth, 'handlevisibility', 'off');
    plot(axB, mod_cond_hind(i).x(1:c)/1e3, mod_cond_hind(i).U(1:c)*3.1536e7, ...
        '-', 'color', col(i,:), 'linewidth', linewidth, 'handlevisibility', 'off');    
end

set(axA, 'Xlim', [0, 60], 'fontsize', 16, 'linewidth', 1);
text(axA, (max(get(axA,'XLim'))-min(get(axA,'XLim')))*0.95+min(get(axA,'XLim')),...
    (max(get(axA,'YLim'))-min(get(axA,'YLim')))*0.9+min(get(axA,'YLim')),...
    'a)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth,'fontweight','bold');
set(axB, 'Xlim', [0, 60], 'fontsize', 16, 'linewidth', 1);
text(axB, (max(get(axB,'XLim'))-min(get(axB,'XLim')))*0.95+min(get(axB,'XLim')),...
    (max(get(axB,'YLim'))-min(get(axB,'YLim')))*0.9+min(get(axB,'YLim')),...
    'b)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth,'fontweight','bold');
colormap(col);
colorbar('position', [0.9, 0.2, 0.02, 0.5], ...
    'Ticks', [0.03, 0.5, 0.97], 'TickLabels', {'2002', '2010', '2018'});

% -----Save figure
exportgraphics(figure(8),[outpath,'model_hindcasting_simulation.png'],'Resolution',300);
disp('figure 8 saved.')

%% 2007-2018 Model Misfits
    
save_figure = 0;       % = 1 to save figure
linewidth = 1.5; 

% -----Load observed 2007-2018 conditions
% ice surface
h_obs = load([basepath,'inputs-outputs/observed_surface_elevations.mat']).h;
Ih_obs = 8:13; % indices for 2009-2011, 2016-2018 observed surface elevation
% ice speed
U_obs = load([basepath,'inputs-outputs/observed_surface_speeds.mat']).U;
IU_obs = 15:21; % indices for 2011-2017 observed surface speed
% terminus position
termX = load([basepath,'inputs-outputs/LarsenB_centerline.mat']).centerline.termx;
termY = load([basepath,'inputs-outputs/LarsenB_centerline.mat']).centerline.termy;
termx = cl.xi(dsearchn([cl.Xi cl.Yi],[termX' termY']));
termdate = load([basepath,'inputs-outputs/LarsenB_centerline.mat']).centerline.termdate;
clear termX termY termx termdate

% -----Load modeled 2007-2018 conditions
mod_cond = load([basepath,'inputs-outputs/modeled_conditions_2007-2018.mat']).mod_cond;
Ih_mod = [3:5, 10:12]; % indices for 2009-2011, 2016-2018 modeled surface elevation
IU_mod = 5:11; % indices for 2007-2017 observed surface speed

% color scheme for plotting time series
col = parula(length(2007:2018)+1); 

% plot
figure(8); clf;
set(gcf,'position',[-1000 200 1000 700],'defaultAxesColorOrder',[[0 0 0];[0.8 0.1 0.1]]);
% modeled surface elevation
ax1 = axes('position',[0.08 0.55 0.4 0.4]); hold on; 
    grid on;
%     xlim([25 60]);
    ylim([0 1000]);
    ylabel('Modeled surface elevation [m]');
    legend('location','northeast');
    set(gca,'fontsize',fontsize,'fontname','Arial','linewidth',2); 
    % grounding line location
    plot(ax1, [mod_cond(end).x(mod_cond(end).gl)/10^3 mod_cond(end).x(mod_cond(end).gl)/10^3],...
        [min(get(ax1,'YLim')) max(get(ax1,'YLim'))],'-k','linewidth',linewidth,'HandleVisibility','off');
    for i=1:length(mod_cond)
        plot(ax1, mod_cond(i).x/10^3, mod_cond(i).h, 'linewidth', linewidth, 'color', col(i,:), 'displayname', num2str(mod_cond(i).year));
    end
    % add text label            
    text((max(get(ax1,'XLim'))-min(get(ax1,'XLim')))*0.9+min(get(ax1,'XLim')),...
        (max(get(ax1,'YLim'))-min(get(ax1,'YLim')))*0.1+min(get(ax1,'YLim')),...
        'a)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');
% modeled flow speed
ax2 = axes('position',[0.56 0.55 0.4 0.4],'YTick',0:400:1600); hold on; 
    set(gca,'fontsize',fontsize,'fontname','Arial','linewidth',2); 
    grid on;
    ylabel('Modeled flow speed [m yr^{-1}]');
%     xlim([25 60]);
    ylim([0 1700]);
    % grounding line location
    plot(ax2, [mod_cond(end).x(mod_cond(end).gl)/10^3 mod_cond(end).x(mod_cond(end).gl)/10^3],...
        [min(get(ax2,'YLim')) max(get(ax2,'YLim'))],'-k','linewidth',linewidth,'displayname','2018 gl');
    for i=1:length(mod_cond)
        plot(ax2, mod_cond(i).x/10^3, mod_cond(i).U*3.1536e7, 'linewidth', linewidth, 'color', col(i,:), 'displayname', num2str(mod_cond(i).year));
    end
    % add text label            
    text((max(get(ax2,'XLim'))-min(get(ax2,'XLim')))*0.9+min(get(ax2,'XLim')),...
        (max(get(ax2,'YLim'))-min(get(ax2,'YLim')))*0.1+min(get(ax2,'YLim')),...
        'b)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');    
% surface elevation misfit
ax3 = axes('position',[0.08 0.1 0.4 0.4]); hold on; 
grid on;
    set(gca,'fontsize',fontsize,'fontname','Arial','linewidth',2);
    xlabel('Distance along centerline [km]');
    ylabel('Surface elevation misfit [m]');  
%     xlim([25 60]);
    ylim([-75 125]);
    % grounding line location
    plot(ax3, [mod_cond(end).x(mod_cond(end).gl)/10^3 mod_cond(end).x(mod_cond(end).gl)/10^3],...
        [min(get(ax3,'YLim')) max(get(ax3,'YLim'))],'-k','linewidth',linewidth,'displayname','2018 gl');
    for i=1:length(Ih_obs)
        % dataset error
        h_err = 22; % surface elevation observational error margin [m]
        % interpolate observed surface elevation to model grid coordinates
        h_obsi = interp1(cl.xi, h_obs(Ih_obs(i)).h_centerline, mod_cond(Ih_mod(i)).x);
        % difference between modeled and observed
        misfit = mod_cond(Ih_mod(i)).h - h_obsi; 
        % adjust misfit for dataset error
        misfit(misfit<0) = misfit(misfit<0) + h_err;
        misfit(misfit>0) = misfit(misfit>0) - h_err;
        plot(ax3, mod_cond(Ih_mod(i)).x/10^3, misfit,'linewidth', linewidth, 'color', col(Ih_mod(i),:), 'displayname', num2str(mod_cond(Ih_mod(i)).year));
    end
    % add text label            
    text((max(get(ax3,'XLim'))-min(get(ax3,'XLim')))*0.9+min(get(ax3,'XLim')),...
        (max(get(ax3,'YLim'))-min(get(ax3,'YLim')))*0.1+min(get(ax3,'YLim')),...
        'c)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');    
% flow speed misfit
ax4 = axes('position',[0.56 0.1 0.4 0.4]); hold on; 
grid on;
    set(gca,'fontsize',fontsize,'fontname','Arial','linewidth',2);
    xlabel('Distance along centerline [km]');
    ylabel('Flow speed misfit [m yr^{-1}]'); 
    xlim([0 60]);
    ylim([-600 850]);
    % grounding line location
    plot(ax4, [mod_cond(end).x(mod_cond(end).gl)/10^3 mod_cond(end).x(mod_cond(end).gl)/10^3],...
        [min(get(ax4,'YLim')) max(get(ax4,'YLim'))],'-k','linewidth',linewidth,'displayname','2018 gl');
    for i=1:length(IU_obs)
        % dataset error
        U_err = interp1(cl.xi, U_obs(IU_obs(i)).U_err, mod_cond(IU_mod(i)).x); 
        % difference between modeled and observed
        % interpolate observed surface speed to model grid coordinates
        U_obsi = interp1(cl.xi, U_obs(IU_obs(i)).U_width_ave, mod_cond(IU_mod(i)).x);
        % difference between modeled and observed
        misfit = mod_cond(IU_mod(i)).U - U_obsi;
        % adjust misfit for dataset error
        misfit(misfit<0) = misfit(misfit<0) + U_err(misfit<0);
        misfit(misfit>0) = misfit(misfit>0) - U_err(misfit>0);
        % plot 
        plot(ax4, mod_cond(IU_mod(i)).x/10^3, misfit.*3.1536e7,...
            'linewidth', linewidth, 'color', col(IU_mod(i),:), 'displayname', num2str(mod_cond(IU_mod(i)).year));
    end
    % add text label            
    text((max(get(ax4,'XLim'))-min(get(ax4,'XLim')))*0.9+min(get(ax4,'XLim')),...
        (max(get(ax4,'YLim'))-min(get(ax4,'YLim')))*0.1+min(get(ax4,'YLim')),...
        'd)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');    

   
% save figure
if save_figure
    exportgraphics(figure(8),[outpath,'model_misfits_2007-2018.png'],'Resolution',300);
    exportgraphics(figure(8),[outpath,'model_misfits_2007-2018.eps'],'Resolution',300);
    disp('figure 8 saved');
end

%% Sensitivity Tests

save_figures = 0;    % = 1 to save figure
fontsize = 16;      % font size
fontname = 'Arial'; % font name
linewidth = 2;      % line width
markersize = 10;    % marker size
print_tables = 0;   % = 1 to print data tables in LaTeX format

% load modeled conditions
% 2100: unperturbed scenario
load([basepath,'inputs-outputs/modeled_conditions_2100_unperturbed.mat']);
% 2018
H18 = load([basepath,'inputs-outputs/modeled_conditions_2007-2018.mat']).mod_cond(end).H;
U18 = load([basepath,'inputs-outputs/modeled_conditions_2007-2018.mat']).mod_cond(end).U;
c18 = load([basepath,'inputs-outputs/modeled_conditions_2007-2018.mat']).mod_cond(end).c;
h18 = load([basepath,'inputs-outputs/modeled_conditions_2007-2018.mat']).mod_cond(end).h;
% hb18 = load([homepath,'inputs-outputs/modeled_conditions_2007-2018.mat']).mod_cond(end).b;
x18 = load([basepath,'inputs-outputs/modeled_conditions_2007-2018.mat']).mod_cond(end).x;
% model initialization parameters
W0 = load([basepath,'inputs-outputs/model_initialization_pre-collapse.mat']).W0;
b0 = load([basepath,'inputs-outputs/model_initialization_pre-collapse.mat']).b0;
h0 = load([basepath,'inputs-outputs/model_initialization_pre-collapse.mat']).h0;
x0 = load([basepath,'inputs-outputs/model_initialization_pre-collapse.mat']).x0;
c0 = load([basepath,'inputs-outputs/model_initialization_pre-collapse.mat']).c0;
RO0 = load([basepath,'inputs-outputs/model_initialization_pre-collapse.mat']).RO0;
% median DFW_min
DFW_min = 10; % m
% mean SMB over time: unperturbed scenario
smb_mean = load([basepath,'inputs-outputs/2100_SMB_mean.mat']).smb_mean;
% pre-collapse ice mass discharge
Fgl_preCollapse = load([basepath,'inputs-outputs/modeled_discharge_pre-collapse.mat']).Fgl_preCollapse;
Fgl_preCollapse(end-10:end) = Fgl_preCollapse(end-10);
% modeled backstress
hindcast = load([basepath,'inputs-outputs/modeled_hindcasting_simulation_conditions.mat']).hindcast;
mod_cond = load([basepath,'inputs-outputs/modeled_conditions_2002-2100_unperturbed.mat']).mod_cond;
% load observed discharge and calving front positions
% Rignot et al. (2004) discharge observations 
% F_obs: [deciyear  discharge(km^3 yr^{-1})  error(km^3 yr^{-1})]
F_obs = [1996 2.6; 2003+2.75/12 5.6; 2003+3.2/12 6.8; 2003+3.5/12 7.6];
F_obs_err = [sqrt(2.6^2*((100/700)^2 + (100/700)^2 + 2*(100*100)/(700*700)));...
    sqrt(5.6^2*((100/2000)^2 + (100/700)^2 + 2*(100*100)/(2000*700)));...
    sqrt(6.8^2*((100/1600)^2 + (100/700)^2 + 2*(100*100)/(1600*700)));...
    sqrt(7.6^2*((100/1300)^2 + (100/700)^2 + 2*(100*100)/(1300*700)))];
% convert to Gt/a
% (km^3/a)*(10^9 m^3/km^3)*(917 kg/m^3)*(10^-3 ton/kg)*(10^-9 Gt/ton) = Gt/a
F_obs(:,2) = F_obs(:,2).*10^9.*917.*10^-3.*10^-9; % Gt/a
F_obs_err = F_obs_err.*10^9.*917.*10^-3.*10^-9; % Gt/a
% load observed terminus positions
termX = load([basepath,'inputs-outputs/LarsenB_centerline.mat']).centerline.termx;
termY = load([basepath,'inputs-outputs/LarsenB_centerline.mat']).centerline.termy;
termx = cl.xi(dsearchn([cl.Xi cl.Yi],[termX' termY']));
termdate = load([basepath,'inputs-outputs/LarsenB_centerline.mat']).centerline.termdate;
% load observed speed, width, and modeled thickness
U = load([basepath,'inputs-outputs/observed_surface_speeds.mat']).U;
h = load([basepath,'inputs-outputs/observed_surface_elevations.mat']).h;
os.years = 2016:2017;
os.xcf = interp1(termdate, termx, os.years); % calving front position (m along centerline)
os.c = dsearchn(cl.xi',os.xcf'); % calving front indices
os.W = W0(os.c); % (m along centerline)
os.h = 30*ones(1,length(os.years));
% for i=1:length(os.years)
%     os.h(i) = h(i+7).h_centerline(os.c(i)); % surface elevation (m) 
%     if os.h(i) < 0
%         os.h(i) = h(i+7).h_centerline(find(h(i+7).h_centerline > 0,1, 'last'));
%     end
% end
os.Hf = (1000/(1000-917)).*os.h; % flotation thickness (m)
os.U = [U(20).U_width_ave(os.c(1)) U(21).U_width_ave(os.c(2))]; % 2016:2017
%[U(13).U_width_ave(os.c(1)) U(14).U_width_ave(os.c(2)) U(15).U_width_ave(os.c(3))... % 2009:2011
% calculate F_obs, convert to Gt/a, and append to vector array
% (m^3/s)*(3.1536e7 s/a)*(917 kg/m^3)*(10^-3 ton/kg)*(10^-9 Gt/ton)
% use the mean of a rectangular and ellipsoidal bed
F_obs = [F_obs; os.years' (os.W.*os.Hf.*os.U.*3.1536e7*917.*10^-3.*10^-9*pi*1/4)']; % Gt/a;
F_obs_err(5:6) = [sqrt(F_obs(5,2)^2*((31/(os.U(1).*3.1536e7))^2 + (10.1/os.Hf(1))^2 + 2*(31*10.1)/(os.U(1)*3.1536e7*os.Hf(1)))).*10^9.*917.*10^-3.*10^-9;... % Gt/a
    sqrt(F_obs(6,2)^2*((31/(os.U(2).*3.1536e7))^2 + (10.1/os.Hf(2))^2 + 2*(31*10.1)/(os.U(2)*3.1536e7*os.Hf(2)))).*10^9.*917.*10^-3.*10^-9]; % Gt/a

% estimate observed thickness in 2018 using surface and bed
% calculate the thickness required to remain grounded at each grid cell
rho_sw = 1000; % density of sea water (kg/m^3)
rho_i = 917; % density of ice (kg/m^3)
Hf = -(rho_sw./rho_i).*b0; % flotation thickness (m)
h_2018 = interp1(cl.xi,h(13).h_centerline,x0);
H_2018 = h_2018 - b0;
% find the location of the grounding line and use a floating
% geometry from the grounding linU_widthavge to the calving front
if length(Hf)>=find(Hf-H_2018>0,1,'first')+1
    xgl = interp1(Hf(find(Hf-H_2018>0,1,'first')-1:find(Hf-H_2018>0,1,'first')+1)...
        -H_2018(find(Hf-H_2018>0,1,'first')-1:find(Hf-H_2018>0,1,'first')+1),...
        x0(find(Hf-H_2018>0,1,'first')-1:find(Hf-H_2018>0,1,'first')+1),0,'linear','extrap'); % (m along centerline)
else
    xgl = x0(find(Hf-H_2018>0,1,'first')-1);
end
gl_2018 = dsearchn(x0',xgl);
h_2018(gl_2018+1:c0) = (1-rho_i/rho_sw).*H_2018(gl_2018+1:c0); %adjust the surface elevation of ungrounded ice to account for buoyancy
H_2018(h_2018<0)=0-b0(h_2018<0); h_2018(h_2018<0)=0; % surface cannot go below sea level
h_2018(h_2018-H_2018<b0) = b0(h_2018-H_2018<b0)+H_2018(h_2018-H_2018<b0); % thickness cannot go beneath bed elevation

% define time stepping (s)
t_start = 0*3.1536e7; % 2002
t_mid = 18*3.1536e7; % 2020
t_end = 98*3.1536e7; % 2100
dt1 = 0.0005*3.1536e7; 
dt2 = 0.001*3.1536e7; 
t = [t_start:dt1:t_mid t_mid+dt2:dt2:t_end];

% define color schemes
% figures 9 & 11
colDFW = cmocean('thermal',14); 
colDFW(1,:) = []; colDFW(end-1:end,:)=[]; % don't use end member colors
col1 = cmocean('thermal',14);  
col1(1,:) = []; col1(end-1:end,:)=[]; % don't use end member colors
% figure 12
col2 = [[222,119,174]./255; [127,188,65]./255; [142,1,82]./255; [39,100,25]./255]; % colors for plotting box plots

% set up axes
loop=1; % loop to minimize plotting commands
while loop==1
    % -----unperturbed & varying DFW scenarios-----
    % geometry and speed
    figure(9); clf; 
    set(gcf,'Position',[0 75 375 550]);
    ax9A=axes('position',[0.17 0.5 0.78 0.35]); hold on; % geometry
        set(gca,'fontsize',fontsize,'YTick',-1500:500:1500,'XTickLabel',[],'linewidth',1);
        grid on; 
        ylabel('Elevation [m]');         
        xlim([25 80]); 
        ylim([-700 500]);
        plot(x1./10^3,b1,'-k','linewidth',2);
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.9+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
            'a)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold'); 
        % add colorbar
        colormap(col1);
        cb1=colorbar('horiz'); set(cb1,'fontname',fontname,'fontsize',fontsize-3,...
            'Ticks',0:0.5:1,'TickLabels',["-5", "0", "+5"],'position',[0.15 0.88 0.8 0.02]);
        set(get(cb1,'label'),'String','d_{fw} [m]','fontsize',fontsize-3);   
    ax9B=axes('position',[0.17 0.1 0.78 0.35]); hold on; % speed
        set(gca,'fontsize',fontsize,'YTick',0:500:1500,'linewidth',1);   
        grid on;
        xlabel('Distance along centerline [km]');
        ylabel('Speed [m yr^{-1}]');  
        xlim([25 80]); 
        ylim([250 1500]);
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.9+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
            'b)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold'); 
    % Fgl, calving front & grounding line positions, backstress
    figure(10); clf;
    set(gcf,'Position',[-1000 50 750 800]); 
    % Xcf time series
    ax10A = axes('position',[0.08 0.69 0.63 0.3]); hold on;
        set(gca,'fontsize',fontsize,'linewidth',1, ...
            'XLim', [1995 2100], 'XTickLabel', [], ...
            'YLim', [35 70]);
        ylabel('X_{cf} [km]');
        grid on;
%         legend('location','south');
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.02+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.92+min(get(gca,'YLim')),...
            'a)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');
        % add rectangle for Larsen B ice shelf collapse
        clps_st = 2002.0849; % Jan 31, 2002
        clps_end = 2002.2822; % April 13, 2002
        rectangle(ax10A,'Position',[clps_st 25 clps_end-clps_st 90],'FaceColor',[253,141,60]./255,'EdgeColor',[253,141,60]./255);
    % Fgl time series
    ax10B = axes('position',[0.08 0.36 0.63 0.3]); hold on; 
        set(gca,'fontsize',fontsize,'linewidth',1, ...
            'XLim', [1995 2100], 'XTickLabel', [], ...
            'YLim', [0 9]); 
        ylabel('F_{gl} [Gt/y]');
        grid on; 
%         legend('location','north');
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.02+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.92+min(get(gca,'YLim')),...
            'b)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');
        % add grey rectangle for Larsen B ice shelf collapse
        rectangle(ax10B,'Position',[clps_st 0 clps_end-clps_st 10],'FaceColor',[253,141,60]./255,'EdgeColor',[253,141,60]./255); 
    % backstress time series
    ax10C = axes('position',[0.08 0.03 0.63 0.3]); hold on; 
        set(gca,'fontsize',fontsize,'linewidth',1, ...
            'XLim', [1995 2100], ...
            'YLim', [0 4]);
        ylabel('\Sigma R_{xy,gl} [MPa]');
        grid on; 
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.02+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.92+min(get(gca,'YLim')),...
            'c)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');
        % add grey rectangle for Larsen B ice shelf collapse
        rectangle(ax10C,'Position',[clps_st 0 clps_end-clps_st 5],'FaceColor',[253,141,60]./255,'EdgeColor',[253,141,60]./255); 

    % -----future SMB, TF, SMB_enh, SMB_enh+TF scenarios-----
    % geometry and speed
    figure(11); clf; 
    set(gcf,'Position',[0 75 1250 550]);
    % SMB
    ax11A=axes('position',[0.05 0.5 0.19 0.35]); hold on; % geometry
        set(gca,'fontsize',fontsize,'YTick',-1500:500:1500,'XTickLabel',[],'linewidth',1);
        grid on; 
        ylabel('Elevation [m]');         
        xlim([25 60]); 
        ylim([-700 500]);
        plot(x1./10^3,b1,'-k','linewidth',2);
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.9+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
            'a)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold'); 
        % add colorbar
        colormap(col1);
        cb2=colorbar('horiz'); set(cb2,'fontname',fontname,'fontsize',fontsize-3,...
            'Ticks',0:0.5:1,'TickLabels',[{'0.0'},{'-2.5'},{'-5.0'}],'position',[0.05 0.9 0.19 0.02]);
        set(get(cb2,'label'),'String','\DeltaSMB [m/y]','fontsize',fontsize-3);   
    ax11E=axes('position',[0.05 0.1 0.19 0.35]); hold on; % speed
        set(gca,'fontsize',fontsize,'YTick',0:500:5000,'linewidth',1); 
        grid on; 
        xlabel('Distance along centerline [km]');
        ylabel('Speed [m yr^{-1}]');  
        xlim([25 60]); 
        ylim([250 1500]);
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.9+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
            'e)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold'); 
    % TF
    ax11B=axes('position',[0.29 0.5 0.19 0.35]); hold on; % geometry
        set(gca,'fontsize',fontsize,'YTick',-1500:500:1500,'XTickLabel',[],'linewidth',1);
        grid on; 
        xlim([25 60]); 
        ylim([-700 500]);
        plot(x1./10^3,b1,'-k','linewidth',2);
        % add colorbar
        colormap(col1);
        cb3=colorbar('horiz'); set(cb3,'fontname',fontname,'fontsize',fontsize-3,...
            'Ticks',0:0.5:1,'TickLabels',[{'0.0'},{'+0.5'},{'+1.0'}],'position',[0.29 0.9 0.19 0.02]);
        set(get(cb3,'label'),'String','\Delta F_T [^oC]','fontsize',fontsize-3);   
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.9+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
            'b)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold'); 
    ax11F=axes('position',[0.29 0.1 0.19 0.35]); hold on; grid on; % speed
        set(gca,'fontsize',fontsize,'YTick',0:500:1500,'linewidth',1);        
        xlim([25 60]); 
        ylim([250 1500]);
        xlabel('Distance along centerline [km]');
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.9+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
            'f)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold'); 
    % SMB_enh
    ax11C=axes('position',[0.53 0.5 0.19 0.35]); hold on; % geometry
        set(gca,'fontsize',fontsize,'YTick',-1500:500:1500,'XTickLabel',[],'linewidth',1);
        grid on; 
        xlim([25 60]); 
        ylim([-700 500]);
        plot(x1./10^3,b1,'-k','linewidth',2); 
        % add colorbar
        colormap(col1);
        cb4=colorbar('horiz'); set(cb4,'fontname',fontname,'fontsize',fontsize-3,...
            'Ticks',0:0.5:1,'TickLabels',[{'0.0'},{'-2.5'},{'-5.0'}],'position',[0.53 0.9 0.19 0.02]);
        set(get(cb4,'label'),'String','\Delta SMB_{enh} [m yr^{-1}]','fontsize',fontsize-3);  
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.9+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
            'c)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold'); 
    ax11G=axes('position',[0.53 0.1 0.19 0.35]); hold on; % speed
        set(gca,'fontsize',fontsize,'YTick',0:500:1500,'linewidth',1);   
        grid on;
        xlim([25 60]); 
        ylim([250 1500]);
        xlabel('Distance along centerline [km]');        
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.9+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
            'g)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');  
    % SMB_enh & TF
    ax11D=axes('position',[0.77 0.5 0.19 0.35]); hold on; % geometry
        set(gca,'fontsize',fontsize,'YTick',-1500:500:1500,'XTickLabel',[],'linewidth',1);
        grid on;
        xlim([25 60]); 
        ylim([-700 500]);
        plot(x1./10^3,b1,'-k','linewidth',2);
        % add colorbar
        colormap(col1);
        cb5=colorbar('horiz'); set(cb5,'fontname',fontname,'fontsize',fontsize-3,'Ticks',0:1/2:1,...
            'TickLabels',[{'0.0 & 0.0'},{'-2.5 & +0.5'},{'-5.0 & +1.0'}],'position',[0.77 0.9 0.19 0.02]);
        set(get(cb5,'label'),'String','\DeltaSMB_{enh} [m yr^{-1}] & \DeltaF_T [^oC]','fontsize',fontsize-3);  
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.9+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
            'd)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold'); 
    ax11H=axes('position',[0.77 0.1 0.19 0.35]); hold on; grid on; % speed
        set(gca,'fontsize',fontsize,'YTick',0:500:1500,'linewidth',1);        
        xlim([25 60]); 
        ylim([250 1500]);
        xlabel('Distance along centerline [km]'); 
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.9+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.9+min(get(gca,'YLim')),...
            'h)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold'); 
    % Fgl, Xcf, backstress
    figure(12); clf;
    set(gcf,'Position',[-1400 50 1200 800]); 
    % Xcf time series
    ax12A = axes('position',[0.05 0.69 0.4 0.3]); hold on;
        set(gca,'fontsize',fontsize,'linewidth',1,'XTickLabel',[]); 
        grid on;
        xlim([1995 2100]); 
        ylim([35 70]);
        ylabel('X_{cf} [km]');
%         legend('location','north','numcolumns',2);
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.02+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.92+min(get(gca,'YLim')),...
            'a)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');
        % add grey rectangle for Larsen B ice shelf collapse
        clps_st = 2002.0849; % Jan 31, 2002
        clps_end = 2002.2822; % April 13, 2002
        rectangle(ax12A,'Position',[clps_st 25 clps_end-clps_st 90],'FaceColor',[253,141,60]./255,'EdgeColor',[253,141,60]./255);
    % Xcf box plot
    ax12B = axes('position',[0.48 0.69 0.32 0.3]); hold on; 
        set(gca, 'fontsize', fontsize, 'linewidth', 1); 
        grid on; 
    % Fgl time series
    ax12C = axes('position',[0.05 0.36 0.4 0.3]); hold on; 
        set(gca,'fontsize',fontsize,'linewidth',1,'XTickLabel',[]); 
        grid on; 
        xlim([1995 2100]); 
        ylim([0 9]);        
        ylabel('F_{gl} [Gt/y]'); 
%         legend('location','north');
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.02+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.92+min(get(gca,'YLim')),...
            'c)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');
        % add grey rectangle for Larsen B ice shelf collapse
        rectangle(ax12C,'Position',[clps_st 0 clps_end-clps_st 10],'FaceColor',[253,141,60]./255,'EdgeColor',[253,141,60]./255); 
    % Fgl box plot
    ax12D = axes('position',[0.48 0.36 0.32 0.3]); hold on; 
        set(gca,'fontsize',fontsize,'linewidth',1); 
        grid on;
    % Backstress time series
    ax12E = axes('position',[0.05 0.03 0.4 0.3]); hold on; 
        set(gca,'fontsize',fontsize,'linewidth',1); 
        grid on; 
        xlim([1995 2100]); 
        ylim([0 4]);        
        ylabel('\Sigma R_{xy} [MPa]'); 
        % add text label            
        text((max(get(gca,'XLim'))-min(get(gca,'XLim')))*0.02+min(get(gca,'XLim')),...
            (max(get(gca,'YLim'))-min(get(gca,'YLim')))*0.92+min(get(gca,'YLim')),...
            'e)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');
        % add grey rectangle for Larsen B ice shelf collapse
        rectangle(ax12E,'Position',[clps_st 0 clps_end-clps_st 10],'FaceColor',[253,141,60]./255,'EdgeColor',[253,141,60]./255); 
    % Fgl box plot
    ax12F = axes('position',[0.48 0.03 0.32 0.3]); hold on; 
        set(gca,'fontsize',fontsize,'linewidth',1); 
        grid on;

    loop=loop+1; % exit loop 
    
end

% loop through results, split into each scenario
cd([basepath,'workflows/steady-state-initial/results/1_SMB_DFW_TF/']);
files = dir('*geom.mat');
for i=1:length(files)
    if contains(files(i).name,'SMB0') && contains(files(i).name,'DFW0') && contains(files(i).name,'TF0')
        files(i).change = 0;
        files(i).changeIn = 'SMB';
        files(i).name = files(i).name; 
        files(length(files)+1).change = 0;
        files(length(files)).changeIn = 'DFW';
        files(length(files)).name = files(i).name;
        files(length(files)+1).change = 0; 
        files(length(files)).changeIn = 'TF';
        files(length(files)).name = files(i).name;        
    % (a) SMB
    elseif contains(files(i).name,'DFW12.458m') && contains(files(i).name,'TF0_')
        files(i).change = str2double(files(i).name(regexp(files(i).name,'B')+1:...
            regexp(files(i).name,'_D')-1)); 
        files(i).changeIn = 'SMB';  
        files(i).name = files(i).name;
    % (b) DFW
    elseif contains(files(i).name,'SMB0') && contains (files(i).name,'TF0_')
        files(i).change = str2double(files(i).name(regexp(files(i).name,'W')+1:...
            regexp(files(i).name,'m_')-1)) - 12.458; % m 
        files(i).changeIn = 'DFW';  
        files(i).name = files(i).name;
    % (c) F_T
    elseif contains(files(i).name,'SMB0') && contains (files(i).name,'DFW12.458m')        
        files(i).change = str2double(files(i).name(regexp(files(i).name,'TF')+2:...
            regexp(files(i).name,'_geom')-1)); % m 
        files(i).changeIn = 'TF';  
        files(i).name = files(i).name;        
    end
end
    
% sort by changeIn and change
files = struct2table(files);
files = sortrows(files,[8,7]);
% save indices for SMB & SMR
ISMB = flipud(find(strcmp('SMB',table2array(files(:,8)))));
IDFW = find(strcmp('DFW',table2array(files(:,8))));
IFT = find(strcmp('TF',table2array(files(:,8))));
files = table2struct(files);

% (0) unperturbed with varying DFW_min scenarios
dDFW = zeros(length(IDFW),1); % change in DFW
dHgl = zeros(length(IDFW),1); % change in mean thickness
dUgl = zeros(length(IDFW),1); % change in mean ice speed
dL = zeros(length(IDFW),1); % change in length
dgl = zeros(length(IDFW),1); % change in grounding line position
Ugl = zeros(length(IDFW),1); % speed at grounding line 
Fdfw = zeros(length(IDFW),1); % grounding line discharge
FGL = zeros(length(IDFW), length(t));
XCF = zeros(length(IDFW), length(t));
RXY = zeros(length(IDFW), length(t)); 
for i=1:length(IDFW)
    % load file
    load(files(IDFW(i)).name);
    % calculate grounding line discharge
    W = interp1(x0,W0,x2); % interpolate width on spatial grid
    % F (Gt/a) = (U m/s)*(H m)*(W m)*(917 kg/m^3)*(3.1536e7 s/a)*(1e-12 Gt/kg)
    % use the mean of a rectangular and an ellipsoidal bed
    Fdfw(i) = (H2(gl2)*U2(gl2)*W(gl2))*917*1e-12*3.1536e7; % Gt/a    
    % store full Fgl, Xcf, and Rxy_gl over time 
    FGL(i,:) = Fgl2; 
    XCF(i,:) = XCF2; 
    RXY(i,:) = Rxy_gl2; 
    % plot
    figure(9); hold on;
        % ice surface
        plot(ax9A,x2(1:c2)./10^3,h2(1:c2),'color',colDFW(i,:),'linewidth',linewidth-0.5);
        % calving front
        plot(ax9A,[x2(c2) x2(c2)]./10^3,[h2(c2)-H2(c2) h2(c2)],'color',colDFW(i,:),'linewidth',linewidth-0.5);
        % floating bed
        plot(ax9A,x2(gl2:c2)./10^3,h2(gl2:c2)-H2(gl2:c2),'color',colDFW(i,:),'linewidth',linewidth-0.5);
        % ice surface speed
        plot(ax9B,x2(1:c2)./10^3,U2(1:c2).*3.1536e7,'color',colDFW(i,:),'linewidth',linewidth-0.5);
        % dH
        dHgl(i) = H2(gl2)-H1(gl1); % m      
    % calving front position and grounding line discharge over time
    if i==1
        XCF2_DFWmin = XCF2;
        FGL2_DFWmin = Fgl2; 
        RXY2_DFWmin = Rxy_gl2; 
    elseif i==6
        XCF2_DFWmid = XCF2;
        FGL2_DFWmid = Fgl2;
        RXY2_DFWmid = Rxy_gl2; 
    elseif i==length(IDFW)
        XCF2_DFWmax = XCF2;
        FGL2_DFWmax = Fgl2; 
        RXY2_DFWmax = Rxy_gl2; 
    end
    % save results 
    dDFW(i) = files(IDFW(i)).change; % m/a
    dUgl(i) = (U2(gl2)-U1(gl1)).*3.1536e7; % m/a     
    dL(i) = x2(c2)-x1(c1); % m   
    dgl(i) = x2(gl2)-x1(gl1); % m
    Ugl(i) = U2(gl2)*3.1536e7; % m/a
end
% plot Fgl, Xcf, Rxy_gl over time averaged over 1 yr bins
figure(10);
l1 = fill(ax10A, [t/3.1536e7+2002 fliplr(t)/3.1536e7+2002],...
    [movmean(XCF2_DFWmin/10^3,1000) fliplr(movmean(XCF2_DFWmax,1000))/10^3],...
    [150,150,150]./255,'LineStyle','none','displayname','d_{fw,range}');
l2 = plot(ax10A,[(0:dt1:5*3.1536e7-dt1)/3.1536e7+1997 t/3.1536e7+2002],...
    movmean([x0(c0)*ones(1,length(Fgl_preCollapse))/10^3 XCF2_DFWmid/10^3],1000),...
    '-k','linewidth',linewidth,'displayname','d_{fw,median}');        
fill(ax10B, [t/3.1536e7+2002 fliplr(t)/3.1536e7+2002],...
    [movmean(FGL2_DFWmin,1000) fliplr(movmean(FGL2_DFWmax,1000))],...
    [150,150,150]./255,'LineStyle','none','HandleVisibility','off');
plot(ax10B,[(0:dt1:5*3.1536e7-dt1)/3.1536e7+1997 t/3.1536e7+2002],...
    movmean([Fgl_preCollapse FGL2_DFWmid],1000),'-k','linewidth',linewidth,'handlevisibility','off'); 
fill(ax10C, [t/3.1536e7+2002 fliplr(t)/3.1536e7+2002],...
    [movmean(RXY2_DFWmin/10^6,1000) fliplr(movmean(RXY2_DFWmax,1000))/10^6],...
    [150,150,150]./255,'LineStyle','none','handlevisibility','off');
plot(ax10C,[(0:dt1:5*3.1536e7-dt1)/3.1536e7+1997 t/3.1536e7+2002],...
    movmean([x0(c0)*ones(1,length(Fgl_preCollapse))/10^3 RXY2_DFWmid/10^6],1000),...
    '-k','linewidth',linewidth,'handlevisibility','off');      
% create table to store result quantities
varNames = {'dfwd','dL','dxgl','dHgl','dUgl','Qfwd'};
T_DFW = table(dDFW,dL/10^3,dgl/10^3,dHgl,dUgl,Fdfw,'VariableNames',varNames);

% (1) SMB
dSMB = zeros(length(ISMB),1); % change in SMB
dHgl = zeros(length(ISMB),1); % change in thickness at the grounding line
dUgl = zeros(length(ISMB),1); % change in ice speed at the grounding line
dL = zeros(length(ISMB),1); % change in length
dgl = zeros(length(ISMB),1); % change in grounding line position
Ugl = zeros(length(ISMB),1); % speed at grounding line 
Fsmb = zeros(length(ISMB),1); % grounding line discharge
FGL = zeros(length(ISMB), length(t));
XCF = zeros(length(ISMB), length(t));
RXY = zeros(length(ISMB), length(t)); 
for i=1:length(ISMB)
    load(files(ISMB(i)).name);
    % calculate grounding line discharge
    W = interp1(x0,W0,x2); % interpolate width on spatial grid
    % F (Gt/a) = (U m/s)*(A m^2)*(917 kg/m^3)*(3.1536e7 s/a)*(1e-12 Gt/kg)
    % use the mean of a rectangular and an ellipsoidal bed
    Fsmb(i) = (H2(gl2)*U2(gl2)*W(gl2))*917*1e-12*3.1536e7; % Gt/a
    % store full Fgl and XCF over time 
    FGL(i,:) = Fgl2; 
    XCF(i,:) = XCF2; 
    RXY(i,:) = Rxy_gl2; 
    % plot
    figure(11); hold on;
        % ice surface
        plot(ax11A,x2(1:c2)./10^3,h2(1:c2),'color',col1(i,:),'linewidth',linewidth-0.5);
        % calving front
        plot(ax11A,[x2(c2) x2(c2)]./10^3,[h2(c2) h2(c2)-H2(c2)],'color',col1(i,:),'linewidth',linewidth-0.5);
        % floating bed
        plot(ax11A,x2(gl2:c2)./10^3,h2(gl2:c2)-H2(gl2:c2),'color',col1(i,:),'linewidth',linewidth-0.5);
        % ice surface speed
        plot(ax11E,x2(1:c2)./10^3,U2(1:c2).*3.1536e7,'color',col1(i,:),'linewidth',linewidth-0.5);
        % dH
        dHgl(i) = H2(gl2)-H1(gl1);        
    % calving front position and grounding line discharge over time
    if i==1
        XCF2_SMBmin = XCF2;
        Fgl2_SMBmin = Fgl2; 
        RXY2_SMBmin = Rxy_gl2; 
    elseif i==6
        XCF2_SMBmid = XCF2;
        Fgl2_SMBmid = Fgl2; 
        RXY2_SMBmid = Rxy_gl2; 
    elseif i==length(ISMB)
        XCF2_SMBmax = XCF2;
        Fgl2_SMBmax = Fgl2; 
        RXY2_SMBmax = Rxy_gl2; 
    end
    % save results 
    dSMB(i) = files(ISMB(i)).change; % m/a
    dUgl(i) = (U2(gl2)-U1(gl1)).*3.1536e7; % m/a     
    dL(i) = x2(c2)-x1(c1); % m   
    dgl(i) = x2(gl2)-x1(gl1); % m
    Ugl(i) = U2(gl2)*3.1536e7; % m/a
end
% save info for box plots
BP.XCF = [XCF(:,(t/3.1536e7+2002)==2020); XCF(:,(t/3.1536e7+2002)==2040); ... 
    XCF(:,(t/3.1536e7+2002)==2060); XCF(:,(t/3.1536e7+2002)==2080); XCF(:,(t/3.1536e7+2002)==2100)];
BP.FGL = [FGL(:,(t/3.1536e7+2002)==2020); FGL(:,(t/3.1536e7+2002)==2040);... 
    FGL(:,(t/3.1536e7+2002)==2060); FGL(:,(t/3.1536e7+2002)==2080); FGL(:,(t/3.1536e7+2002)==2100)];
BP.RXY = [RXY(:,(t/3.1536e7+2002)==2020); RXY(:,(t/3.1536e7+2002)==2040);... 
    RXY(:,(t/3.1536e7+2002)==2060); RXY(:,(t/3.1536e7+2002)==2080); RXY(:,(t/3.1536e7+2002)==2100)];
BP.years = [2020*ones(length(XCF(:,(t/3.1536e7+2002)==2020)),1); 2040*ones(length(XCF(:,(t/3.1536e7+2002)==2040)),1);...
    2060*ones(length(XCF(:,(t/3.1536e7+2002)==2060)),1); 2080*ones(length(XCF(:,(t/3.1536e7+2002)==2080)),1); ...
    2100*ones(length(XCF(:,(t/3.1536e7+2002)==2100)),1)];
% create table to store result quantities
varNames = {'dsmb','dL','dxgl','dHgl','dUgl','Qsmb'};
T_SMB = table(dSMB,dL/10^3,dgl/10^3,dHgl,dUgl,Fsmb,'VariableNames',varNames);

% (2) F_T
dTF = zeros(length(IFT),1); % change in F_T
dsmr = zeros(length(IFT),1); % change in smr due to F_T
dHgl = zeros(length(IFT),1); % change in mean thickness
dUgl = zeros(length(IFT),1); % change in mean ice speed
dL = zeros(length(IFT),1); % change in length
dgl = zeros(length(IFT),1); % change in grounding line position
Ugl = zeros(length(IFT),1); % speed at grounding line 
F = zeros(length(IFT),1); % grounding line discharge
FGL = zeros(length(IFT), length(t));
XCF = zeros(length(IFT), length(t));
RXY = zeros(length(IFT), length(t)); 
for i=1:length(IFT)
    load(files(IFT(i)).name);
    W = interp1(x0,W0,x2); % interpolate width on spatial grid
    % F (Gt/a) = (U m/s)*(H m)*(W m)*(917 kg/m^3)*(3.1536e7 s/a)*(1e-12 Gt/kg)
    % use the mean of a rectangular and an ellipsoidal bed
    F(i) = (H2(gl2)*U2(gl2)*W(gl2))*917*1e-12*3.1536e7; % Gt/a
    % store full Fgl over time 
    FGL(i,:) = Fgl2; 
    XCF(i,:) = XCF2;
    RXY(i,:) = Rxy_gl2; 
    % extract change in F_T
    dTF(i) = files(IFT(i)).change; % m/a
    figure(11); hold on;
        % ice surface
        plot(ax11B,x2(1:c2)./10^3,h2(1:c2),'color',col1(i,:),'linewidth',linewidth-0.5);
        % calving front
        plot(ax11B,[x2(c2) x2(c2)]./10^3,[h2(c2) h2(c2)-H2(c2)],'color',col1(i,:),'linewidth',linewidth-0.5);
        % floating bed
        plot(ax11B,x2(gl2:c2)./10^3,h2(gl2:c2)-H2(gl2:c2),'color',col1(i,:),'linewidth',linewidth-0.5);
        % ice surface speed
        plot(ax11F,x2(1:c2)./10^3,U2(1:c2).*3.1536e7,'color',col1(i,:),'linewidth',linewidth-0.5);
        % dH
        dHgl(i) = H2(gl2)-H1(gl1);  
    % calving front position and grounding line discharge over time
    if i==1
        XCF2_TFmin = XCF2;
        Fgl2_TFmin = Fgl2; 
        RXY2_TFmin = Rxy_gl2; 
    elseif i==6
        XCF2_TFmid = XCF2;
        Fgl2_TFmid = Fgl2; 
        RXY2_TFmid = Rxy_gl2; 
    elseif i==length(IFT)
        XCF2_TFmax = XCF2;
        Fgl2_TFmax = Fgl2; 
        RXY2_TFmax = Rxy_gl2; 
    end
    % save results for data table
    %dSMR(i) = dSMR_max*3.1536e7;
    dUgl(i) = (U2(gl2)-U1(gl1)).*3.1536e7; % m/a     
    dL(i) = x2(c2)-x1(c1); % m   
    dgl(i) = x2(gl2)-x1(gl1); % m
    Ugl(i) = U2(gl2)*3.1536e7; % m/a
end
% save info for box plots
BP.XCF = [BP.XCF; XCF(:,(t/3.1536e7+2002)==2020); XCF(:,(t/3.1536e7+2002)==2040); ... 
    XCF(:,(t/3.1536e7+2002)==2060); XCF(:,(t/3.1536e7+2002)==2080); XCF(:,(t/3.1536e7+2002)==2100)];
BP.FGL = [BP.FGL; FGL(:,(t/3.1536e7+2002)==2020); FGL(:,(t/3.1536e7+2002)==2040);... 
    FGL(:,(t/3.1536e7+2002)==2060); FGL(:,(t/3.1536e7+2002)==2080); FGL(:,(t/3.1536e7+2002)==2100)];
BP.RXY = [BP.RXY; RXY(:,(t/3.1536e7+2002)==2020); RXY(:,(t/3.1536e7+2002)==2040);... 
    RXY(:,(t/3.1536e7+2002)==2060); RXY(:,(t/3.1536e7+2002)==2080); RXY(:,(t/3.1536e7+2002)==2100)];
BP.years = [BP.years; 2020*ones(length(XCF(:,(t/3.1536e7+2002)==2020)),1); 2040*ones(length(XCF(:,(t/3.1536e7+2002)==2040)),1);...
    2060*ones(length(XCF(:,(t/3.1536e7+2002)==2060)),1); 2080*ones(length(XCF(:,(t/3.1536e7+2002)==2080)),1); ...
    2100*ones(length(XCF(:,(t/3.1536e7+2002)==2100)),1)];
varNames = {'dTF','dL','dgl','dHgl','dUgl','Qgl'};
T_TF = table(dTF,dL/10^3,dgl/10^3,dHgl,dUgl,F,'VariableNames',varNames);

% (3) SMB_enh
cd([basepath,'workflows/steady-state-initial/results/2_SMB_enh/']);
dsmb_enh = zeros(length(IDFW),1); % change in SMB_enh
dHgl = zeros(length(IDFW),1); % change in mean thickness
dUgl = zeros(length(IDFW),1); % change in mean ice speed
dL = zeros(length(IDFW),1); % change in length
dgl = zeros(length(IDFW),1); % change in grounding line position
Ugl = zeros(length(IDFW),1); % speed at grounding line 
F = zeros(length(IDFW),1); % grounding line discharge
FGL = zeros(length(IFT), length(t));
XCF = zeros(length(IFT), length(t));
RXY = zeros(length(IFT), length(t)); 
% define thermal forcing
TF0 = 0.2; % ^oC - estimated from Larsen B icebergs
clear files; files = dir('*geom.mat');
% sort files by perturbation magnitude
for i=1:length(files)
    files(i).change = str2double(files(i).name(regexp(files(i).name,'B')+1:...
                  regexp(files(i).name,'_enh')-1)); % m/a
end
files = struct2table(files);
files = sortrows(files,7,'descend');
files = table2struct(files); 
for i=1:length(files)
    load(files(i).name);
    W = interp1(x0,W0,x2); % interpolate width on spatial grid
    % F (Gt/a) = (U m/s)*(H m)*(W m)*(917 kg/m^3)*(3.1536e7 s/a)*(1e-12 Gt/kg)
    % use the mean of a rectangular and an ellipsoidal bed
    F(i) = (H2(gl2)*U2(gl2)*W(gl2))*917*1e-12*3.1536e7; % Gt/a
    % store full Fgl over time 
    FGL(i,:) = Fgl2; 
    XCF(i,:) = XCF2;
    RXY(i,:) = Rxy_gl2; 
    % estimate initial melt rate using Eqn from Slater et al. (2020):
    mdot0 = (3*10^-4*-b0(gl1)*((sum(RO0(1:gl1)))*86400)^0.39 + 0.15)*TF0^1.18/86400; % m/s
    figure(11); hold on;
        % ice surface
        plot(ax11C,x2(1:c2)./10^3,h2(1:c2),'color',col1(i,:),'linewidth',linewidth-0.5);
        % calving front
        plot(ax11C,[x2(c2) x2(c2)]./10^3,[h2(c2) h2(c2)-H2(c2)],'color',col1(i,:),'linewidth',linewidth-0.5);
        % floating bed
        plot(ax11C,x2(gl2:c2)./10^3,h2(gl2:c2)-H2(gl2:c2),'color',col1(i,:),'linewidth',linewidth-0.5);
        % ice surface speed
        plot(ax11G,x2(1:c2)./10^3,U2(1:c2).*3.1536e7,'color',col1(i,:),'linewidth',linewidth-0.5);
        % dH
        dHgl(i) = H2(gl2)-H1(gl1); 
    % calving front position and grounding line discharge over time
    if i==1
        XCF2_SMBenh_min = XCF2;
        Fgl2_SMBenh_min = Fgl2; 
        RXY2_SMBenh_min = Rxy_gl2; 
    elseif i==6
        XCF2_SMBenh_mid = XCF2;
        Fgl2_SMBenh_mid = Fgl2; 
        RXY2_SMBenh_mid = Rxy_gl2; 
    elseif i==length(files)
        XCF2_SMBenh_max = XCF2;
        Fgl2_SMBenh_max = Fgl2; 
        RXY2_SMBenh_max = Rxy_gl2; 
    end
   
    % save results 
    dsmb_enh(i) = files(i).change; % m/a
    %dSMR(i) = dSMR_max*3.1536e7; % m/a
    dUgl(i) = (U2(gl2)-U1(gl1)).*3.1536e7; % m/a     
    dL(i) = x2(c2)-x1(c1); % m   
    dgl(i) = x2(gl2)-x1(gl1); % m
    Ugl(i) = U2(gl2)*3.1536e7; % m/a
end
% save info for box plots
BP.XCF = [BP.XCF; XCF(:,(t/3.1536e7+2002)==2020); XCF(:,(t/3.1536e7+2002)==2040); ... 
    XCF(:,(t/3.1536e7+2002)==2060); XCF(:,(t/3.1536e7+2002)==2080); XCF(:,(t/3.1536e7+2002)==2100)];
BP.FGL = [BP.FGL; FGL(:,(t/3.1536e7+2002)==2020); FGL(:,(t/3.1536e7+2002)==2040);... 
    FGL(:,(t/3.1536e7+2002)==2060); FGL(:,(t/3.1536e7+2002)==2080); FGL(:,(t/3.1536e7+2002)==2100)];
BP.RXY = [BP.RXY; RXY(:,(t/3.1536e7+2002)==2020); RXY(:,(t/3.1536e7+2002)==2040);... 
    RXY(:,(t/3.1536e7+2002)==2060); RXY(:,(t/3.1536e7+2002)==2080); RXY(:,(t/3.1536e7+2002)==2100)];
BP.years = [BP.years; 2020*ones(length(XCF(:,(t/3.1536e7+2002)==2020)),1); 2040*ones(length(XCF(:,(t/3.1536e7+2002)==2040)),1);...
    2060*ones(length(XCF(:,(t/3.1536e7+2002)==2060)),1); 2080*ones(length(XCF(:,(t/3.1536e7+2002)==2080)),1); ...
    2100*ones(length(XCF(:,(t/3.1536e7+2002)==2100)),1)];
varNames = {'dSMB_enh','dL','dgl','dHgl','dUgl','Qgl'};
T_smb_enh = table(dsmb_enh,dL/10^3,dgl/10^3,dHgl,dUgl,F,'VariableNames',varNames);

% (4) SMB_enh + F_T
cd([basepath,'workflows/steady-state-initial/results/3_SMB_enh+TF/']);
dsmb_enh = zeros(length(IDFW),1); % change in SMB_enh
dTF = zeros(length(IDFW),1); % change in F_T
dHgl = zeros(length(IDFW),1); % change in mean thickness
dUgl = zeros(length(IDFW),1); % change in mean ice speed
dL = zeros(length(IDFW),1); % change in length
dgl = zeros(length(IDFW),1); % change in grounding line position
Ugl = zeros(length(IDFW),1); % speed at grounding line 
F = zeros(length(IDFW),1); % grounding line discharge
FGL = zeros(length(IFT), length(t));
XCF = zeros(length(IFT), length(t));
RXY = zeros(length(IFT), length(t)); 
clear files; files = dir('*geom.mat');
% sort files by perturbation magnitude
for i=1:length(files)
    files(i).change_TF = str2double(files(i).name(regexp(files(i).name,'F')+1:...
                  regexp(files(i).name,'_geom')-1)); % ^oC
    files(i).change_SMB = str2double(files(i).name(regexp(files(i).name,'B')+1:...
                  regexp(files(i).name,'_enh')-1)); % m/a
end
files = struct2table(files);
files = sortrows(files,7,'ascend');
files = table2struct(files); 
for i=1:length(files)
    load(files(i).name);
    W = interp1(x0,W0,x2); % interpolate width on spatial grid
    % F (Gt/a) = (U m/s)*(H m)*(W m)*(917 kg/m^3)*(3.1536e7 s/a)*(1e-12 Gt/kg)
    % use the mean of a rectangular and an ellipsoidal bed
    F(i) = (H2(gl2)*U2(gl2)*W(gl2))*917*1e-12*3.1536e7; % Gt/a
    % store full Fgl over time 
    FGL(i,:) = Fgl2; 
    XCF(i,:) = XCF2;
    RXY(i,:) = Rxy_gl2; 
    % plot
    figure(11); hold on;
        % ice surface
        plot(ax11D,x2(1:c2)./10^3,h2(1:c2),'color',col1(i,:),'linewidth',linewidth-0.5);
        % calving front
        plot(ax11D,[x2(c2) x2(c2)]./10^3,[h2(c2) h2(c2)-H2(c2)],'color',col1(i,:),'linewidth',linewidth-0.5);
        % floating bed
        plot(ax11D,x2(gl2:c2)./10^3,h2(gl2:c2)-H2(gl2:c2),'color',col1(i,:),'linewidth',linewidth-0.5);
        % ice surface speed
        plot(ax11H,x2(1:c2)./10^3,U2(1:c2).*3.1536e7,'color',col1(i,:),'linewidth',linewidth-0.5);        
    % calving front position and grounding line discharge over time
    if i==1
        XCF2_SMBenhTF_min = XCF2;
        Fgl2_SMBenhTF_min = Fgl2; 
        RXY2_SMBenhTF_min = Rxy_gl2; 
    elseif i==6
        XCF2_SMBenhTF_mid = XCF2;
        Fgl2_SMBenhTF_mid = Fgl2; 
        RXY2_SMBenhTF_mid = Rxy_gl2; 
    elseif i==length(files)
        XCF2_SMBenhTF_max = XCF2;
        Fgl2_SMBenhTF_max = Fgl2; 
        RXY2_SMBenhTF_max = Rxy_gl2; 
    end 
    % save results 
    dsmb_enh(i) = files(i).change_SMB; % m/a
    dTF(i) = files(i).change_TF; % m/a
    % dH
    dHgl(i) = H2(gl2)-H1(gl1);
    %dSMR(i) = dSMR_max*3.1536e7; % m/a
    dUgl(i) = (U2(gl2)-U1(gl1)).*3.1536e7; % m/a     
    dL(i) = x2(c2)-x1(c1); % m   
    dgl(i) = x2(gl2)-x1(gl1); % m
    Ugl(i) = U2(gl2)*3.1536e7; % m/a
end
% save info for box plots
BP.XCF = [BP.XCF; XCF(:,(t/3.1536e7+2002)==2020); XCF(:,(t/3.1536e7+2002)==2040); ... 
    XCF(:,(t/3.1536e7+2002)==2060); XCF(:,(t/3.1536e7+2002)==2080); XCF(:,(t/3.1536e7+2002)==2100)];
BP.FGL = [BP.FGL; FGL(:,(t/3.1536e7+2002)==2020); FGL(:,(t/3.1536e7+2002)==2040);... 
    FGL(:,(t/3.1536e7+2002)==2060); FGL(:,(t/3.1536e7+2002)==2080); FGL(:,(t/3.1536e7+2002)==2100)];
BP.RXY = [BP.RXY; RXY(:,(t/3.1536e7+2002)==2020); RXY(:,(t/3.1536e7+2002)==2040);... 
    RXY(:,(t/3.1536e7+2002)==2060); RXY(:,(t/3.1536e7+2002)==2080); RXY(:,(t/3.1536e7+2002)==2100)];
BP.years = [BP.years; 2020*ones(length(XCF(:,(t/3.1536e7+2002)==2020)),1); 2040*ones(length(XCF(:,(t/3.1536e7+2002)==2040)),1);...
    2060*ones(length(XCF(:,(t/3.1536e7+2002)==2060)),1); 2080*ones(length(XCF(:,(t/3.1536e7+2002)==2080)),1); ...
    2100*ones(length(XCF(:,(t/3.1536e7+2002)==2100)),1)];
varNames = {'dSMB_enh','dTF','dL','dgl','dHgl','dUgl','Qgl'};
T_smb_enh_TF = table(dsmb_enh,dTF,dL/10^3,dgl/10^3,dHgl,dUgl,F,'VariableNames',varNames);

% -----plot Fgl, Xcf, Rxy_gl over time averaged over 1 yr bins     
% mid
% SMB
figure(12);
L1 = plot(ax12A,t/3.1536e7+2002,movmean(XCF2_SMBmid/10^3,1000),'color',col2(1,:),'linewidth',linewidth,'displayname','\DeltaSMB');  
plot(ax12C,t/3.1536e7+2002,movmean(Fgl2_SMBmid,1000),'color',col2(1,:),'linewidth',linewidth,'HandleVisibility','off');     
plot(ax12E,t/3.1536e7+2002,movmean(RXY2_SMBmid/1e6,1000),'color',col2(1,:),'linewidth',linewidth,'HandleVisibility','off');        
% TF
L2 = plot(ax12A,t/3.1536e7+2002,movmean(XCF2_TFmid/10^3,1000),'color',col2(2,:),'linewidth',linewidth,'displayName','\DeltaF_{T}');        
plot(ax12C,t/3.1536e7+2002,movmean(Fgl2_TFmid,1000),'color',col2(2,:),'linewidth',linewidth,'HandleVisibility','off');        
plot(ax12E,t/3.1536e7+2002,movmean(RXY2_TFmid/1e6,1000),'color',col2(2,:),'linewidth',linewidth,'HandleVisibility','off');        

% SMB_enh
L3 = plot(ax12A,t/3.1536e7+2002,movmean(XCF2_SMBenh_mid/10^3,1000),'color',col2(3,:),'linewidth',linewidth,'displayname','\DeltaSMB_{enh}');        
plot(ax12C,t/3.1536e7+2002,movmean(Fgl2_SMBenh_mid,1000),'color',col2(3,:),'linewidth',linewidth,'HandleVisibility','off');        
plot(ax12E,t/3.1536e7+2002,movmean(RXY2_SMBenh_mid/1e6,1000),'color',col2(3,:),'linewidth',linewidth,'HandleVisibility','off');        
% SMB_enh & TF
L4 = plot(ax12A,[(0:dt1:5*3.1536e7-dt1)/3.1536e7+1997 t/3.1536e7+2002],...
    [x0(c0)*ones(1,length(Fgl_preCollapse))/10^3 movmean(XCF2_SMBenhTF_mid/10^3,1000)],'color',col2(4,:),'linewidth',linewidth,'DisplayName','\DeltaSMB_{enh} & \DeltaF_{T}');        
plot(ax12C,[(0:dt1:5*3.1536e7-dt1)/3.1536e7+1997 t/3.1536e7+2002],...
    [Fgl_preCollapse movmean(Fgl2_SMBenhTF_mid,1000)],'color',col2(4,:),'linewidth',linewidth,'HandleVisibility','off');   
plot(ax12E,[(0:dt1:5*3.1536e7-dt1)/3.1536e7+1997 t/3.1536e7+2002],...
    [Fgl_preCollapse movmean(RXY2_SMBenhTF_mid/1e6,1000)],'color',col2(4,:),'linewidth',linewidth,'HandleVisibility','off');

% observations
% terminus - Dryak and Enderlin
l3 = plot(ax10A,termdate,termx/10^3,'xk','markersize',markersize-1,'linewidth',linewidth,'displayName','Dryak and Enderlin (2020)');        
L5 = plot(ax12A,termdate,termx/10^3,'xk','markersize',markersize-1,'linewidth',linewidth,'displayName','Dryak and Enderlin (2020)');        
% discharge - Rignot (2004)
l4 = errorbar(ax10B,F_obs(1:4,1),F_obs(1:4,2),F_obs_err(1:4),'.','color',[150,150,150]./255,...
    'markersize',markersize*2,'markerfacecolor','k','markeredgecolor','k','linewidth',linewidth,'displayName','Rignot et al. (2004)');        
L6 = errorbar(ax12C,F_obs(1:4,1),F_obs(1:4,2),F_obs_err(1:4),'.','color',[150,150,150]./255,...
    'markersize',markersize*2,'markerfacecolor','k','markeredgecolor','k','linewidth',linewidth,'displayName','Rignot et al. (2004)');   
% discharge - Us! 
l5 = plot(ax10B,F_obs(5:6,1),F_obs(5:6,2),'ok','markersize',markersize,'linewidth',linewidth,'displayName','this study');        
L7 = plot(ax12C,F_obs(5:6,1),F_obs(5:6,2),'ok','markersize',markersize,'linewidth',linewidth,'displayName','this study');   

% add legends
figure(10); legend([l1, l2, l3, l4, l5], 'position', [0.82, 0.73, 0.08, 0.25], 'orientation', 'vertical');
figure(12); legend([L1, L2, L3, L4, L5, L6, L7], 'position', [0.86 0.68, 0.08, 0.3], 'orientation', 'vertical');

% boxplots
% Note: must add two dummy groups to increase spacing between boxes
box_width = 0.7; 
% climate scenario groups (add letters to the front in order, because
% boxchart automatically alphabetizes categories when plotting)
BP.groups(1:55) = "B_SMB";
BP.groups(56:110) = "C_TF";
BP.groups(111:165) = "D_SMB_{enh}";
BP.groups(166:220) = "E_TF+SMB_{enh}";
BP.groups(221:225) = "A";
BP.groups(226:230) = "Z";
BP.years = [BP.years; (2020:20:2100)'; (2020:20:2100)'];
BP.XCF = [BP.XCF; NaN*ones(length(2020:20:2100),1); NaN*ones(length(2020:20:2100),1)];
BP.FGL = [BP.FGL; NaN*ones(length(2020:20:2100),1); NaN*ones(length(2020:20:2100),1)];
BP.RXY = [BP.RXY; NaN*ones(length(2020:20:2100),1); NaN*ones(length(2020:20:2100),1)];
bp = boxchart(ax12B,categorical(BP.years), BP.XCF./1000, 'GroupByColor', BP.groups,...
    'BoxWidth', box_width, 'markerstyle', 'none');
bp(2).BoxFaceColor = col2(1,:); bp(2).WhiskerLineColor = col2(1,:);
bp(3).BoxFaceColor = col2(2,:); bp(3).WhiskerLineColor = col2(2,:);
bp(4).BoxFaceColor = col2(3,:); bp(4).WhiskerLineColor = col2(3,:);
bp(5).BoxFaceColor = col2(4,:); bp(5).WhiskerLineColor = col2(4,:);
bp = boxchart(ax12D,categorical(BP.years), BP.FGL, 'GroupByColor',BP.groups,...
    'BoxWidth', box_width, 'markerstyle', 'none');
bp(2).BoxFaceColor = col2(1,:); bp(2).WhiskerLineColor = col2(1,:);
bp(3).BoxFaceColor = col2(2,:); bp(3).WhiskerLineColor = col2(2,:);
bp(4).BoxFaceColor = col2(3,:); bp(4).WhiskerLineColor = col2(3,:);
bp(5).BoxFaceColor = col2(4,:); bp(5).WhiskerLineColor = col2(4,:);
bp = boxchart(ax12F,categorical(BP.years), BP.RXY/1e6, 'GroupByColor',BP.groups,...
    'BoxWidth', box_width, 'markerstyle', 'none');
bp(2).BoxFaceColor = col2(1,:); bp(2).WhiskerLineColor = col2(1,:);
bp(3).BoxFaceColor = col2(2,:); bp(3).WhiskerLineColor = col2(2,:);
bp(4).BoxFaceColor = col2(3,:); bp(4).WhiskerLineColor = col2(3,:);
bp(5).BoxFaceColor = col2(4,:); bp(5).WhiskerLineColor = col2(4,:);
% modify y-axis limits, add text labels
set(ax12B,'YLim',[35 60], 'XTickLabels',[], 'XLim', [categorical(2020), categorical(2100)]);
text(ax12B,categorical(2020),...
    (max(get(ax12B,'YLim'))-min(get(ax12B,'YLim')))*0.92+min(get(ax12B,'YLim')),...
    'b)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');
set(ax12D,'YLim',[0.7 1.5],'YTick',0.4:0.2:1.6, 'XTickLabels',[], 'XLim', [categorical(2020), categorical(2100)]);
text(ax12D,categorical(2020),...
    (max(get(ax12D,'YLim'))-min(get(ax12D,'YLim')))*0.92+min(get(ax12D,'YLim')),...
    'd)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');
set(ax12F,'YLim',[0 4],'YTick',0:4, 'XLim', [categorical(2020), categorical(2100)]);
text(ax12F,categorical(2020),...
    (max(get(ax12F,'YLim'))-min(get(ax12F,'YLim')))*0.92+min(get(ax12F,'YLim')),...
    'f)','backgroundcolor','w','fontsize',fontsize,'linewidth',linewidth-1,'fontweight','bold');
% Add observed 2018 conditions to figures 5 and 7
b=1; % create a loop to make section collapsible
while b==1
    % geometry
    plot(ax9A,x18/10^3,h18,'--k','linewidth',linewidth-0.5);
    plot(ax9A,x18/10^3,h18-H18,'--k','linewidth',linewidth-0.5);
    plot(ax9A,[x18(c18)/10^3; x18(c18)/10^3],[h18(c18); h18(c18)-H18(c18)],'--k','linewidth',linewidth-0.5);
    plot(ax11A,x18/10^3,h18,'--k','linewidth',linewidth-0.5);
    plot(ax11A,x18/10^3,h18-H18,'--k','linewidth',linewidth-0.5);
    plot(ax11A,[x18(c18)/10^3; x18(c18)/10^3],[h18(c18)-H18(c18); h18(c18)],'--k','linewidth',linewidth-0.5);
    plot(ax11B,x18/10^3,h18,'--k','linewidth',linewidth-0.5);
    plot(ax11B,x18/10^3,h18-H18,'--k','linewidth',linewidth-0.5);
    plot(ax11B,[x18(c18)/10^3; x18(c18)/10^3],[h18(c18)-H18(c18); h18(c18)],'--k','linewidth',linewidth-0.5);
    plot(ax11C,x18/10^3,h18,'--k','linewidth',linewidth-0.5);
    plot(ax11C,x18/10^3,h18-H18,'--k','linewidth',linewidth-0.5);
    plot(ax11C,[x18(c18)/10^3; x18(c18)/10^3],[h18(c18); h18(c18)-H18(c18)],'--k','linewidth',linewidth-0.5);
    plot(ax11D,x18/10^3,h18,'--k','linewidth',linewidth-0.5);
    plot(ax11D,x18/10^3,h18-H18,'--k','linewidth',linewidth-0.5);
    plot(ax11D,[x18(c18)/10^3; x18(c18)/10^3],[h18(c18)-H18(c18); h18(c18)],'--k','linewidth',linewidth-0.5);
    % speed
    plot(ax9B,x18/10^3,U18*3.1536e7,'--k','linewidth',linewidth-0.5);
    plot(ax11E,x18/10^3,U18*3.1536e7,'--k','linewidth',linewidth-0.5);
    plot(ax11F,x18/10^3,U18*3.1536e7,'--k','linewidth',linewidth-0.5);
    plot(ax11G,x18/10^3,U18*3.1536e7,'--k','linewidth',linewidth-0.5);
    plot(ax11H,x18/10^3,U18*3.1536e7,'--k','linewidth',linewidth-0.5);

    b=b+1;
end
    
% save figures 
if save_figures
    exportgraphics(figure(9),[outpath,'sensitivityTests_geom+speed_unperturbed.png'],'Resolution',300);
    exportgraphics(figure(9),[outpath,'sensitivityTests_geom+speed_unperturbed.eps'],'Resolution',300);
    exportgraphics(figure(10),[outpath,'sensitivityTests_QglXcf_unperturbed.png'],'Resolution',300);
    exportgraphics(figure(10),[outpath,'sensitivityTests_QglXcf_unperturbed.eps'],'Resolution',300);
    exportgraphics(figure(11),[outpath,'sensitivityTests_geom+speed_climate_scenarios.png'],'Resolution',300);
    exportgraphics(figure(11),[outpath,'sensitivityTests_geom+speed_climate_scenarios.eps'],'Resolution',300);
    exportgraphics(figure(12),[outpath,'sensitivityTests_QglXcf_climate_scenarios.png'],'Resolution',300);
    exportgraphics(figure(12),[outpath,'sensitivityTests_QglXcf_climate_scenarios.eps'],'Resolution',300);
    disp('figures 9-12 saved.');
end

% option to print tables in LaTeX format
if print_tables
    
    % DFW
    disp('T_DFW:')
    disp(['d_fw  dL  dxgl dHgl  dUgl  Qgl']);
    T_DFW2 = table2array(T_DFW);
    for i=1:length(T_DFW2(:,1))
        disp([num2str(round(T_DFW2(i,1))), ' & ', num2str(round(T_DFW2(i,2),1)), ' & ',...
            num2str(round(T_DFW2(i,3),1)), ' & ', num2str(round(T_DFW2(i,4))), ' & ',...
            num2str(round(T_DFW2(i,5))), ' & ', num2str(round(T_DFW2(i,6),2)), ' \\']);
    end
    disp('     ');
    disp('-----------------------------');
    
    % SMB
    disp('T_SMB:')
    disp(['d_smb  dL  dxgl dHgl  dUgl  Qgl']);
    T_SMB2 = table2array(T_SMB);
    for i=1:length(T_SMB2(:,1))
        disp([num2str(round(T_SMB2(i,1),2)), ' & ', num2str(round(T_SMB2(i,2),1)), ' & ',...
            num2str(round(T_SMB2(i,3),1)), ' & ', num2str(round(T_SMB2(i,4))), ' & ',...
            num2str(round(T_SMB2(i,5))), ' & ', num2str(round(T_SMB2(i,6),2)), ' \\']);
    end
    disp('     ');
    disp('-----------------------------');
    
    % F_T
    disp('T_TF:')
    disp(['d_TF  dL  dxgl dHgl  dUgl  Qgl']);
    T_TF2 = table2array(T_TF);
    for i=1:length(T_TF2(:,1))
        disp([num2str(round(T_TF2(i,1),2)), ' & ', num2str(round(T_TF2(i,2),1)), ' & ',...
            num2str(round(T_TF2(i,3),1)), ' & ', num2str(round(T_TF2(i,4))), ' & ',...
            num2str(round(T_TF2(i,5))), ' & ', num2str(round(T_TF2(i,6),2)), ' \\']);
    end
    disp('     ');
    disp('-----------------------------');
    
    % SMB_enh
    disp('T_SMB_enh:')
    disp(['d_smb  dL  dxgl dHgl  dUgl  Qgl']);
    T_smb_enh2 = table2array(T_smb_enh);
    for i=1:length(T_smb_enh2(:,1))
        disp([num2str(T_smb_enh2(i,1),2), ' & ', num2str(round(T_smb_enh2(i,2),1)), ' & ',...
            num2str(round(T_smb_enh2(i,3),1)), ' & ', num2str(round(T_smb_enh2(i,4))), ' & ',...
            num2str(round(T_smb_enh2(i,5))), ' & ', num2str(round(T_smb_enh2(i,6),2)), ' \\']);
    end
    disp('   ');
    disp('-----------------------------');
    
    % SMB_enh & F_T
    disp('T_SMB_enh_TF:')
    disp(['d_SMB_enh  d_TF  dL  dxgl dHgl  dUgl  Qgl']);
    T_smb_enh_TF2 = table2array(T_smb_enh_TF);
    for i=1:length(T_smb_enh_TF2(:,1))
        disp([num2str(T_smb_enh_TF2(i,1),2), ' & ', num2str(round(T_smb_enh_TF2(i,2),2)), ' & ',...
            num2str(round(T_smb_enh_TF2(i,3),1)), ' & ', num2str(round(T_smb_enh_TF2(i,4),1)), ' & ',...
            num2str(round(T_smb_enh_TF2(i,5))), ' & ', num2str(round(T_smb_enh_TF2(i,6))),...
            ' & ',num2str(round(T_smb_enh_TF2(i,7),2)), ' \\']);
    end
    disp('     ');
    disp('-----------------------------');
    
end



