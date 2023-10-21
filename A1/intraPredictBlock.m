function [mode, predictedBlock] = intraPredictBlock(currentFrame, widthBlockIndex, heightBlockIndex, blockSize)
currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame, 0, 0);
verticalPredictionBlock=currentBlock;
horizontalPredictionBlock=currentBlock;
            
for i=2:blockSize
    verticalPredictionBlock(2:blockSize,i)=currentBlock(1,i);
end

for i=2:blockSize
    horizontalPredictionBlock(i,2:blockSize)=currentBlock(i,1);
end

MAE_h=abs(sum(int32(horizontalPredictionBlock),'all') - sum(int32(currentBlock),'all'))  / numel(int32(currentBlock));
MAE_v=abs(sum(int32(verticalPredictionBlock),'all') - sum(int32(currentBlock),'all'))  / numel(int32(currentBlock));

if(MAE_h>MAE_v)
    mode=0;
    predictedBlock=horizontalPredictionBlock;
else
    mode=1;
    predictedBlock=verticalPredictionBlock;
end