function computeFeaturesLabs(sub, rec, db)
    % usage: computeFeaturesLabs("S001", 4) -> 4, 8, 12
    
    if (nargin < 3)
        db=""; % directory of a database
    end

    subject = string(sub); % convert subject name to string
    record = [];

    for i=0:2
        % 3,7,11 ... dejasnko stistaknje pesti
        % 4, 8, 12 ... zamislanje stiskanja pesti

        record = [record string(num2str(rec+(i*4), "%02d"))];
    end

    % disp(record);

    % open and read intervals
    % we'll use the cell array such that we can deal with object of siff size
    t1s = {}; % signals t1, possible of different length 
    t2s = {}; % signals t2, possible of different length

    for i=1:size(record, 2)

        if (strcmp(db, "") == 0)
            recName = strcat('/', db, '/', subject, '/', subject, 'R', record(:, i), '.edf');
        else
            recName = strcat(subject, 'R', record(i), '.edf');
        end

        recName = convertStringsToChars(recName); % add this otherwise you will cry :()
        disp(recName);

        % Read records
        [sig, fs, tm] = rdsamp(recName, 1:64); % recall that the 65th channel has annotations (we ignore it here)
        [T0, T1, T2] = getIntervals(recName, 'event', fs, size(sig, 1)); % "event denotes .event files, where we have the annotations"
        % sometimes records are shorten than what is said in annotations, therefore we add size(sig, 1) parameter
    
        % Process signals
        sig = transpose(sig);

        for j=1:size(T1, 1)
            start = T1(j, 1);
            stop = T1(j, 2);
            t1s{end + 1} = sig(:, start:stop); % take all 64 signals between start and stop  
        end

        for j=1:size(T2, 1)
            start = T2(j, 1);
            stop = T2(j, 2);
            t2s{end + 1} = sig(:, start:stop); % take all 64 signals between start and stop  
        end

        size(t1s)
        size(t2s)
    end

    % use only the first two intervals from t1s and t2s to estimate the matrix W
    [W] = f_CSP(cell2mat(t1s(1)), cell2mat(t2s(1)));

    % remove intervals used for training
    t1s(1) = [];
    t2s(1) = [];

    % Implement a bandpass filter
    fb = [0 8 8 13 13 fs / 2] / (fs / 2);
    ints = [0 0 1 1 0 0];
    n = 35;
    b = firls(n, fb, ints);    

    % transform to csp space
    for i=1:size(t1s, 2)
        cst = W * cell2mat(t1s(i));

        % take only the extreme components (e.g take only 2)
        cse = transpose([transpose(cst(1, :)), transpose(cst(size(cst, 1), :))]);

        % filter cse
        csf = filter(b, 1, cse);

        % use the log Var operator
        lvt1(i, 1) = log(var(csf(1, :)));
        lvt1(i, 2) = log(var(csf(2, :)));
    end

    for i=1:size(t2s, 2)
        cst = W * cell2mat(t2s(i));

        % take only the extreme components (e.g take only 2)
        cse = transpose([transpose(cst(1, :)), transpose(cst(size(cst, 1), :))]);

        % filter cse
        csf = filter(b, 1, cse);

        % use the log Var operator
        lvt2(i, 1) = log(var(csf(1, :)));
        lvt2(i, 2) = log(var(csf(2, :)));
    end

    % display scatter plot of classes
    figure;
    scatter(lvt1(:, 1), lvt1(:, 2));
    hold on;
    scatter(lvt2(:, 1), lvt2(:, 2));

    % TODO 1: Save feature vectors as "featureVectors.txt" and labels "referenceClass.txt"
    featureVectorsFile = 'featureVectors.txt';
    classFile = 'referenceClass.txt';

    file_fv = fopen(featureVectorsFile, "wt");
    file_c = fopen(classFile, "wt");

    for i=1:size(lvt1, 1)
        fprintf(file_fv, "%.8f %.8f\n", lvt1(i, 1), lvt1(i, 2));
        fprintf(file_c, "T1\n");
    end

    for i=1:size(lvt2, 1)
        fprintf(file_fv, "%.8f %.8f\n", lvt2(i, 1), lvt2(i, 2));
        fprintf(file_c, "T2\n");
    end

    fclose(file_fv);
    fclose(file_c);

    % if you open "featureVectors.txt" you'll see that each row is a feature !


    % TODO 2: Install Statistics and Machine Learning Toolbox
    % add ons => search => install
    % https://www.mathworks.com/matlabcentral/answers/477394-how-to-install-toolbox-on-ubuntu

    % TODO 3: call doClassification("featureVectors.txt", "referenceClass.txt", {1, 1}, 10, 30, 0)

    % metrics
    % Se =  TP / (TP + FN)
    % Sp =  TP / (TP + FN)
    % acc = (TP + TN) / (TP + TN + FP + FN)
end