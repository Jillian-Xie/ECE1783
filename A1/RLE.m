function encodedRLE = RLE(array)
    % array is assumed to be a 1xlength array
    % return an encoded 1-d array
    
    length = size(array, 2);
    encodedRLE = [];
    tempRun = [];
    zeroCounter = 0;
    nonZeroCounter = 0;
    for i = 1:length
        if array(1, i) ~= 0
            if i > 1 && array(1, i-1) == 0
                % we start a new run with non zero elements at the current
                % index, push the previous run of all zeros into the result
                encodedRLE = [encodedRLE, zeroCounter];
            end
            nonZeroCounter = nonZeroCounter + 1;
            zeroCounter = 0;
            tempRun = [tempRun, array(1, i)];
        else
            % array(1, i) == 0
            if i > 1 && array(1, i-1) ~= 0
                % we start a new run with all zero elements at the current
                % index, push the previous run of non zeros into the result
                encodedRLE = [encodedRLE, -nonZeroCounter, tempRun];
                nonZeroCounter = 0;
                tempRun = [];
            end
            zeroCounter = zeroCounter + 1;
        end
    end
    
    if zeroCounter > 0
        % there are remaining zeros at the end
        encodedRLE = [encodedRLE, 0];
    end
    
    if nonZeroCounter > 0
        % we did not run into a 0 in between 
        encodedRLE = [encodedRLE, -nonZeroCounter, tempRun];
    end
end