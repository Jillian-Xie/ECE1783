function expGolombDecoded = expGolombDecoding(inputStr)
    % array is assumed to be a string
    % return an decoded 1-d array
    
    expGolombDecoded = [];
    index = 1;
    tempStr = '';
    while index <= size(inputStr, 2)
        if inputStr(1, index) == '0'
            tempStr = [tempStr, inputStr(1, index)];
        else
            % inputStr(1, index) == '1'
            tempStrSize = size(tempStr, 2);
            tempStr = [tempStr, inputStr(1, index)];
            % push the next size(tempstr) elements into tempstr
            for i = 1:tempStrSize
                index = index + 1;
                tempStr = [tempStr, inputStr(1, index)];
            end
            dec = bin2dec(tempStr) - 1;
            if mod(dec, 2) == 0
                expGolombDecoded = [expGolombDecoded, dec / -2];
            else
                expGolombDecoded = [expGolombDecoded, (dec + 1) / 2];
            end
            tempStr = '';
        end
        index = index + 1;
    end
end