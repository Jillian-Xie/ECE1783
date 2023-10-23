function [mode, predictedBlock] = intraPredictBlock(verticalRefference, horizontalRefference, currentBlock, blockSize)
verticalPredictionBlock=zeros(blockSize, blockSize);
horizontalPredictionBlock=zeros(blockSize, blockSize);
            
for i=1:blockSize
    verticalPredictionBlock(i, :)=verticalRefference;
end

for i=1:blockSize
    horizontalPredictionBlock(:, i)=horizontalRefference;
end

SAD_h=abs(sum(int32(horizontalPredictionBlock),'all') - sum(int32(currentBlock),'all'));
SAD_v=abs(sum(int32(verticalPredictionBlock),'all') - sum(int32(currentBlock),'all'));

if(SAD_h>SAD_v)
    mode=0;
    predictedBlock=horizontalPredictionBlock;
else
    mode=1;
    predictedBlock=verticalPredictionBlock;
end