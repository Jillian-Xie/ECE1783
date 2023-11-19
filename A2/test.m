x = 1:500; 
y = sind(x); 
plot(x,y,'linewidth',3) 
axis tight; 
hold on
I = imread('DecoderOutput\0001.png'); 
h = image(xlim,-ylim,I); 
uistack(h,'bottom')