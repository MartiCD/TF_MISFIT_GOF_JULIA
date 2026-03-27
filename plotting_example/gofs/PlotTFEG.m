disp('---------------------------------------------------');
disp('     Matlab sript for plotting TF envelope GOFs       ');

% Plots time-frequency TFEG (goodness-of-fit criterium) for the one- or three-component signals
% (globally normalized, log frequency axis)

% Input file name: 'MISFIT-GOF.DAT'
%                  'TFEG1.DAT' (for one-component signals)
%                  'TFEG1.DAT','TFEG2.DAT','TFEG3.DAT' (for three-component signals)

%  M. Kristekova, 2009

clear all;
cmap = load('gof_cmap10_2');         % colorscale

fid=fopen('MISFIT-GOF.DAT');  % reading of control data of the misfits&GOFs computation
MISFIT=fscanf(fid,'%g',inf);
fmin=log10( MISFIT(1) );% nebude mu ta pomlcka robit problem ako minus?
fmax=log10( MISFIT(2) );
NFREQ= MISFIT(3);
N= MISFIT(4);
dt= MISFIT(5);
nc= MISFIT(6);           % number of components
fclose(fid);

col_max= 10;
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
    f_name =['TFEG',num2str( k,'%01.0f'),'.DAT'];
    fid=fopen(f_name);       % reading from file with TFEM"k" results
	for i=1:1:NFREQ;		 % number "k" in the file name is the number of the component
	  a=fscanf(fid,'%g',[1 N]); 
	  tfa(i,:)=a;                
	end
	fclose(fid);

	figure;
	[C,h,cf]=contourf(time,freq,tfa,[0:1:10]);
    set(h,'EdgeColor','none', 'FaceColor', 'flat')
% shading faceted;   % toto dorobi cierne kontury na rozhrania fareb ploch, potom lepsie dat len 10 urovni 
    hold on;
    contour(time,freq,tfa,[4 6 8],'k');
% set(h,'EdgeColor','k');
    hold off;
	colormap(cmap);
    caxis([0 col_max]);  % setting limits for colorbar

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

	colorbar;

	% save figure to TIFF or png file, resolution 300 dpi 
	set(gcf, 'PaperUnits', 'inches');
	set(gcf, 'PaperPositionMode', 'manual');
	set(gcf, 'PaperPosition', [0.25 0.25 8.0 6.0]);  
% 	fig_name =['TFEG', num2str( k,'%01.0f'),'.tiff'];
    fig_name1 =['TFEG', num2str( k,'%01.0f'),'.png'];
%     print('-f','-dtiff','-r300',fig_name)
    print('-f','-dpng','-r300',fig_name1)
end;
