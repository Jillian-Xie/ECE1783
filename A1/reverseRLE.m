function decodedRLE = reverseRLE(array, resultSize)
    % array is assumed to be a 1xlength array
    % return an encoded 1-d array of shape 1x(blockSize * blockSize)
    
    length = size(array, 2);
    decodedRLE = [];
    index = 1;
    
    while index <= length
        if array(1, index) < 0
            % encountered a run of non zero values
            for i = 1:-array(1, index)
                index = index + 1;
                decodedRLE = [decodedRLE, array(1, index)];
            end
        elseif array(1, index) > 0
            % encountered a run of zeros
            for i = 1:array(1, index)
                decodedRLE = [decodedRLE, 0];
            end
        end
        
        index = index + 1;
    end
    
    while size(decodedRLE, 2) < resultSize
        decodedRLE = [decodedRLE, 0];
    end
end