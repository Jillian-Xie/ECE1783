function [mode, quantizedBlock, approximatedResidualBlock, reconstructedBlock] = intraPredictBlock(verticalRefference, horizontalRefference, currentBlock, blockSize, QP, VBSEnable, FMEEnable, FastME)
verticalPredictionBlock=zeros(blockSize, blockSize);
horizontalPredictionBlock=zeros(blockSize, blockSize);
predictedBlock = zeros(blockSize, blockSize);
            
for i=1:blockSize
    verticalPredictionBlock(i, :)=verticalRefference;
end

for i=1:blockSize
    horizontalPredictionBlock(:, i)=horizontalRefference;
end

SAD_h=abs(sum(int32(horizontalPredictionBlock),'all') - sum(int32(currentBlock),'all'));
SAD_v=abs(sum(int32(verticalPredictionBlock),'all') - sum(int32(currentBlock),'all'));

if(SAD_h>SAD_v) % decide mode by SAD
    mode=int32(0);
    predictedBlock=horizontalPredictionBlock;
else
    mode=int32(1);
    predictedBlock=verticalPredictionBlock;
end

residualBlock = int32(currentBlock) - int32(predictedBlock);
transformedBlock = dct2(residualBlock);
quantizedBlock = quantize(transformedBlock, QP);
rescaledBlock = rescaling(quantizedBlock, QP);
approximatedResidualBlock = idct2(rescaledBlock);
reconstructedBlock = int32(approximatedResidualBlock) + int32(predictedBlock);