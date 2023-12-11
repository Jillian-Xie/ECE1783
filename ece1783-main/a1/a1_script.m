clear;
clc;

filepath = "foreman_cif.yuv";
height = 288;
width = 352;

nframes = 10;
blockSize = 16;
r = 4;
n = 2;
QP = 1;

I_Period = 8;
isDifferential = 1;
isEntropy = 1;

nRefFrames = 1;
VBSEnable = 0;
FMEEnable = 0;
FastME = 0;
ParallelMode = 0;


yVideo = yOnlyVideo(filepath, width, height, nframes);

yframes = yVideo.yframes(:, :, 1 : nframes);


faceDetector =  vision.CascadeObjectDetector;
faceDetector.MergeThreshold = 4;
bboxes = step(faceDetector, yframes(:,:,2));
if ~isempty(bboxes)
    IFaces = insertObjectAnnotation(yframes(:,:,2),'rectangle',bboxes,'Face');   
    figure
    imshow(IFaces)
else
    position = [0 0];
    label='no face detected';
    Imgn = insertText(yframes(:,:,1),position,label, 'fontsize',25,'BoxOpacity',1);
    imshow(Imgn)
end
figure(2)
bboxPoints = bbox2points(bboxes(1, :));
imshow(yframes(120:282,80:242,2));
% encode
%startTime = posixtime(datetime('now'));
%codec(1, filepath, width=width, height=height, nframes=nframes, i=blockSize, r=r, n=2, QP=QP, I_Period=I_Period, isDifferential=isDifferential, isEntropy=isEntropy, nRefFrames=nRefFrames, VBSEnable=VBSEnable,  FMEEnable=FMEEnable, FastME=FastME);
%endTime = posixtime(datetime('now'));
%fprintf("Execution time is %2f\n", endTime - startTime);

% decode
%codec(0, "output/synthetic/");\

