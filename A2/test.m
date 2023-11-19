x = 1:500; 
y = sind(x); 
quiver([1,1],[1,2],[0,1],[1,0])
axis tight; 
set(gca,'YDir','reverse');
set(gca,'XTick',[],'YTick',[]);
hold on
I = imread('DecoderOutput\0001.png'); 
h = image(xlim,ylim,I); 
uistack(h,'bottom')