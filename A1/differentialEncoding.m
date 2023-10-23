function [diffMV, diffModes] = differentialEncoding(MVCell, modes)
MVHeight = size(MVCell,1);
MVWidth = size(MVCell,2);

modesHeight = size(modes,1);
modesWidth = size(modes,2);

diffMV = MVCell;
diffModes=modes;

refMV = [0, 0];
for MVHeightIndex=1:MVHeight
    for MVWidthIndex=1:MVWidth
          diffMV{MVHeightIndex,MVWidthIndex}=MVCell{MVHeightIndex,MVWidthIndex} - refMV;
          refMV = MVCell{MVHeightIndex,MVWidthIndex};
    end
end

refMode = 0;
for ModesHeightIndex=1:modesHeight
    for ModesWidthIndex=1:modesWidth
        if (modes(ModesHeightIndex,ModesWidthIndex) == refMode)
          diffModes(ModesHeightIndex,ModesWidthIndex) = 0;
        else
          diffModes(ModesHeightIndex,ModesWidthIndex) = 1;
          refMode = modes(ModesHeightIndex,ModesWidthIndex);
        end
    end
end

