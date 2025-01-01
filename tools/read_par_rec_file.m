% Description:  Reads Philips PAR/REC V4.2 files                        %
% Author:       Xiaolei Zhu                                   %
% Date:         June 2021, modified Jan 2025   

function [imagesOut, ParsOut, meta] = read_par_rec_file(filename)
    % Get the directory and file name
    [fileDir, baseFileName, ~] = fileparts(filename);
    
    % Change to the directory containing the files
    currentDir = cd;
    cd(fileDir);
    
    % Read the .par and .rec files
    parFileName = [baseFileName, '.PAR'];
    recFileName = [baseFileName, '.REC'];
    
    fid1 = fopen(parFileName, 'r');
    fid2 = fopen(recFileName, 'r');
    
    % Read the .par file
    xPAR = textscan(fid1, '%s', 'delimiter', '\n');
    xPAR = char(xPAR{1});
    
    % Read the .rec file
    xREC = fread(fid2, 'uint16');
    
    % Close the files
    fclose(fid1);
    fclose(fid2);
    
    % Change back to the original directory
    cd(currentDir);
    
    % Initialize parameters
    N_slc = 0;
    N_dyn = 0;
    N_card = 0;
    
    % Determine the number of lines to read
    if isempty(sscanf(xPAR(size(xPAR, 1) - 2, :), '%f'))
        NrLineToRead = size(xPAR, 1) - 3;
    else
        NrLineToRead = size(xPAR, 1) - 2;
    end
    
    % Parse the .par file to get matrix size and other parameters
    for cnt1 = 101:NrLineToRead
        param = sscanf(xPAR(cnt1, :), '%f');
        if (param(1) > N_slc)
            N_slc = N_slc + 1;
            rec_matrix = [param(10) param(11) N_slc]; % x, y, z
        end
        if (param(3) > N_dyn)
            N_dyn = N_dyn + 1;
        end
        if (param(4) > N_card)
            N_card = N_card + 1;
        end
    end
    
    % Read data
    cnt2 = 0;
    imagesOut = zeros([rec_matrix N_dyn]);
    off_center = zeros(N_slc, 3);
    
    for cnt1 = 101:NrLineToRead
        param = sscanf(xPAR(cnt1, :), '%f');
        RI = param(12);
        RS = param(13);
        SS = param(14);
        
        if (param(5) == 0) % magnitude
            PV = reshape(xREC((rec_matrix(1) * rec_matrix(2) * cnt2 + 1):(rec_matrix(1) * rec_matrix(2) * (cnt2 + 1))), rec_matrix(1:2));
            tmp = (PV' .* RS + RI) ./ (RS .* SS); % x, y, z, dyn
            imagesOut(:, :, param(1), param(3)) = tmp;
        end
        
        off_center(param(1), :) = [param(20) param(21) param(22)]; % based on slice
        cnt2 = cnt2 + 1;
    end
    
    % Create the parameter structure
    ParsOut = struct();
    ParsOut.Matrix = rec_matrix;
    ParsOut.Res_XYZ = [param(29) param(30) param(23)]; % x, y, z
    ParsOut.N_slices = N_slc;
    ParsOut.N_dynamics = N_dyn;
    ParsOut.N_card = N_card;
    ParsOut.Orientation = param(26);
    ParsOut.offcenter_XYZ = off_center;
    ParsOut.TE = param(31);
    ParsOut.N_averages = param(35);
    
    % Parse the header information from the .par file
    meta = struct();
    headerLines = xPAR(1:100, :); % Assuming the first 100 lines contain header information
    for i = 1:size(headerLines, 1)
        line = strtrim(headerLines(i, :));
        if startsWith(line, '.')
            key = strtok(line, ':');
            value = strtrim(strrep(line, key, ''));
            key = strrep(key, '.', ''); % Remove leading dot
            key = strrep(key, ' ', '_'); % Replace spaces with underscores
            key = matlab.lang.makeValidName(key); % Ensure valid field name
            meta.(key) = value;
        end
    end
end

