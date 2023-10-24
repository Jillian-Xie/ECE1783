function expGolombEncoded = expGolombEncoding(array)
    % array is assumed to be a 1xlength array
    % return an encoded string
    
    length = size(array, 2);
    expGolombEncoded = '';
    % https://en.wikipedia.org/wiki/Exponential-Golomb_coding#Extension_to_negative_numbers
    for i = 1:length
        if array(1, i) <= 0
            dec = -2 * array(1, i) + 1;
        else
            dec = 2 * array(1, i);
        end
        % dec2bin converts decimal numbers to string of binary numbers
        expGolombEncoded = strcat(expGolombEncoded, dec2bin(dec, 2*floor(log2(dec)) + 1));
    end
end