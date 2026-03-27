disp('---------------------------------------------------');
disp('       Matlab sript for plotting TFEM misfits       ');

% Plots time-frequency TFEM misfit for the one- or three-component signals
%(log frequency axis, misfits are scaled to the maximum from all three components)

% Input file name: 'MISFIT-GOF.DAT'
%                  'TFEM1.DAT' (for one-component signals)
%                  'TFEM1.DAT','TFEM2.DAT','TFEM3.DAT' (for three-component signals)

%  M. Kristekova, 2009

clear all;
cmap=load('jet_modn');         % colorscale

fid=fopen('MISFIT-GOF.DAT');  % reading of control data of the misfits&GOFs computation
MISFIT=fscanf(fid,'%g',inf);
fmin=log10( MISFIT(1) );% nebude mu ta pomlcka robit problem ako minus?
fmax=log10( MISFIT(2) );
NFREQ= MISFIT(3);
N= MISFIT(4);
dt= MISFIT(5);
nc= MISFIT(6);           % number of components
TFEMmax = MISFIT(7+4*nc+1);    % max value of TFEM misfits from all three components
TFPMmax = MISFIT(7+4*nc+2);    % max value of TFPM misfits from all three components
%...
fclose(fid);

col_max = (fix(TFEMmax*100.)+1.)/100.; % rounding to the nearest larger INT value when expressed in [%]
col_max_tic = (fix(TFEMmax*10.)-1)/10.; % rounding to the nearest larger INT value when expressed in [%]

% in case of locally normalized TFEM
% col_max should be computed later as max value of TFEM values for given component just after reading from file with TFEM results
df=(fmax-fmin)/(NFREQ-1);                                         

xmin=0.;       % beginning time (time for the first sample in data)
xmax=dt*(N-1); % ending time
ymin=fmin;     % lower frequency limit
ymax=fmax;     % upper frequency limit

% Time Tics
dx=[xmin:2:xmax];                         
dxLabel={[xmin:2:xmax]};
% Frequency Ticks
y_lin=cat(2,[0.1:0.1:0.9],[1:1:9],[10:10:50]);
dyLabel={'0.1';'';'';'0.4';'';'';'';'';'';'1';'2';'';'';'';'';'';'';'';'10';'';'';'';'50';};
dy=log10(y_lin);            % recalculating to log scale

for i=1:1:NFREQ;		    % frequency vector for plotting in TF plane
  freq(i)=ymin+(i-1)*df;
end
for i=1:1:N;                % time vector for plotting in TF plane
  time(i)=xmin+dt*(i-1);	
end

for k=1:1:nc
    f_name =['TFEM',num2str( k,'%01.0f'),'.DAT'];
    fid=fopen(f_name);       % reading from file with TFEM"k" results
	for i=1:1:NFREQ;		 % number "k" in the file name is the number of the component
	  a=fscanf(fid,'%g',[1 N]); 
	  tfa(i,:)=a;                
	end
	fclose(fid);

	figure;
	[C,h,cf]=contourf(time,freq,tfa,[-col_max:col_max/20:col_max]);
	set(h,'EdgeColor','none', 'FaceColor', 'flat');
	colormap(cmap); 
    caxis([-col_max col_max]);  % setting limits for colorbar

    set(gca,'XTick',[dx]);
	set(gca,'XTickLabel',dxLabel);
	set(gca,'TickDir','out');
	set(gca,'YTick',[dy]);
	set(gca,'YTickLabel',dyLabel);
	xlim([xmin xmax]);          % setting limits for axes
	ylim([ymin ymax]); 
	set(gca,'FontSize',8);
    xlabel('time [s]','FontSize',12)
    ylabel('frequency [Hz]','FontSize',12)

	cbar_axes = colorbar;
    set(cbar_axes,'YTick',[-col_max_tic:col_max_tic/4.:col_max_tic]);
    set(cbar_axes,'YTickLabel',[-col_max_tic*100.:col_max_tic*25.:col_max_tic*100.],'YTickMode','manual');
    xlabel(cbar_axes,'[%]','FontSize',12);
	% save figure to TIFF or png file, resolution 300 dpi 
	set(gcf, 'PaperUnits', 'inches');
	set(gcf, 'PaperPositionMode', 'manual');
	set(gcf, 'PaperPosition', [0.25 0.25 8.0 6.0]);  
% 	fig_name =['TFEM', num2str( k,'%01.0f'),'.tiff'];
    fig_name1 =['TFEM', num2str( k,'%01.0f'),'.png'];
%     print('-f','-dtiff','-r300',fig_name)
    print('-f','-dpng','-r300',fig_name1)
end;
